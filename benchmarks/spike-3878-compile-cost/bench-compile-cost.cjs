#!/usr/bin/env node
/*
 * Profiling spike for issue #3878 — measures the V8 parse/compile cost of the
 * per-request rendering JS executed by the Pro node renderer's hot line
 * (packages/react-on-rails-pro-node-renderer/src/worker/vm.ts:417,
 *  `vm.runInContext(renderingRequest, context)`).
 *
 * THROWAWAY BENCHMARK SCRIPT — report-only spike, not shipped code.
 *
 * Method
 * ------
 * - Uses the BUILT node-renderer package (lib/worker/vm.js) so the VM context
 *   is constructed exactly as in production (same console shim, globals, etc.).
 * - Uses ACTUAL gem-generated rendering requests committed as test fixtures
 *   (tests/fixtures/projects/...), run against their real webpack server bundles.
 * - For large-payload tiers, the actual react-webpack-rails-tutorial
 *   appRenderingRequest.js is used verbatim except that its inlined
 *   `reduxProps.comments` JSON array is scaled with realistic comment objects
 *   until the total request source reaches the target byte size. The App
 *   component actually renders the comments server-side, so execution time
 *   scales with the props like a real props-heavy page.
 * - Every timed compile/run uses a UNIQUE source string (a fixed-width nonce is
 *   substituted into a prop value / trailing comment) so V8 cannot serve any
 *   internal compilation cache — matching production, where props differ per
 *   request. A separate "identical source repeated" series quantifies whether
 *   any caching would help if the source were stable.
 *
 * Per steady-state iteration (bundle VM context already warm, as in production):
 *   compile_ms : `new vm.Script(srcA)`            — isolated parse/compile cost
 *   hotline_ms : `vm.runInContext(srcB, context)` — the exact production hot
 *                line: compile + execute (+ await if a thenable is returned)
 *
 * Also measured once per workload:
 *   cold_bundle_build_ms : buildExecutionContext() — bundle compile+eval
 *                          (the cost paid on worker cold start / LRU eviction)
 *
 * Usage:
 *   node bench-compile-cost.cjs [--iters N] [--warmup N] [--workload NAME]
 *                               [--json-out FILE]
 */

'use strict';

const path = require('path');
const fs = require('fs');
const os = require('os');
const vm = require('vm');
const { performance, PerformanceObserver } = require('perf_hooks');

// Track GC time so phase deltas can be attributed (compile vs GC fallout).
let gcMsAccum = 0;
const gcObserver = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) gcMsAccum += entry.duration;
});
gcObserver.observe({ entryTypes: ['gc'] });

const pkgRoot = path.resolve(__dirname, '../../packages/react-on-rails-pro-node-renderer');
// eslint-disable-next-line import/no-dynamic-require
const { buildConfig } = require(path.join(pkgRoot, 'lib/shared/configBuilder.js'));
// eslint-disable-next-line import/no-dynamic-require
const { buildExecutionContext, resetVM } = require(path.join(pkgRoot, 'lib/worker/vm.js'));

const fixturesRoot = path.join(pkgRoot, 'tests/fixtures/projects');

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
function argValue(name, fallback) {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : fallback;
}
const itersOverride = argValue('--iters', null);
const warmupIters = parseInt(argValue('--warmup', '25'), 10);
const onlyWorkload = argValue('--workload', null);
const jsonOut = argValue('--json-out', path.join(__dirname, 'results.json'));

// ---------------------------------------------------------------------------
// Workload construction
// ---------------------------------------------------------------------------
const NONCE_TOKEN = '@@NONCE0000000000@@'; // fixed width, replaced per iteration

function readFixture(rel) {
  return fs.readFileSync(path.join(fixturesRoot, rel), 'utf8');
}

// Generate a realistic comment object roughly matching the tutorial app's shape.
function makeComment(id) {
  const texts = [
    'This is a great article, thanks for sharing all the details about server side rendering.',
    'I ran into the same issue last week; upgrading the renderer fixed the latency for us.',
    'Could you elaborate on how the hydration step interacts with the Redux store setup?',
    'Benchmarks look promising. Curious how this behaves under sustained production load.',
    'We migrated from ExecJS to the node renderer and saw a significant throughput win.',
  ];
  return {
    id,
    author: `User ${id} Lastname${id % 97}`,
    text: `${texts[id % texts.length]} (comment ${id}, thread ${id % 13}, reply-depth ${id % 4})`,
    created_at: '2026-05-22T01:45:32.043Z',
    updated_at: '2026-06-01T11:02:15.667Z',
  };
}

