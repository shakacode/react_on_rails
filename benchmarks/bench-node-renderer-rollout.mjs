#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { performance } from 'node:perf_hooks';

const require = createRequire(import.meta.url);
const benchmarkPath = fileURLToPath(import.meta.url);
const repositoryRoot = process.env.ROLLOUT_BENCH_REPOSITORY_ROOT
  ? path.resolve(process.env.ROLLOUT_BENCH_REPOSITORY_ROOT)
  : path.resolve(path.dirname(benchmarkPath), '..');
const packageRoot = path.join(repositoryRoot, 'packages/react-on-rails-pro-node-renderer');

function parseArguments(argv) {
  const options = {
    mode: 'full',
    durationSeconds: undefined,
    requestsPerSecond: 3,
    timeoutMilliseconds: 1_000,
    drainTimeoutMilliseconds: 500,
  };

  for (let argumentIndex = 0; argumentIndex < argv.length; argumentIndex += 1) {
    const argument = argv[argumentIndex];
    const value = argv[argumentIndex + 1];
    switch (argument) {
      case '--mode':
        options.mode = value;
        argumentIndex += 1;
        break;
      case '--duration-seconds':
        options.durationSeconds = Number(value);
        argumentIndex += 1;
        break;
      case '--requests-per-second':
        options.requestsPerSecond = Number(value);
        argumentIndex += 1;
        break;
      case '--timeout-ms':
        options.timeoutMilliseconds = Number(value);
        argumentIndex += 1;
        break;
      case '--drain-timeout-ms':
        options.drainTimeoutMilliseconds = Number(value);
        argumentIndex += 1;
        break;
      default:
        throw new Error(`Unknown argument: ${argument}`);
    }
  }

  if (!['smoke', 'full'].includes(options.mode)) {
    throw new Error("--mode must be either 'smoke' or 'full'");
  }
  options.durationSeconds ??= options.mode === 'smoke' ? 2 : 40;
  for (const [name, value] of [
    ['durationSeconds', options.durationSeconds],
    ['requestsPerSecond', options.requestsPerSecond],
    ['timeoutMilliseconds', options.timeoutMilliseconds],
    ['drainTimeoutMilliseconds', options.drainTimeoutMilliseconds],
  ]) {
    if (!Number.isFinite(value) || value <= 0) {
      throw new Error(`${name} must be a positive finite number`);
    }
  }

  return options;
}

function percentile(samples, quantile) {
  const sorted = [...samples].sort((left, right) => left - right);
  const index = Math.max(0, Math.ceil(sorted.length * quantile) - 1);
  return sorted[index];
}

function gitValue(args) {
  return execFileSync('git', args, { cwd: repositoryRoot, encoding: 'utf8' }).trim();
}

function sleep(milliseconds) {
  return new Promise((resolve) => {
    setTimeout(resolve, milliseconds);
  });
}

