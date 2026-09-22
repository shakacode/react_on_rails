import { defineConfig, DESKTOP_VIEWPORT } from 'shaka-shared';

const DEFAULT_TARGET_URL = 'http://127.0.0.1:3000';

// Samples per side per test. PROVISIONAL default: the final value must be
// justified from observed run-to-run variance on the M1 runner (issue #5103
// acceptance criteria). Statistical floor: with pValueThreshold 0.05 the
// Wilcoxon signed-rank test cannot reach significance below 6 clean pairs
// (min two-sided p = 2^(1-n)), so never set this below 6.
const NUMBER_OF_MEASUREMENTS = Number(process.env.SHAKAPERF_PPR_MEASUREMENTS ?? 12);

export default defineConfig({
  shared: {
    controlURL: process.env.SHAKAPERF_CONTROL_URL ?? DEFAULT_TARGET_URL,
    experimentURL:
      process.env.SHAKAPERF_EXPERIMENT_URL ?? process.env.SHAKAPERF_CONTROL_URL ?? DEFAULT_TARGET_URL,
    viewports: [DESKTOP_VIEWPORT],
    parallelism: 1,
  },

  // ShakaPerf validates all category defaults while loading the config, even
  // though this release gate runs only `--categories perf`.
  visreg: {
    viewports: ['desktop'],
    defaultMisMatchThreshold: 0.001,
    maxNumDiffPixels: 50,
    comparePixelmatchThreshold: 0.1,
    compareRetries: 3,
    compareRetryDelay: 500,
    engineOptions: {
      browser: 'chromium',
      args: ['--no-sandbox'],
      gotoParameters: { waitUntil: 'commit' },
    },
  },

  // The live category for this gate. First actual use of `--categories perf`
  // in this repo — the rsc-fouc gate declares this block but runs visreg only.
  perf: {
    viewports: ['desktop'],
    numberOfMeasurements: NUMBER_OF_MEASUREMENTS,
    regressionThreshold: 0.1,
    pValueThreshold: 0.05,
    regressionThresholdStat: 'estimator',
    // Control and experiment are DIFFERENT ROUTES ON THE SAME SERVER
    // (#3255 Decision 5: same delivery path within each pair). Simultaneous
    // sampling takes each pair at the same moment (barrier-synchronized), so
    // machine noise hits both sides of a pair equally — shaka-perf deprecates
    // 'sequential' and its NOISE_RESISTANT_PERF_TESTS_STUDY.md documents why
    // paired-simultaneous wins even at the cost of the two sides sharing the
    // server during a sample.
    samplingMode: 'simultaneous',
    // No throttling: plan §6's target is a ratio of observed server/render
    // times on one host. Simulated network (the harness default: 300ms RTT
    // at 700kbps) would swamp the localhost TTFB difference the gate exists
    // to measure, and modeled LCP would replace the observed one.
    lighthouseConfig: {
      throttlingMethod: 'provided',
      logLevel: 'error',
      output: 'html',
      onlyCategories: ['performance'],
      maxWaitForLoad: 45_000,
    },
  },

  audit: {
    viewports: ['desktop'],
  },
});
