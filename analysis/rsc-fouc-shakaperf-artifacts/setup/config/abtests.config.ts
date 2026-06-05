import * as os from 'node:os';
import * as path from 'node:path';
import { defineConfig, assignPortsAutomatically, DESKTOP_VIEWPORT } from 'shaka-shared';

// Auto-assign the control/experiment host ports from a required preferred pair.
// If either port is in use, BOTH shift up by 1 together — preserving their gap —
// until the first free pair is found; the pair is then remembered per project
// (in ~/.shaka-perf/ports.json) so it stays stable across runs. Set
// SHAKAPERF_CONTROL_PORT / SHAKAPERF_EXPERIMENT_PORT to override entirely. The
// same pair feeds the URLs and twinServers.ports below, so they can't drift.
const { control: CONTROL_PORT, experiment: EXPERIMENT_PORT } = assignPortsAutomatically({
  control: 3020,
  experiment: 3030,
});

const parseArtifactParallelism = (value: string | undefined) => {
  const trimmedValue = value?.trim();
  if (!trimmedValue) {
    return undefined;
  }

  const parsedValue = Number(trimmedValue);
  if (!Number.isFinite(parsedValue)) {
    console.warn(
      `[shakaperf] SHAKAPERF_ARTIFACT_PARALLELISM="${value}" is not a finite number; falling back to auto-detected default.`,
    );
    return undefined;
  }

  const parallelism = Math.floor(parsedValue);
  if (parallelism <= 0) {
    console.warn(
      `[shakaperf] SHAKAPERF_ARTIFACT_PARALLELISM="${value}" parsed to ${parallelism}; falling back to auto-detected default.`,
    );
    return undefined;
  }

  return parallelism;
};

const CONFIGURED_PARALLELISM = parseArtifactParallelism(process.env.SHAKAPERF_ARTIFACT_PARALLELISM);
const DEFAULT_PARALLELISM = Math.max(1, Math.floor(os.availableParallelism() / 2));
const PARALLELISM = CONFIGURED_PARALLELISM ?? DEFAULT_PARALLELISM;
const CHROMIUM_ARGS = process.env.SHAKAPERF_CHROMIUM_NO_SANDBOX === 'true' ? ['--no-sandbox'] : [];

export const rscFoucShakaPerfConfig = {
  shared: {
    controlURL: `http://localhost:${CONTROL_PORT}`,
    experimentURL: `http://localhost:${EXPERIMENT_PORT}`,
    viewports: [DESKTOP_VIEWPORT],
    parallelism: PARALLELISM,
  },

  visreg: {
    viewports: ['desktop'],
    defaultMisMatchThreshold: 0.1,
    maxNumDiffPixels: 50,
    comparePixelmatchThreshold: 0.1,
    engineOptions: {
      browser: 'chromium',
      // Set SHAKAPERF_CHROMIUM_NO_SANDBOX=true only when the ShakaPerf
      // browser runner itself is inside Docker and Chromium cannot sandbox.
      args: CHROMIUM_ARGS,
    },
  },

  perf: {
    numberOfMeasurements: 20,
    regressionThreshold: 0.1,
    pValueThreshold: 0.05,
    regressionThresholdStat: 'estimator',
    samplingMode: 'simultaneous',
    lighthouseTimeoutMs: 45_000,
    viewports: ['desktop'],
  },

  audit: {
    lighthouseTimeoutMs: 45_000,
    viewports: ['desktop'],
  },

  // Twin-servers (Docker A/B testing infra). `ports` reuses the constants
  // above so the host-port mapping, the URLs visreg/perf hit, and
  // `servers notify-server-started` all stay in sync. Run `shaka-perf servers`
  // to build + start both sides. If you don't use twin-servers, delete this.
  twinServers: {
    // This checkout is the experiment side. Use `process.cwd()` when running
    // twin-servers from inside the experiment repo (the common case).
    experimentDir: process.cwd(),
    // Baseline (control) checkout: a sibling dir named after this one with
    // `-control` appended, so it adapts to whatever the repo is called rather
    // than a hardcoded name. `servers build` offers to clone it here if missing.
    controlDir: process.env.SHAKAPERF_CONTROL_DIR || `../${path.basename(process.cwd())}-control`,
    // Local build context. The same relative offset is applied under
    // experimentDir/controlDir when building those images.
    // The paired Dockerfile.dockerignore keeps the repo-root context reproducible
    // while excluding generated artifacts, node_modules, .git, and secrets.
    dockerBuildDir: '.',
    dockerfile: 'twin-servers/Dockerfile',
    dockerBuildArgs: {
      RUBY_VERSION: '3.3.7',
      NODE_VERSION: '22.12.0',
      PNPM_VERSION: '10.33.4',
    },
    // Procfile/composeFile are resolved relative to this local project dir.
    procfile: 'twin-servers/Procfile',
    ports: {
      control: CONTROL_PORT,
      experiment: EXPERIMENT_PORT,
    },
    // No `setupCommands` by default: do all setup (install, build, migrate,
    // seed) in the Dockerfile so the image is self-contained. They're a last
    // resort for what can't be baked into an image — chiefly starting an
    // embedded service daemon — and run in both containers at start.
  },
} satisfies Parameters<typeof defineConfig>[0];

export default defineConfig(rscFoucShakaPerfConfig);
