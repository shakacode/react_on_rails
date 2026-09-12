import { readFile, writeFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { format as formatOutput } from 'prettier';
import { captureEnvironment, startApp } from './app-session.mjs';
import { prepareWorkspaces, removeWorkspaces } from './starter-workspace.mjs';
import { buildSummary } from './stats.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sampleCount = Number(readArgument('--samples') ?? 5);
const output = path.resolve(root, readArgument('--output') ?? 'results/latest.json');
const tools = ['rspack', 'vite'];
let browser;
let activeSession;

if (!Number.isInteger(sampleCount) || sampleCount < 5)
  throw new Error('--samples must be an integer of at least 5');

const environment = captureEnvironment(root);
if (!environment.harness_git_clean) throw new Error('benchmark must start from a clean committed worktree');

await prepareWorkspaces(root);
const raw = {
  schema_version: 1,
  created_at: new Date().toISOString(),
  environment,
  methodology: {
    sample_count: sampleCount,
    order: 'cold starts alternate stack order; Fast Refresh markers alternate values within each stack',
    cold_start: 'bin/dev process spawn to the generated React marker becoming visible in Chromium',
    fast_refresh:
      'source write to browser-observed marker update while a typed input value remains unchanged',
    cache_policy:
      'a fresh ignored starter copy and empty app caches for every cold start; installed dependencies are shared',
    noise_policy:
      'ambiguous above 50% spread; otherwise differences inside the larger observed min-to-max spread are a wash',
    stale_server_control:
      'preflighted ports plus a unique marker compiled into every process; shutdown waits for process exit and closed ports',
  },
  raw_samples_ms: {
    cold_start: { rspack: [], vite: [] },
    fast_refresh: { rspack: [], vite: [] },
  },
  fast_refresh_state_preserved: { rspack: [], vite: [] },
  generated_config_audit: {},
};

try {
  browser = await chromium.launch({ headless: true });
  for (let iteration = 0; iteration < sampleCount; iteration += 1) {
    const order = iteration % 2 === 0 ? tools : [...tools].reverse();
    for (const tool of order) {
      const session = await startApp({ browser, root, tool, label: `cold-${iteration}` });
      activeSession = session;
      raw.raw_samples_ms.cold_start[tool].push(session.readyMs);
      await session.stop();
      activeSession = undefined;
    }
  }

  for (const tool of tools) {
    const session = await startApp({ browser, root, tool, label: 'refresh' });
    activeSession = session;
    try {
      const input = session.page.locator('[data-benchmark-input]');
      await input.fill(`state-${tool}`);
      for (let iteration = 0; iteration < sampleCount; iteration += 1) {
        const marker = `${tool}-refresh-${iteration % 2 === 0 ? 'a' : 'b'}-${iteration}`;
        const startedAt = performance.now();
        await session.workspace.setMarker(marker);
        await session.page
          .locator('[data-benchmark-marker]')
          .filter({ hasText: marker })
          .waitFor({ timeout: 30_000 });
        raw.raw_samples_ms.fast_refresh[tool].push(round(performance.now() - startedAt));
        const preserved = (await input.inputValue()) === `state-${tool}`;
        raw.fast_refresh_state_preserved[tool].push(preserved);
        if (!preserved) throw new Error(`${tool} Fast Refresh did not preserve component state`);
      }
    } finally {
      await session.stop();
      activeSession = undefined;
    }
    raw.generated_config_audit[tool] = await inspectConfig(tool);
  }
} finally {
  await activeSession?.stop();
  await browser?.close();
  await removeWorkspaces(root);
}

raw.summary = buildSummary(raw.raw_samples_ms);
await mkdir(path.dirname(output), { recursive: true });
await writeFile(output, await formatOutput(JSON.stringify(raw), { parser: 'json' }));
console.log(`Wrote ${path.relative(root, output)}`);
console.log(JSON.stringify(raw.summary, null, 2));

async function inspectConfig(tool) {
  const files =
    tool === 'rspack'
      ? [
          'Procfile.dev',
          'config/shakapacker.yml',
          'config/rspack/rspack.config.ts',
          'config/rspack/commonWebpackConfig.js',
          'config/rspack/clientWebpackConfig.js',
          'config/rspack/serverWebpackConfig.js',
          'config/rspack/development.js',
        ]
      : ['Procfile.dev', 'config/vite.json', 'vite.config.mts'];
  const records = [];
  for (const file of files) {
    const contents = await readFile(path.join(root, 'starters', tool, file), 'utf8');
    records.push({
      file: `starters/${tool}/${file}`,
      bytes: Buffer.byteLength(contents),
      nonblank_noncomment_lines: contents.split('\n').filter((line) => {
        const text = line.trim();
        return text && !text.startsWith('#') && !text.startsWith('//');
      }).length,
    });
  }
  return {
    files: records,
    total_files: records.length,
    total_nonblank_noncomment_lines: records.reduce(
      (sum, record) => sum + record.nonblank_noncomment_lines,
      0,
    ),
    caution: 'descriptive generated-file surface only; line counts are not a usability score',
  };
}

function readArgument(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}

function round(value) {
  return Math.round(value * 10) / 10;
}
