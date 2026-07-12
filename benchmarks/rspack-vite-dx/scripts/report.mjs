import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { format as formatMarkdown } from 'prettier';
import { verifySummary } from './stats.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rawArgument = readArgument('--raw') ?? 'results/recorded.json';
const outputArgument = readArgument('--output') ?? 'RESULTS.md';
const rawPath = path.resolve(root, rawArgument);
const outputPath = path.resolve(root, outputArgument);
const raw = JSON.parse(await readFile(rawPath, 'utf8'));
const verified = { ...raw, summary: verifySummary(raw) };
const rendered = await formatMarkdown(render(verified, path.relative(root, rawPath)), {
  parser: 'markdown',
});

if (process.argv.includes('--check')) {
  const current = await readFile(outputPath, 'utf8');
  if (current !== rendered) {
    console.error(
      `${path.relative(root, outputPath)} is stale; regenerate it with pnpm exec node scripts/report.mjs`,
    );
    process.exitCode = 1;
  }
} else {
  await writeFile(outputPath, rendered);
  console.log(`Wrote ${path.relative(root, outputPath)}`);
}

function render(result, relativeRawPath) {
  const cold = result.summary.cold_start;
  const hmr = result.summary.hmr;
  const rspackConfig = result.zero_config.rspack;
  const viteConfig = result.zero_config.vite;
  return `# Recorded Rspack vs Vite DX control result

Generated from [${relativeRawPath}](${relativeRawPath}) by \`scripts/report.mjs\`. Do not edit this table by hand.

| Metric | Rspack median (min–max) | Vite median (min–max) | Vite relative to Rspack |
| --- | ---: | ---: | --- |
| Cold start to HTTP ready | ${format(cold.rspack)} | ${format(cold.vite)} | **${cold.vite_relative_to_rspack}** |
| Browser-observed HMR | ${format(hmr.rspack)} | ${format(hmr.vite)} | **${hmr.vite_relative_to_rspack}** |

Each timing has ${result.methodology.sample_count} samples. The conservative noise band is the larger observed min-to-max spread for that metric. This machine-local result is not a universal product ranking.

| Surface check | Rspack | Vite |
| --- | --- | --- |
| Compile-error overlay | ${observedStatus(result.overlay.rspack.compile_error_overlay_attached)} | ${observedStatus(result.overlay.vite.compile_error_overlay_attached)} |
| Click-to-editor | ${verificationStatus(result.overlay.rspack.click_to_editor_verified)} | ${verificationStatus(result.overlay.vite.click_to_editor_verified)} |
| Explicit config lines | ${rspackConfig.nonblank_noncomment_lines} | ${viteConfig.nonblank_noncomment_lines} |

## Environment

- Recorded: ${result.created_at}
- Harness commit: \`${result.environment.harness_git_head ?? result.environment.git_head}\`
- Harness worktree clean at start: ${result.environment.harness_git_clean ?? 'UNKNOWN'}
- OS: ${result.environment.operating_system}
- CPU: ${result.environment.cpu} (${result.environment.logical_cpu_count} logical CPUs)
- Node: ${result.environment.node}; pnpm: ${result.environment.pnpm}
- Rspack: ${result.environment.rspack}; Vite: ${result.environment.vite}

## Interpretation boundary

This run compares matched, minimal JavaScript controls and isolates dev-server startup, module replacement reaching a real browser, compile-error overlay attachment, and explicit bundler configuration. It does **not** compare generated Rails applications, \`vite_ruby\`, Inertia, Rails startup, React transforms or Fast Refresh, runtime-error overlays, or click-to-editor integration. Accordingly, it is reproducible control evidence, not sufficient evidence for a supported “Rspack matches Vite” onboarding claim.
`;
}

function format(summary) {
  return `${summary.median_ms} ms (${summary.min_ms}–${summary.max_ms})`;
}

function observedStatus(value) {
  return value ? 'observed' : 'not observed';
}

function verificationStatus(value) {
  return value ? 'verified' : 'not tested';
}

function readArgument(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}
