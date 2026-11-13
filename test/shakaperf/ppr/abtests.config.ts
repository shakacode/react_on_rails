import { defineConfig, DESKTOP_VIEWPORT } from 'shaka-shared';

const DEFAULT_TARGET_URL = 'http://127.0.0.1:3000';

// Samples per side per test. PROVISIONAL default: the final value must be
// justified from observed run-to-run variance on the M1 runner (issue #5103
// acceptance criteria). Statistical floor: with pValueThreshold 0.05 the
// Wilcoxon signed-rank test cannot reach significance below 6 clean pairs
// (min two-sided p = 2^(1-n)), so never set this below 6.
const NUMBER_OF_MEASUREMENTS = Number(process.env.SHAKAPERF_PPR_MEASUREMENTS ?? 12);
// Enforce the floor, not just document it: below 6 pairs the Wilcoxon test can NEVER reach
// p < 0.05 (min p = 2^(1-n); n=4 gives 0.125), so the "no worse" statistical gate is silently
// blind — every undersampled run reports green regardless of regression size. NaN (a typo'd
// env value) would also sail through bare comparisons, so validate the shape too.
if (!Number.isInteger(NUMBER_OF_MEASUREMENTS) || NUMBER_OF_MEASUREMENTS < 6) {
  throw new Error(
    `SHAKAPERF_PPR_MEASUREMENTS must be an integer >= 6 (got ${JSON.stringify(
      process.env.SHAKAPERF_PPR_MEASUREMENTS,
    )}): below 6 paired samples the Wilcoxon test cannot reach p < 0.05, so the regression gate ` +
      'cannot fail — an undersampled run is not a release-gate run.',
  );
}

export default defineConfig({
  shared: {
    controlURL: process.env.SHAKAPERF_CONTROL_URL ?? DEFAULT_TARGET_URL,
    experimentURL:
      process.env.SHAKAPERF_EXPERIMENT_URL ?? process.env.SHAKAPERF_CONTROL_URL ?? DEFAULT_TARGET_URL,
    viewports: [DESKTOP_VIEWPORT],
    parallelism: 1,
    // No retries: the runner's default (2) retries ASSERTION failures, not just
    // infrastructure crashes, and a retry-recovered task passes the run as
    // merely "flaky". For this gate the guard's assertions ARE the evidence —
    // an intermittent warm-hit/resume failure must turn the gate red, not get
    // retried into a green verdict. Infrastructure flakes become terminal too;
    // rerunning the gate is cheap next to a false release verdict.
    retries: 0,
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
    // "No worse" enforcement: shaka-perf 0.1.3 fails the run (exit 1) on ANY
    // statistically significant slower-direction metric via its regression
    // chip — that verdict path never consults regressionThreshold, which is an
    // absolute tolerance in MILLISECONDS (not a ratio) feeding only the console
    // alert and a report.json field; 0.1ms keeps the alert aligned with the
    // verdict. The plan §6 improvement floor (warm-hit TTFB ≤ 10% of streaming)
    // is NOT machine-enforced by this stage — see README "Enforcement status".
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