// Take the ACTUAL tutorial appRenderingRequest.js and scale its inlined
// reduxProps JSON until the whole source is ~targetBytes. The nonce token is
// embedded in the first comment's text so every iteration's source is unique.
function buildScaledTutorialRequest(targetBytes) {
  const original = readFixture('react-webpack-rails-tutorial/ec974491/appRenderingRequest.js');
  const marker = /reduxProps = \{.*\};/;
  if (!marker.test(original)) throw new Error('reduxProps marker not found in fixture');

  const baseSize = original.replace(marker, 'reduxProps = {"comments":[]};').length;
  const probe = JSON.stringify(makeComment(123456));
  const perComment = probe.length + 1; // + comma
  let count = Math.max(1, Math.floor((targetBytes - baseSize) / perComment));

  const build = (n) => {
    const comments = [];
    for (let i = 0; i < n; i += 1) comments.push(makeComment(100000 + i));
    comments[0].text += ` ${NONCE_TOKEN}`;
    const propsJson = JSON.stringify({ comments });
    return original.replace(marker, () => `reduxProps = ${propsJson};`);
  };

  // One refinement pass to land close to the target size.
  let src = build(count);
  const diff = targetBytes - src.length;
  count = Math.max(1, count + Math.round(diff / perComment));
  src = build(count);
  return { src, commentCount: count };
}

// For the small, unmodified fixtures: uniquify by appending a trailing comment.
function uniquifierFor(src) {
  if (src.includes(NONCE_TOKEN)) {
    return (nonce) => src.replace(NONCE_TOKEN, String(nonce).padStart(NONCE_TOKEN.length, '0'));
  }
  return (nonce) => `${src}\n//${String(nonce).padStart(17, '0')}`;
}

