import { spawn, spawnSync } from 'node:child_process';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { format as formatOutput } from 'prettier';
import { assertExactlyOneEntry } from './html.mjs';
import { buildSummary } from './stats.mjs';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDirectory, '..');
const sampleCount = Number(readArgument('--samples') ?? 5);
const output = path.resolve(root, readArgument('--output') ?? 'results/latest.json');
const tools = ['rspack', 'vite'];

if (!Number.isInteger(sampleCount) || sampleCount < 5) {
  throw new Error('--samples must be an integer of at least 5');
}

const environment = captureEnvironment();
if (!environment.harness_git_clean) {
  throw new Error('benchmark must start from a clean committed harness');
}

const browser = await chromium.launch({ headless: true });
const raw = {
  schema_version: 1,
  created_at: new Date().toISOString(),
  controls: {},
  environment,
  methodology: {
    sample_count: sampleCount,
    order: 'alternating; Rspack first on odd iterations and Vite first on even iterations',
    cold_start: 'process spawn to first successful HTTP response; caches removed before each start',
    hmr: 'source write to browser-observed DOM update over the live dev-server connection',
    overlay: 'browser DOM inspection after introducing a JavaScript syntax error, then restoration',
    noise_band: 'maximum observed min-to-max spread of either control; conservative, local-machine only',
    stale_server_control:
      'ephemeral port preflight plus a unique compiled marker for every server process; shutdown awaits process exit and port closure',
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

  for (const tool of tools) {
    const session = await startControl(tool);
    try {
      raw.raw_samples_ms.hmr[tool] = await measureHmr(session.page, tool, sampleCount);
      raw.overlay[tool] = await inspectOverlay(session.page, tool);
      raw.controls[tool] = {
        command: commandFor(tool, '<PORT>').join(' '),
        measured_port: session.port,
        run_nonce: session.runNonce,
      };
    } finally {
      await session.stop();
    }
    raw.zero_config[tool] = await inspectConfigSurface(tool);
  }
} finally {
  await browser.close();
  await restoreMarkers();
}

raw.summary = buildSummary(raw.raw_samples_ms);

await mkdir(path.dirname(output), { recursive: true });
await writeFile(output, await formatOutput(JSON.stringify(raw), { parser: 'json' }));
console.log(`Wrote ${path.relative(root, output)}`);
console.log(JSON.stringify(raw.summary, null, 2));

async function startControl(tool) {
  const controlDirectory = path.join(root, 'controls', tool);
  const port = await reserveEphemeralPort();
  await assertPortAvailable(port);
  const runNonce = `${tool}-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const readyMarker = `ready-${runNonce}`;
  await writeMarker(tool, readyMarker);
  await clearToolCaches(tool, controlDirectory);
  const logs = [];
  const command = commandFor(tool, port);
  const startedAt = performance.now();
  const child = spawn(command[0], command.slice(1), {
    cwd: controlDirectory,
    detached: process.platform !== 'win32',
    env: { ...process.env, FORCE_COLOR: '0', NO_COLOR: '1' },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  child.stdout.on('data', (chunk) => logs.push(chunk.toString()));
  child.stderr.on('data', (chunk) => logs.push(chunk.toString()));

  try {
    const url = `http://127.0.0.1:${port}`;
    await waitForHttp(url, child, logs, tool);
    const coldStartMs = rounded(performance.now() - startedAt);
    const page = await browser.newPage();
    await page.goto(`${url}/?benchmark_nonce=${encodeURIComponent(runNonce)}`, {
      waitUntil: 'domcontentloaded',
    });
    await page.locator('#root').filter({ hasText: readyMarker }).waitFor({ timeout: 15_000 });
    return {
      coldStartMs,
      page,
      port,
      runNonce,
      async stop() {
        await page.close();
        await stopProcess(child, port);
      },
    };
  } catch (error) {
    await stopProcess(child, port);
    throw new Error(`${tool} failed to start: ${error.message}\n${logs.join('').slice(-4000)}`);
  }
}

