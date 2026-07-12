import { spawn, spawnSync } from 'node:child_process';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { format as formatOutput } from 'prettier';
import { classify, summarize } from './stats.mjs';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDirectory, '..');
const sampleCount = Number(readArgument('--samples') ?? 5);
const output = path.resolve(root, readArgument('--output') ?? 'results/latest.json');
const ports = { rspack: 4311, vite: 4312 };

if (!Number.isInteger(sampleCount) || sampleCount < 5) {
  throw new Error('--samples must be an integer of at least 5');
}

const browser = await chromium.launch({ headless: true });
const raw = {
  schema_version: 1,
  created_at: new Date().toISOString(),
  controls: {},
  environment: captureEnvironment(),
  methodology: {
    sample_count: sampleCount,
    order: 'alternating; Rspack first on odd iterations and Vite first on even iterations',
    cold_start: 'process spawn to first successful HTTP response; caches removed before each start',
    hmr: 'source write to browser-observed React DOM update over the live dev-server connection',
    overlay: 'browser DOM inspection after introducing a JavaScript syntax error, then restoration',
    noise_band: 'maximum observed min-to-max spread of either control; conservative, local-machine only',
  },
  raw_samples_ms: {
    cold_start: { rspack: [], vite: [] },
    hmr: { rspack: [], vite: [] },
  },
  overlay: {},
  zero_config: {},
};

try {
  for (let iteration = 0; iteration < sampleCount; iteration += 1) {
    const order = iteration % 2 === 0 ? ['rspack', 'vite'] : ['vite', 'rspack'];
    for (const tool of order) {
      const session = await startControl(tool);
      raw.raw_samples_ms.cold_start[tool].push(session.coldStartMs);
      await session.stop();
    }
  }

  for (const tool of ['rspack', 'vite']) {
    const session = await startControl(tool);
    try {
      raw.raw_samples_ms.hmr[tool] = await measureHmr(session.page, tool, sampleCount);
      raw.overlay[tool] = await inspectOverlay(session.page, tool);
      raw.controls[tool] = { command: commandFor(tool).join(' '), port: ports[tool] };
    } finally {
      await session.stop();
    }
    raw.zero_config[tool] = await inspectConfigSurface(tool);
  }
} finally {
  await browser.close();
  await restoreMarkers();
}

raw.summary = {};
for (const metric of ['cold_start', 'hmr']) {
  const rspack = summarize(raw.raw_samples_ms[metric].rspack);
  const vite = summarize(raw.raw_samples_ms[metric].vite);
  raw.summary[metric] = {
    rspack,
    vite,
    vite_relative_to_rspack: classify(rspack, vite),
  };
}

await mkdir(path.dirname(output), { recursive: true });
await writeFile(output, await formatOutput(JSON.stringify(raw), { parser: 'json' }));
console.log(`Wrote ${path.relative(root, output)}`);
console.log(JSON.stringify(raw.summary, null, 2));

