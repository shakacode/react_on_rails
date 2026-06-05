import { defineConfig, DESKTOP_VIEWPORT } from 'shaka-shared';

const DEFAULT_TARGET_URL = 'http://127.0.0.1:3000';

export default defineConfig({
  shared: {
    controlURL: process.env.SHAKAPERF_CONTROL_URL ?? DEFAULT_TARGET_URL,
    experimentURL:
      process.env.SHAKAPERF_EXPERIMENT_URL ?? process.env.SHAKAPERF_CONTROL_URL ?? DEFAULT_TARGET_URL,
    viewports: [DESKTOP_VIEWPORT],
    parallelism: 1,
  },

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

  // ShakaPerf validates all category defaults while loading the config, even
  // when this release gate runs only `--categories visreg`.
  perf: {
    viewports: ['desktop'],
    numberOfMeasurements: 1,
    regressionThreshold: 0.1,
    pValueThreshold: 0.05,
    regressionThresholdStat: 'estimator',
    samplingMode: 'simultaneous',
    lighthouseTimeoutMs: 45_000,
  },

  audit: {
    viewports: ['desktop'],
    lighthouseTimeoutMs: 45_000,
  },
});
