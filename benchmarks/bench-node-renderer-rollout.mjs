#!/usr/bin/env node

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { performance } from 'node:perf_hooks';

const require = createRequire(import.meta.url);
const benchmarkPath = fileURLToPath(import.meta.url);
const repositoryRoot = path.resolve(path.dirname(benchmarkPath), '..');
const packageRoot = path.join(repositoryRoot, 'packages/react-on-rails-pro-node-renderer');

function parseArguments(argv) {
  const options = {
    mode: 'full',
    durationSeconds: undefined,
    requestsPerSecond: 3,
    timeoutMilliseconds: 1_000,
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
  const { buildExecutionContext, getVMContext, resetVM } = require(vmModulePath);
  const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'ror-node-renderer-rollout-'));
  const bundleSets = {
    old: ['server', 'rsc'].map((role) => path.join(temporaryRoot, 'old', `${role}.js`)),
    new: ['server', 'rsc'].map((role) => path.join(temporaryRoot, 'new', `${role}.js`)),
  };

  Object.values(bundleSets)
    .flat()
    .forEach((bundlePath) => {
      fs.mkdirSync(path.dirname(bundlePath), { recursive: true });
      fs.copyFileSync(fixturePath, bundlePath);
    });
  const allBundlePaths = Object.values(bundleSets).flat();

  const config = buildConfig({
    serverBundleCachePath: temporaryRoot,
    workersCount: 0,
    supportModules: true,
    logLevel: 'silent',
    logHttpLevel: 'silent',
  });
  resetVM();
  global.gc?.();

  const identityByBundlePath = new Map();
  let inferredBuildCount = 0;
  let inferredRebuildCount = 0;
  let evictionTransitionCount = 0;
  let peakRssBytes = process.memoryUsage().rss;
  let peakHeapUsedBytes = process.memoryUsage().heapUsed;

  const observePoolTransition = (retainedBefore) => {
    const retainedAfter = new Set(
      allBundlePaths.filter((bundlePath) => getVMContext(bundlePath) !== undefined),
    );
    retainedBefore.forEach((bundlePath) => {
      if (!retainedAfter.has(bundlePath)) {
        evictionTransitionCount += 1;
      }
    });
    retainedAfter.forEach((bundlePath) => {
      const currentIdentity = getVMContext(bundlePath);
      const previousIdentity = identityByBundlePath.get(bundlePath);
      if (previousIdentity === undefined) {
        inferredBuildCount += 1;
      } else if (previousIdentity !== currentIdentity) {
        inferredBuildCount += 1;
        inferredRebuildCount += 1;
      }
      identityByBundlePath.set(bundlePath, currentIdentity);
    });
  };

  const buildBundleSet = async (bundlePaths) => {
    const retainedBefore = new Set(
      allBundlePaths.filter((bundlePath) => getVMContext(bundlePath) !== undefined),
    );
    const buildStartedAt = performance.now();
    const executionContext = await buildExecutionContext(bundlePaths, true);
    executionContext.release();
    const buildLatencyMilliseconds = performance.now() - buildStartedAt;
    observePoolTransition(retainedBefore);
    const memory = process.memoryUsage();
    peakRssBytes = Math.max(peakRssBytes, memory.rss);
    peakHeapUsedBytes = Math.max(peakHeapUsedBytes, memory.heapUsed);
    return buildLatencyMilliseconds;
  };

  try {
    await buildBundleSet(bundleSets.old);
    await buildBundleSet(bundleSets.new);
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
      const bundlePaths = sampleIndex % 2 === 0 ? bundleSets.old : bundleSets.new;
      // eslint-disable-next-line no-await-in-loop
      const buildLatencyMilliseconds = await buildBundleSet(bundlePaths);
      latenciesMilliseconds.push(buildLatencyMilliseconds);
    }

    global.gc?.();
    const finalMemory = process.memoryUsage();
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
        topology: 'one_shared_renderer_process_receiving_alternating_old_and_new_rsc_bundle_sets',
        bundleGenerations: 2,
        contextsPerGeneration: 2,
        workersCount: 0,
        effectiveWorkersPerReplica: 1,
        maxVMPoolSize: config.maxVMPoolSize,
        mode: options.mode,
        durationSeconds: options.durationSeconds,
        requestsPerSecond: options.requestsPerSecond,
        scheduler: 'serial_fixed_rate',
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
        buildCount: inferredBuildCount,
        rebuildCount: inferredRebuildCount,
        evictionTransitionCount,
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
        'Serial fixed-rate scheduling models deterministic 3 rps alternation, not concurrent saturation.',
        'Latency isolates pool lookup/buildExecutionContext plus release; retained-set scans, transition instrumentation, memory sampling, and runInVM/render execution are excluded.',
        'Build and eviction counts are inferred from baseline-compatible VM identity and retained-path transitions.',
        'Timeout count means completed samples above the threshold; the harness does not cancel in-flight builds.',
        'Disk seeding and HTTP upload are outside this harness; no supported eager VM-prewarm API is invoked.',
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