function defineWorkloads() {
  const tutorialBundle = path.join(fixturesRoot, 'react-webpack-rails-tutorial/ec974491/server-bundle.js');
  const specDummyBundle = path.join(fixturesRoot, 'spec-dummy/9fa89f7/server-bundle-web-target.js');

  const w = [];

  w.push({
    name: 'spec_dummy_redux_actual',
    description: 'spec/dummy ReduxApp — actual gem-generated request, unmodified',
    bundle: specDummyBundle,
    src: readFixture('spec-dummy/9fa89f7/reduxAppRenderingRequest.js'),
    iters: 500,
  });

  w.push({
    name: 'tutorial_app_actual',
    description: 'react-webpack-rails-tutorial App — actual gem-generated request, unmodified',
    bundle: tutorialBundle,
    src: readFixture('react-webpack-rails-tutorial/ec974491/appRenderingRequest.js'),
    iters: 500,
  });

  w.push({
    name: 'friendsandguests_listing_index_actual',
    description: 'friendsandguests ListingIndex — actual gem-generated request (14 KB), unmodified',
    bundle: path.join(fixturesRoot, 'friendsandguests/1a7fe417/server-bundle.js'),
    src: readFixture('friendsandguests/1a7fe417/listingIndexRenderingRequest.js'),
    iters: 500,
  });

  const scaled64k = buildScaledTutorialRequest(64 * 1024);
  w.push({
    name: 'tutorial_app_scaled_64kb',
    description: `tutorial App request, comments scaled to ~64 KB (${scaled64k.commentCount} comments)`,
    bundle: tutorialBundle,
    src: scaled64k.src,
    iters: 300,
  });

  // 1,164,171 bytes = the renderingRequest size measured for the canonical
  // mega_benchmark page in internal/planning/json-render-body-migration-plan.md
  const scaledMega = buildScaledTutorialRequest(1164171);
  w.push({
    name: 'tutorial_app_scaled_1_16mb',
    description: `tutorial App request, comments scaled to ~1.16 MB (${scaledMega.commentCount} comments)`,
    bundle: tutorialBundle,
    src: scaledMega.src,
    iters: 150,
  });

  return w;
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------
function percentile(sorted, p) {
  if (sorted.length === 0) return NaN;
  const idx = Math.min(sorted.length - 1, Math.ceil((p / 100) * sorted.length) - 1);
  return sorted[Math.max(0, idx)];
}

function stats(samples) {
  const sorted = [...samples].sort((a, b) => a - b);
  const sum = sorted.reduce((a, b) => a + b, 0);
  return {
    n: sorted.length,
    mean: sum / sorted.length,
    min: sorted[0],
    p50: percentile(sorted, 50),
    p90: percentile(sorted, 90),
    p99: percentile(sorted, 99),
    max: sorted[sorted.length - 1],
  };
}

function fmt(x) {
  return x >= 100 ? x.toFixed(0) : x >= 10 ? x.toFixed(1) : x.toFixed(2);
}

// ---------------------------------------------------------------------------
// Benchmark
// ---------------------------------------------------------------------------
async function maybeAwait(result) {
  if (result && typeof result.then === 'function') return result;
  return result;
}

async function benchWorkload(workload) {
  resetVM();
  const tmpCache = fs.mkdtempSync(path.join(os.tmpdir(), 'spike-3878-'));
  buildConfig({ serverBundleCachePath: tmpCache });

  // Cold start: bundle compile + eval (paid on worker start / LRU eviction).
  const tCold0 = performance.now();
  const { getVMContext, runInVM } = await buildExecutionContext([workload.bundle], true);
  const coldBundleBuildMs = performance.now() - tCold0;

  const { context } = getVMContext(workload.bundle);
  const makeSrc = uniquifierFor(workload.src);

  // Sanity check: run through the real production entry point once and verify
  // that HTML actually rendered.
  const sanityResult = await runInVM(makeSrc(999999999), workload.bundle);
  if (typeof sanityResult !== 'string' || !sanityResult.includes('<')) {
    throw new Error(`Workload ${workload.name}: render sanity check failed: ${String(sanityResult).slice(0, 300)}`);
  }
  const sanity = JSON.parse(sanityResult);
  if (sanity.hasErrors) {
    throw new Error(`Workload ${workload.name}: render reported errors: ${sanityResult.slice(0, 500)}`);
  }

  const iters = itersOverride ? parseInt(itersOverride, 10) : workload.iters;

  // Warmup (warm context, warm IC/feedback for the bundle's render path).
  for (let i = 0; i < warmupIters; i += 1) {
    // eslint-disable-next-line no-await-in-loop
    await maybeAwait(vm.runInContext(makeSrc(1000000 + i), context));
  }

  if (global.gc) global.gc();

  const compileMs = [];
  const hotlineMs = [];
  let resultWasSync = true;

  await new Promise((resolve) => setTimeout(resolve, 50)); // flush pending GC observer entries
  const gcBeforeUnique = gcMsAccum;

  for (let i = 0; i < iters; i += 1) {
    // (a) isolated parse/compile of a unique source
    const srcA = makeSrc(2000000 + i);
    const c0 = performance.now();
    // eslint-disable-next-line no-new
    new vm.Script(srcA, { filename: 'renderingRequest.js' });
    compileMs.push(performance.now() - c0);

    // (b) the exact production hot line on a different unique source
    const srcB = makeSrc(3000000 + i);
    const h0 = performance.now();
    const r = vm.runInContext(srcB, context);
    if (r && typeof r.then === 'function') {
      resultWasSync = false;
      // eslint-disable-next-line no-await-in-loop
      await r;
    }
    hotlineMs.push(performance.now() - h0);
  }

  // (c) identical source compiled repeatedly — does ANY cache kick in?
  const sameSrc = makeSrc(4000000);
  const sameCompileMs = [];
  for (let i = 0; i < Math.min(100, iters); i += 1) {
    const c0 = performance.now();
    // eslint-disable-next-line no-new
    new vm.Script(sameSrc, { filename: 'renderingRequest.js' });
    sameCompileMs.push(performance.now() - c0);
  }

  await new Promise((resolve) => setTimeout(resolve, 50));
  const gcAfterUnique = gcMsAccum;

  // (d) the production hot line with an IDENTICAL source every time —
  // simulates "props-as-data" (stable wrapper, V8 compilation cache hits).
  // unique-src hot line p50 minus this p50 = in-situ per-request compile penalty.
  if (global.gc) global.gc();
  await new Promise((resolve) => setTimeout(resolve, 50));
  const gcBeforeSame = gcMsAccum;
  const sameHotSrc = makeSrc(5000000);
  const hotlineSameSrcMs = [];
  for (let i = 0; i < iters; i += 1) {
    const h0 = performance.now();
    const r = vm.runInContext(sameHotSrc, context);
    // eslint-disable-next-line no-await-in-loop
    if (r && typeof r.then === 'function') await r;
    hotlineSameSrcMs.push(performance.now() - h0);
  }
  await new Promise((resolve) => setTimeout(resolve, 50));
  const gcAfterSame = gcMsAccum;

  const htmlBytes = Buffer.byteLength(sanityResult, 'utf8');

  return {
    name: workload.name,
    description: workload.description,
    bundle: path.relative(fixturesRoot, workload.bundle),
    requestBytes: Buffer.byteLength(makeSrc(0), 'utf8'),
    resultBytes: htmlBytes,
    resultWasSync,
    iters,
    warmup: warmupIters,
    coldBundleBuildMs,
    compile: stats(compileMs),
    hotline: stats(hotlineMs),
    compileSameSrc: stats(sameCompileMs),
    hotlineSameSrc: stats(hotlineSameSrcMs),
    // Unique phase does 2 fresh compiles/iter (isolated + hot line); same phase ~0.
    gcMsPerIterUniquePhase: (gcAfterUnique - gcBeforeUnique) / iters,
    gcMsPerIterSamePhase: (gcAfterSame - gcBeforeSame) / iters,
  };
}

async function main() {
  const workloads = defineWorkloads().filter((w) => !onlyWorkload || w.name === onlyWorkload);
  if (workloads.length === 0) {
    console.error(`No workload named ${onlyWorkload}`);
    process.exit(1);
  }

  const env = {
    node: process.version,
    v8: process.versions.v8,
    os: `${os.type()} ${os.release()} (${os.platform()}/${os.arch()})`,
    cpu: os.cpus()[0]?.model || 'unknown',
    cores: os.cpus().length,
    memGB: Math.round(os.totalmem() / 1024 ** 3),
    exposedGc: Boolean(global.gc),
    date: new Date().toISOString(),
  };
  console.log('Environment:', JSON.stringify(env, null, 2));

  const results = [];
  for (const w of workloads) {
    process.stdout.write(`\n== ${w.name} (${w.description}) ==\n`);
    // eslint-disable-next-line no-await-in-loop
    const r = await benchWorkload(w);
    results.push(r);

    const pct = (a, b) => ((a / b) * 100).toFixed(1);
    console.log(`  request size        : ${r.requestBytes.toLocaleString()} bytes`);
    console.log(`  rendered result     : ${r.resultBytes.toLocaleString()} bytes (sync=${r.resultWasSync})`);
    console.log(`  cold bundle build   : ${fmt(r.coldBundleBuildMs)} ms (once per worker/bundle)`);
    console.log(`  iterations          : ${r.iters} (+${r.warmup} warmup)`);
    console.log(
      `  compile (unique src): p50=${fmt(r.compile.p50)} p90=${fmt(r.compile.p90)} p99=${fmt(r.compile.p99)} mean=${fmt(r.compile.mean)} ms`,
    );
    console.log(
      `  hot line (vm.runInContext, unique src): p50=${fmt(r.hotline.p50)} p90=${fmt(r.hotline.p90)} p99=${fmt(r.hotline.p99)} mean=${fmt(r.hotline.mean)} ms`,
    );
    console.log(
      `  compile share of hot line: p50 ${pct(r.compile.p50, r.hotline.p50)}%  mean ${pct(r.compile.mean, r.hotline.mean)}%`,
    );
    console.log(
      `  compile (identical src x${r.compileSameSrc.n}): p50=${fmt(r.compileSameSrc.p50)} ms (vs unique p50=${fmt(r.compile.p50)} ms)`,
    );
    console.log(
      `  hot line (identical src, cache hits): p50=${fmt(r.hotlineSameSrc.p50)} p99=${fmt(r.hotlineSameSrc.p99)} ms` +
        ` → in-situ compile penalty p50 ≈ ${fmt(r.hotline.p50 - r.hotlineSameSrc.p50)} ms`,
    );
    console.log(
      `  GC per iter: unique-src phase=${fmt(r.gcMsPerIterUniquePhase)} ms, identical-src phase=${fmt(r.gcMsPerIterSamePhase)} ms`,
    );
  }

  fs.writeFileSync(jsonOut, `${JSON.stringify({ env, results }, null, 2)}\n`);
  console.log(`\nResults written to ${jsonOut}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