async function measureHmr(page, tool, count) {
  const samples = [];
  for (let iteration = 0; iteration < count; iteration += 1) {
    const marker = `${tool}-hmr-${iteration}-${Date.now()}`;
    const startedAt = performance.now();
    await writeMarker(tool, marker);
    await page.locator('#root').filter({ hasText: marker }).waitFor({ timeout: 15_000 });
    samples.push(rounded(performance.now() - startedAt));
  }
  return samples;
}

async function inspectOverlay(page, tool) {
  const messagePath = messagePathFor(tool);
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
  await writeMarker(tool, 'ready');
  await page.locator('#root').filter({ hasText: 'ready' }).waitFor({ timeout: 15_000 });

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

async function waitForHttp(url, child, logs, tool) {
  const deadline = Date.now() + 30_000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) {
      throw new Error(`process exited ${child.exitCode}; ${logs.join('').slice(-1000)}`);
    }
    try {
      const response = await fetch(url);
      if (response.ok) {
        assertExactlyOneEntry(await response.text(), tool);
        return;
      }
    } catch (error) {
      if (error.message.startsWith('expected exactly one')) throw error;
      // The socket is expected to refuse connections until the server is ready.
    }
    await delay(10);
  }
  throw new Error(`timed out waiting for ${url}`);
}

async function stopProcess(child, port) {
  if (child.exitCode === null) {
    const exited = new Promise((resolve) => child.once('exit', resolve));
    signalProcessGroup(child, 'SIGTERM');
    const exitedGracefully = await Promise.race([exited.then(() => true), delay(2_000).then(() => false)]);
    if (!exitedGracefully) {
      signalProcessGroup(child, 'SIGKILL');
      await exited;
    }
  }

  try {
    await waitForPortClosed(port, 500);
  } catch {
    signalProcessGroup(child, 'SIGKILL');
    await waitForPortClosed(port, 3_000);
  }
}

function signalProcessGroup(child, signal) {
  try {
    if (process.platform === 'win32') child.kill(signal);
    else process.kill(-child.pid, signal);
  } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
}

async function reserveEphemeralPort() {
  const server = net.createServer();
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  const address = server.address();
  await closeServer(server);
  if (!address || typeof address === 'string') throw new Error('could not reserve an ephemeral port');
  return address.port;
}

async function assertPortAvailable(port) {
  const server = net.createServer();
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, '127.0.0.1', resolve);
  });
  await closeServer(server);
}

async function closeServer(server) {
  await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
}

async function waitForPortClosed(port, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (!(await canConnect(port))) return;
    await delay(10);
  }
  throw new Error(`port ${port} remained open after process shutdown`);
}

async function canConnect(port) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host: '127.0.0.1', port });
    const finish = (connected) => {
      socket.destroy();
      resolve(connected);
    };
    socket.setTimeout(100, () => finish(false));
    socket.once('connect', () => finish(true));
    socket.once('error', () => finish(false));
  });
}

function commandFor(tool, port) {
  if (tool === 'rspack') {
    return ['pnpm', 'exec', 'rspack', 'serve', '--config', 'rspack.config.mjs', '--port', `${port}`];
  }
  return ['pnpm', 'exec', 'vite', '--host', '127.0.0.1', '--port', `${port}`, '--strictPort'];
}

function captureEnvironment() {
  const gitStatus = spawnSync('git', ['status', '--porcelain=v1'], { cwd: root, encoding: 'utf8' });
  if (gitStatus.status !== 0) throw new Error(`git status failed: ${gitStatus.stderr.trim()}`);
  return {
    harness_git_head: run('git', ['rev-parse', 'HEAD']),
    harness_git_clean: gitStatus.stdout.trim() === '',
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

async function writeMarker(tool, marker) {
  await writeFile(messagePathFor(tool), `export default ${JSON.stringify(marker)};\n`);
}

function messagePathFor(tool) {
  return path.join(root, 'controls', tool, 'src', 'message.js');
}

async function restoreMarkers() {
  await Promise.all(tools.map((tool) => writeMarker(tool, 'ready')));
}

function readArgument(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}

function rounded(value) {
  return Math.round(value * 10) / 10;
}

function sanitizePath(value) {
  return value?.replaceAll(root, '<benchmark-root>') ?? null;
}