async function startControl(tool) {
  const controlDirectory = path.join(root, 'controls', tool);
  await clearToolCaches(tool, controlDirectory);
  const logs = [];
  const startedAt = performance.now();
  const child = spawn(commandFor(tool)[0], commandFor(tool).slice(1), {
    cwd: controlDirectory,
    env: { ...process.env, FORCE_COLOR: '0', NO_COLOR: '1' },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  child.stdout.on('data', (chunk) => logs.push(chunk.toString()));
  child.stderr.on('data', (chunk) => logs.push(chunk.toString()));

  try {
    await waitForHttp(`http://127.0.0.1:${ports[tool]}`, child, logs);
    const coldStartMs = rounded(performance.now() - startedAt);
    const page = await browser.newPage();
    await page.goto(`http://127.0.0.1:${ports[tool]}`, { waitUntil: 'domcontentloaded' });
    await page.getByTestId('marker').waitFor();
    return {
      coldStartMs,
      page,
      async stop() {
        await page.close();
        await stopProcess(child);
      },
    };
  } catch (error) {
    await stopProcess(child);
    throw new Error(`${tool} failed to start: ${error.message}\n${logs.join('').slice(-4000)}`);
  }
}

async function measureHmr(page, tool, count) {
  const samples = [];
  const messagePath = path.join(root, 'controls', tool, 'src', 'message.js');
  for (let iteration = 0; iteration < count; iteration += 1) {
    const marker = `${tool}-hmr-${iteration}-${Date.now()}`;
    const startedAt = performance.now();
    await writeFile(messagePath, `export default ${JSON.stringify(marker)};\n`);
    await page.getByTestId('marker').filter({ hasText: marker }).waitFor({ timeout: 15_000 });
    samples.push(rounded(performance.now() - startedAt));
  }
  return samples;
}

async function inspectOverlay(page, tool) {
  const messagePath = path.join(root, 'controls', tool, 'src', 'message.js');
  await writeFile(messagePath, 'export default ;\n');
  const selectors =
    tool === 'vite'
      ? ['vite-error-overlay']
      : ['#rspack-dev-server-client-overlay', 'iframe#rspack-dev-server-client-overlay'];

  let matchedSelector = null;
  for (const selector of selectors) {
    try {
      await page.locator(selector).waitFor({ state: 'attached', timeout: 8_000 });
      matchedSelector = selector;
      break;
    } catch {
      // Try the next known overlay surface.
    }
  }

  let overlayText = null;
  if (matchedSelector && tool === 'rspack') {
    overlayText = (
      (await page.locator(matchedSelector).contentFrame().locator('body').innerText()) ?? ''
    ).slice(0, 500);
  } else if (matchedSelector && tool === 'vite') {
    overlayText = await page
      .locator(matchedSelector)
      .evaluate((element) => (element.shadowRoot?.textContent ?? '').slice(0, 500));
  }
  await writeFile(messagePath, "export default 'ready';\n");
  await page.getByTestId('marker').filter({ hasText: 'ready' }).waitFor({ timeout: 15_000 });

  return {
    compile_error_overlay_attached: matchedSelector !== null,
    matched_selector: matchedSelector,
    overlay_text_excerpt: sanitizePath(overlayText),
    click_to_editor_verified: false,
    click_to_editor_note:
      'Not asserted: editor protocol registration and overlay link behavior vary by host setup.',
  };
}

async function inspectConfigSurface(tool) {
  const fileName = tool === 'rspack' ? 'rspack.config.mjs' : 'vite.config.mjs';
  const contents = await readFile(path.join(root, 'controls', tool, fileName), 'utf8');
  const significantLines = contents
    .split('\n')
    .filter((line) => line.trim() && !line.trim().startsWith('//')).length;
  return {
    config_file: `controls/${tool}/${fileName}`,
    nonblank_noncomment_lines: significantLines,
    bytes: Buffer.byteLength(contents),
  };
}

async function clearToolCaches(tool, controlDirectory) {
  const paths =
    tool === 'rspack'
      ? [path.join(controlDirectory, 'dist'), path.join(controlDirectory, 'node_modules', '.cache')]
      : [path.join(controlDirectory, 'dist'), path.join(controlDirectory, 'node_modules', '.vite')];
  await Promise.all(paths.map((candidate) => rm(candidate, { recursive: true, force: true })));
}

async function waitForHttp(url, child, logs) {
  const deadline = Date.now() + 30_000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) {
      throw new Error(`process exited ${child.exitCode}; ${logs.join('').slice(-1000)}`);
    }
    try {
      const response = await fetch(url);
      if (response.ok) return;
    } catch {
      // The socket is expected to refuse connections until the server is ready.
    }
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
  throw new Error(`timed out waiting for ${url}`);
}

async function stopProcess(child) {
  if (child.exitCode !== null) return;
  child.kill('SIGTERM');
  await Promise.race([
    new Promise((resolve) => child.once('exit', resolve)),
    new Promise((resolve) => setTimeout(resolve, 2_000)),
  ]);
  if (child.exitCode === null) child.kill('SIGKILL');
}

function commandFor(tool) {
  if (tool === 'rspack') {
    return ['pnpm', 'exec', 'rspack', 'serve', '--config', 'rspack.config.mjs', '--port', `${ports.rspack}`];
  }
  return ['pnpm', 'exec', 'vite', '--host', '127.0.0.1', '--port', `${ports.vite}`, '--strictPort'];
}

function captureEnvironment() {
  return {
    git_head: run('git', ['rev-parse', 'HEAD']),
    operating_system: `${os.type()} ${os.release()} ${os.arch()}`,
    cpu: os.cpus()[0]?.model ?? 'UNKNOWN',
    logical_cpu_count: os.cpus().length,
    memory_bytes: os.totalmem(),
    node: process.version,
    pnpm: run('pnpm', ['--version']),
    rspack: run('pnpm', ['exec', 'rspack', '--version']),
    vite: run('pnpm', ['exec', 'vite', '--version']),
  };
}

function run(command, arguments_) {
  const result = spawnSync(command, arguments_, { cwd: root, encoding: 'utf8' });
  return result.status === 0 ? result.stdout.trim() : `UNKNOWN (${result.stderr.trim()})`;
}

async function restoreMarkers() {
  await Promise.all(
    ['rspack', 'vite'].map((tool) =>
      writeFile(path.join(root, 'controls', tool, 'src', 'message.js'), "export default 'ready';\n"),
    ),
  );
}

function readArgument(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}

function rounded(value) {
  return Math.round(value * 10) / 10;
}

function sanitizePath(value) {
  return value?.split(root).join('<benchmark-root>') ?? null;
}