async function run() {
  const options = parseArguments(process.argv.slice(2));
  process.env.NODE_ENV = 'test';
  process.env.RAILS_ENV = 'test';

  const configModulePath = path.join(packageRoot, 'lib/shared/configBuilder.js');
  const vmModulePath = path.join(packageRoot, 'lib/worker/vm.js');
  const manifestModulePath = path.join(packageRoot, 'lib/worker/currentGenerationManifest.js');
  const fixturePath = path.join(packageRoot, 'tests/fixtures/bundle.js');
  const missingRequiredPaths = [configModulePath, vmModulePath, fixturePath].filter(
    (requiredPath) => !fs.existsSync(requiredPath),
  );
  if (missingRequiredPaths.length > 0) {
    throw new Error(
      `Required rollout benchmark files are missing:\n${missingRequiredPaths
        .map((missingPath) => `- ${missingPath}`)
        .join('\n')}\n` +
        'Run `pnpm --filter react-on-rails-pro-node-renderer run build` and ensure the benchmark fixture is present.',
    );
  }

  // eslint-disable-next-line import/no-dynamic-require -- computed path was checked above
  const { buildConfig } = require(configModulePath);
  // eslint-disable-next-line import/no-dynamic-require -- computed path was checked above
  const vmModule = require(vmModulePath);
  // eslint-disable-next-line import/no-dynamic-require -- optional production module path is fixed under packageRoot
  const manifestModule = fs.existsSync(manifestModulePath) ? require(manifestModulePath) : undefined;
  const {
    buildExecutionContext,
    getVMContext,
    getVMPoolDiagnostics,
    prewarmDeclaredBundleGeneration,
    resetVM,
  } = vmModule;
  const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'ror-node-renderer-rollout-'));
  const cachePath = path.join(temporaryRoot, 'cache');
  const snapshotRoot = `${cachePath}.artifact-snapshots`;
  const serverId = `rorp-v2-s-${'a'.repeat(64)}`;
  const rscId = `rorp-v2-r-${'b'.repeat(64)}`;
  const currentArtifacts = [
    { role: 'server', id: serverId },
    { role: 'rsc', id: rscId },
  ];
  const generationDigest = createHash('sha256');
  generationDigest.update('react-on-rails-pro-current-generation-v1\0');
  currentArtifacts.forEach(({ role, id }) => generationDigest.update(`${role}\0${id}\0`));
  const generationId = `rorp-generation-v1-${generationDigest.digest('hex')}`;
  const bundleSets = {
    old: ['server', 'rsc'].map((role) => path.join(cachePath, 'old', `${role}.js`)),
    new: currentArtifacts.map(({ id }) => path.join(cachePath, id, `${id}.js`)),
  };
  const canonicalCurrentBundlePaths = currentArtifacts.map(({ id }) =>
    path.join(snapshotRoot, id, `${id}.js`),
  );

  bundleSets.old.forEach((bundlePath) => {
    fs.mkdirSync(path.dirname(bundlePath), { recursive: true });
    fs.copyFileSync(fixturePath, bundlePath);
  });
  bundleSets.new.forEach((requestBundlePath, index) => {
    const canonicalBundlePath = canonicalCurrentBundlePaths[index];
    fs.mkdirSync(path.dirname(canonicalBundlePath), { recursive: true });
    fs.mkdirSync(path.dirname(requestBundlePath), { recursive: true });
    fs.copyFileSync(fixturePath, canonicalBundlePath);
    fs.symlinkSync(path.relative(path.dirname(requestBundlePath), canonicalBundlePath), requestBundlePath);
  });
  const declarationDirectory = path.join(cachePath, '.current-generations');
  const manifestPath = path.join(declarationDirectory, `${generationId}.json`);
  fs.mkdirSync(declarationDirectory, { recursive: true });
  fs.writeFileSync(
    manifestPath,
    JSON.stringify({ schema_version: 1, generation_id: generationId, artifacts: currentArtifacts }),
  );
  const identityProbePaths = [...bundleSets.old, ...bundleSets.new, ...canonicalCurrentBundlePaths];

  const config = buildConfig({
    serverBundleCachePath: cachePath,
    workersCount: 0,
    supportModules: true,
    logLevel: 'silent',
    logHttpLevel: 'silent',
    vmPoolRolloutDrainTimeout: options.drainTimeoutMilliseconds / 1_000,
  });
  resetVM();
  global.gc?.();

  const observedContextIdentities = new Set();
  let inferredBuildCount = 0;
  let evictionTransitionCount = 0;
  let peakRssBytes = process.memoryUsage().rss;
  let peakHeapUsedBytes = process.memoryUsage().heapUsed;

  const observePoolTransition = (retainedBefore) => {
    const retainedAfter = new Set(
      identityProbePaths
        .map((bundlePath) => getVMContext(bundlePath))
        .filter((context) => context !== undefined),
    );
    retainedBefore.forEach((context) => {
      if (!retainedAfter.has(context)) {
        evictionTransitionCount += 1;
      }
    });
    retainedAfter.forEach((context) => {
      if (!observedContextIdentities.has(context)) {
        inferredBuildCount += 1;
      }
      observedContextIdentities.add(context);
    });
  };

  const buildBundleSet = async (bundlePaths, build = buildExecutionContext) => {
    const retainedBefore = new Set(
      identityProbePaths
        .map((bundlePath) => getVMContext(bundlePath))
        .filter((context) => context !== undefined),
    );
    const buildStartedAt = performance.now();
    const executionContext = await build(bundlePaths, true);
    executionContext.release();
    const buildLatencyMilliseconds = performance.now() - buildStartedAt;
    observePoolTransition(retainedBefore);
    const memory = process.memoryUsage();
    peakRssBytes = Math.max(peakRssBytes, memory.rss);
    peakHeapUsedBytes = Math.max(peakHeapUsedBytes, memory.heapUsed);
    return buildLatencyMilliseconds;
  };

  try {
    const declaration = manifestModule
      ? await manifestModule.loadCurrentGenerationManifest({
          manifestPath,
          serverBundleCachePath: cachePath,
        })
      : {
          bundlePaths: canonicalCurrentBundlePaths.map((bundlePath) => fs.realpathSync(bundlePath)),
          bundlePathAliases: [],
        };
    const startupStartedAt = performance.now();
    await buildBundleSet(
      declaration.bundlePaths,
      typeof prewarmDeclaredBundleGeneration === 'function'
        ? (bundlePaths) => prewarmDeclaredBundleGeneration(bundlePaths, declaration.bundlePathAliases)
        : buildExecutionContext,
    );
    const startupPrewarmMilliseconds = performance.now() - startupStartedAt;
    const startupPoolDiagnostics = getVMPoolDiagnostics();
    global.gc?.();
    const rssBeforeSamplesBytes = process.memoryUsage().rss;
    const heapUsedBeforeSamplesBytes = process.memoryUsage().heapUsed;
    peakRssBytes = Math.max(peakRssBytes, rssBeforeSamplesBytes);
    peakHeapUsedBytes = Math.max(peakHeapUsedBytes, heapUsedBeforeSamplesBytes);

    const sampleCount = Math.max(1, Math.round(options.durationSeconds * options.requestsPerSecond));
    const intervalMilliseconds = 1_000 / options.requestsPerSecond;
    const latenciesMilliseconds = [];
    const scheduleStartedAt = performance.now();

    for (let sampleIndex = 0; sampleIndex < sampleCount; sampleIndex += 1) {
      const scheduledAt = scheduleStartedAt + sampleIndex * intervalMilliseconds;
      // Sequential pacing is intentional: this measures one renderer worker's request path.
      // eslint-disable-next-line no-await-in-loop
      await sleep(Math.max(0, scheduledAt - performance.now()));
      // eslint-disable-next-line no-await-in-loop
      const buildLatencyMilliseconds = await buildBundleSet(bundleSets.old);
      latenciesMilliseconds.push(buildLatencyMilliseconds);
    }

    const drainWaitStartedAt = performance.now();
    await sleep(options.drainTimeoutMilliseconds + 25);
    const oldOnlyGapMilliseconds = performance.now() - scheduleStartedAt;
    const buildsBeforeFirstNewRequest = getVMPoolDiagnostics().contextsBuilt;
    const beforeFirstNewRequestPoolDiagnostics = getVMPoolDiagnostics();
    const firstNewRequestLatencyMilliseconds = await buildBundleSet(bundleSets.new);
    const firstNewRequestBuildCount = getVMPoolDiagnostics().contextsBuilt - buildsBeforeFirstNewRequest;
    const drainWaitMilliseconds = performance.now() - drainWaitStartedAt;

    global.gc?.();
    const finalMemory = process.memoryUsage();
    const finalPoolDiagnostics = getVMPoolDiagnostics();
    const retainedByGeneration = Object.fromEntries(
      Object.entries(bundleSets).map(([generation, bundlePaths]) => [
        generation,
        bundlePaths.filter((bundlePath) => getVMContext(bundlePath) !== undefined).length,
      ]),
    );
    const status = gitValue(['status', '--short']);
    const report = {
      benchmark: 'node_renderer_rollout_vm_pool',
      revision: gitValue(['rev-parse', 'HEAD']),
      dirty: status.length > 0,
      runtime: {
        node: process.version,
        architecture: process.arch,
        platform: process.platform,
        gcExposed: typeof global.gc === 'function',
      },
      scenario: {
        topology:
          'new_renderer_revision_prewarmed_then_receiving_only_old_rsc_traffic_before_first_new_request',
        bundleGenerations: 2,
        contextsPerGeneration: 2,
        workersCount: 0,
        effectiveWorkersPerReplica: 1,
        maxVMPoolSize: config.maxVMPoolSize,
        mode: options.mode,
        durationSeconds: options.durationSeconds,
        requestsPerSecond: options.requestsPerSecond,
        scheduler: 'serial_fixed_rate',
        declaredCurrentPrewarmAvailable: typeof prewarmDeclaredBundleGeneration === 'function',
        productionManifestLoaderAvailable: manifestModule !== undefined,
        startupBundleIdentity: 'validated_canonical_snapshot_target',
        firstNewRequestBundleIdentity: 'renderer_visible_symlink_path',
        drainTimeoutMilliseconds: options.drainTimeoutMilliseconds,
        measuredOldOnlyGapMilliseconds: oldOnlyGapMilliseconds,
        measuredDrainWaitMilliseconds: drainWaitMilliseconds,
      },
      startupPrewarmMilliseconds,
      startupPoolDiagnostics,
      beforeFirstNewRequestPoolDiagnostics,
      firstNewRequest: {
        latencyMilliseconds: firstNewRequestLatencyMilliseconds,
        buildCount: firstNewRequestBuildCount,
        vmHit: firstNewRequestBuildCount === 0,
      },
      latencyMilliseconds: {
        samples: latenciesMilliseconds.length,
        p50: percentile(latenciesMilliseconds, 0.5),
        p95: percentile(latenciesMilliseconds, 0.95),
        max: Math.max(...latenciesMilliseconds),
        timeoutThreshold: options.timeoutMilliseconds,
        timeoutCount: latenciesMilliseconds.filter((latency) => latency > options.timeoutMilliseconds).length,
      },
      inferredPoolActivity: {
        buildCount: finalPoolDiagnostics.contextsBuilt,
        rebuildCount: Math.max(0, finalPoolDiagnostics.contextsBuilt - 4),
        observedContextIdentityCount: inferredBuildCount,
        evictionTransitionCount,
        hardLimitEvictions: finalPoolDiagnostics.hardLimitEvictions,
        drainedContextRetirements: finalPoolDiagnostics.drainedContextRetirements,
        retainedContexts: Object.values(retainedByGeneration).reduce((sum, retained) => sum + retained, 0),
        retainedByGeneration,
      },
      memoryBytes: {
        rssBeforeSamples: rssBeforeSamplesBytes,
        peakRss: peakRssBytes,
        finalRssAfterGc: finalMemory.rss,
        heapUsedBeforeSamples: heapUsedBeforeSamplesBytes,
        peakHeapUsed: peakHeapUsedBytes,
        finalHeapUsedAfterGc: finalMemory.heapUsed,
      },
      caveats: [
        'Synthetic tiny fixture bundles; this does not claim cloned Rails workload parity.',
        'Serial fixed-rate scheduling models deterministic old-only traffic, not concurrent saturation.',
        'Latency isolates pool lookup/buildExecutionContext plus release; retained-set scans, transition instrumentation, memory sampling, and runInVM/render execution are excluded.',
        'Build, hard-limit, and drain counts come from pool diagnostics; transition and observed-identity counts are baseline-compatible instrumentation.',
        'Timeout count means completed samples above the threshold; the harness does not cancel in-flight builds.',
        'Disk seeding, manifest parsing, worker fork/listen, HTTP upload, and network latency are outside this harness.',
        'Startup compiles canonical snapshot targets while the first new request uses renderer-facing symlink paths; this exercises trusted alias identity.',
        'Baseline revisions without manifest loading or declared-current prewarm use the same canonical-to-symlink sequence but cannot register or pin aliases; availability fields record that distinction.',
        'ROLLOUT_BENCH_REPOSITORY_ROOT may point this unchanged harness at an exact detached baseline worktree.',
        'Runtime-only benchmark; visual parity is not applicable.',
        'Fresh processes and at least five quiet repeats are required for release evidence.',
      ],
    };

    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  } finally {
    resetVM();
    fs.rmSync(temporaryRoot, { recursive: true, force: true });
  }
}

run().catch((error) => {
  process.stderr.write(`${error.stack ?? error.message}\n`);
  process.exitCode = 1;
});
