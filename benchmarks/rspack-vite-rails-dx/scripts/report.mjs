import { readFile, realpath, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { format as formatMarkdown } from 'prettier';
import { assertNoLocalPaths } from './local-paths.mjs';
import { verifySummary } from './stats.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rawArgument = readArgument('--raw') ?? 'results/recorded.json';
const outputArgument = readArgument('--output') ?? 'RESULTS.md';
const rawPath = path.resolve(root, rawArgument);
const outputPath = path.resolve(root, outputArgument);
const raw = JSON.parse(await readFile(rawPath, 'utf8'));
assertNoLocalPaths(raw, [...new Set([root, await realpath(root)])]);
const result = { ...raw, summary: verifySummary(raw) };
const rendered = await formatMarkdown(render(result, path.relative(root, rawPath)), { parser: 'markdown' });

if (process.argv.includes('--check')) {
  if ((await readFile(outputPath, 'utf8')) !== rendered) {
    console.error(
      `${path.relative(root, outputPath)} is stale; regenerate it with pnpm exec node scripts/report.mjs`,
    );
    process.exitCode = 1;
  }
} else {
  await writeFile(outputPath, rendered);
  console.log(`Wrote ${path.relative(root, outputPath)}`);
}

function render(data, relativeRawPath) {
  const cold = data.summary.cold_start;
  const refresh = data.summary.fast_refresh;
  const rspackConfig = data.generated_config_audit.rspack;
  const viteConfig = data.generated_config_audit.vite;
  return `# Recorded Rails-tier Rspack vs Vite DX result

Generated from [${relativeRawPath}](${relativeRawPath}) by \`scripts/report.mjs\`. Do not edit the tables by hand.

| Metric | React on Rails + Rspack median (min–max) | Inertia Rails + Vite median (min–max) | Vite relative to Rspack |
| --- | ---: | ---: | --- |
| Generated dev environment to browser-ready React | ${format(cold.rspack)} | ${format(cold.vite)} | **${cold.vite_relative_to_rspack}** |
| Browser-observed React Fast Refresh | ${format(refresh.rspack)} | ${format(refresh.vite)} | **${refresh.vite_relative_to_rspack}** |

Each timing has ${data.methodology.sample_count} samples. The conservative noise band is the larger observed min-to-max spread for that metric. A result is ambiguous when either spread exceeds 50% of its median.

| Generated configuration audit | React on Rails + Rspack | Inertia Rails + Vite |
| --- | ---: | ---: |
| Files in the declared config surface | ${rspackConfig.total_files} | ${viteConfig.total_files} |
| Nonblank, non-comment lines | ${rspackConfig.total_nonblank_noncomment_lines} | ${viteConfig.total_nonblank_noncomment_lines} |
| Fast Refresh preserved typed React state in every sample | ${yes(data.fast_refresh_state_preserved.rspack.every(Boolean))} | ${yes(data.fast_refresh_state_preserved.vite.every(Boolean))} |

Configuration counts describe generated files only. They are not a usability score.

## Environment

- Recorded: ${data.created_at}
- Harness commit: \`${data.environment.harness_git_head}\`
- Worktree clean at start: ${data.environment.harness_git_clean}
- OS: ${data.environment.operating_system}
- CPU: ${data.environment.cpu} (${data.environment.logical_cpu_count} logical CPUs)
- Memory: ${Math.round(data.environment.total_memory_bytes / 1024 / 1024 / 1024)} GiB
- Node: ${data.environment.node}; pnpm: ${data.environment.pnpm}; Ruby: ${data.environment.ruby}
- Rails: Rspack starter ${data.environment.rails.rspack}; Vite starter ${data.environment.rails.vite}
- Rspack stack: ${data.environment.dependencies.rspack_ruby}; ${data.environment.dependencies.rspack_javascript}
- Vite stack: ${data.environment.dependencies.vite_ruby}; ${data.environment.dependencies.vite_javascript}

## Interpretation boundary

This is a same-machine development benchmark of two pinned generated Rails starters. It measures each generator's normal \`bin/dev\` path through a real browser, including Rails boot, asset startup, React rendering, and state-preserving Fast Refresh. It does not isolate bundler cost, score onboarding comprehension, measure production builds, test runtime-error overlay quality, or verify click-to-editor. Results can vary with hardware, filesystem caches, background load, and dependency versions.

Use this package with the bare-JavaScript control from [issue #4612](https://github.com/shakacode/react_on_rails/pull/4612) to inform [the broader DX positioning issue #4600](https://github.com/shakacode/react_on_rails/issues/4600). Do not turn one machine-local run into a universal “parity,” “faster,” or “near-instant” claim.
`;
}

function format(summary) {
  return `${summary.median_ms} ms (${summary.min_ms}–${summary.max_ms})`;
}

function yes(value) {
  return value ? 'yes' : 'no';
}

function readArgument(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}
