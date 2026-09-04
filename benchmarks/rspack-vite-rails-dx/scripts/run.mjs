import { spawn, spawnSync } from 'node:child_process';
import { readFile, realpath, rm, writeFile, mkdir } from 'node:fs/promises';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { setTimeout as delay } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { format as formatOutput } from 'prettier';
import { redactLocalPaths } from './local-paths.mjs';
import { createWorkspace, prepareWorkspaces, removeWorkspaces } from './starter-workspace.mjs';
import { buildSummary } from './stats.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repositoryRoot = path.resolve(root, '../..');
const rootAliases = [
  ...new Set([root, await realpath(root), repositoryRoot, await realpath(repositoryRoot)]),
];
const sampleCount = Number(readArgument('--samples') ?? 5);
const output = path.resolve(root, readArgument('--output') ?? 'results/latest.json');
const tools = ['rspack', 'vite'];
const maxLogCharacters = 8_000;
let browser;
let activeSession;

if (!Number.isInteger(sampleCount) || sampleCount < 5)
  throw new Error('--samples must be an integer of at least 5');

const environment = captureEnvironment();
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
      const session = await startApp(tool, `cold-${iteration}`);
      raw.raw_samples_ms.cold_start[tool].push(session.readyMs);
      await session.stop();
    }
  }

  for (const tool of tools) {
    const session = await startApp(tool, 'refresh');
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

async function startApp(tool, label) {
  const nonce = `${label}-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const workspace = await createWorkspace(root, tool, nonce);
  const marker = `ready-${tool}-${nonce}`;
  await workspace.setMarker(marker);
  await clearSharedToolCache(tool);
  const basePort = await reservePortRange();
  const webPort = tool === 'rspack' ? basePort : basePort + 100;
  const assetPort = basePort + 1;
  const command = tool === 'rspack' ? ['bin/dev', '--no-open-browser'] : ['bin/dev'];
  const env = {
    ...process.env,
    FORCE_COLOR: '0',
    NO_COLOR: '1',
    PORT: String(basePort),
    REACT_ON_RAILS_BASE_PORT: String(basePort),
    SHAKAPACKER_DEV_SERVER_HOST: '127.0.0.1',
    VITE_RUBY_HOST: '127.0.0.1',
    VITE_RUBY_PORT: String(assetPort),
  };
  let logTail = '';
  const capture = (chunk) => {
    logTail = `${logTail}${chunk}`.slice(-maxLogCharacters);
  };
  const startedAt = performance.now();
  const child = spawn(command[0], command.slice(1), {
    cwd: workspace.directory,
    detached: process.platform !== 'win32',
    env,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  child.stdout.on('data', capture);
  child.stderr.on('data', capture);
  let page;
  let stopPromise;
  const stop = async () => {
    stopPromise ??= (async () => {
      try {
        await page?.close();
        await stopProcess(child);
        await waitForClosedPorts([webPort, assetPort]);
      } finally {
        await workspace.remove();
      }
    })();
    await stopPromise;
    if (activeSession?.stop === stop) activeSession = undefined;
  };
  activeSession = { stop };

  try {
    const url = `http://127.0.0.1:${webPort}${tool === 'rspack' ? '/hello_world' : '/'}`;
    await waitForHttp(url, child, () => logTail);
    const assetUrl =
      tool === 'rspack'
        ? `http://127.0.0.1:${assetPort}/packs/js/runtime.js`
        : `http://127.0.0.1:${assetPort}/vite-dev/@vite/client`;
    await waitForHttp(assetUrl, child, () => logTail);
    page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 });
    await page.locator('[data-benchmark-marker]').filter({ hasText: marker }).waitFor({ timeout: 30_000 });
    return { page, readyMs: round(performance.now() - startedAt), stop, workspace };
  } catch (error) {
    await stop();
    throw new Error(
      `${tool} failed to become browser-ready: ${error.message}\n${redactLocalPaths(logTail, rootAliases)}`,
    );
  }
}

async function clearSharedToolCache(tool) {
  const candidates =
    tool === 'rspack' ? ['starters/rspack/node_modules/.cache'] : ['starters/vite/node_modules/.vite'];
  await Promise.all(
    candidates.map((candidate) => rm(path.join(root, candidate), { recursive: true, force: true })),
  );
}

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

async function reservePortRange() {
  for (let attempt = 0; attempt < 50; attempt += 1) {
    const base = 38_000 + Math.floor(Math.random() * 10_000);
    if (await portsAvailable([base, base + 1, base + 100])) return base;
  }
  throw new Error('could not reserve an available benchmark port range');
}

async function portsAvailable(ports) {
  const servers = [];
  try {
    for (const port of ports) {
      const server = net.createServer();
      await new Promise((resolve, reject) => server.once('error', reject).listen(port, '127.0.0.1', resolve));
      servers.push(server);
    }
    return true;
  } catch {
    return false;
  } finally {
    await Promise.all(servers.map((server) => new Promise((resolve) => server.close(resolve))));
  }
}

async function waitForHttp(url, child, readLog) {
  const deadline = Date.now() + 60_000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null)
      throw new Error(`process exited ${child.exitCode}: ${readLog().slice(-2_000)}`);
    try {
      const response = await fetch(url, { signal: AbortSignal.timeout(1_000) });
      if (response.ok) return;
    } catch {
      // Connection refusal is expected until Rails is ready.
    }
    await delay(50);
  }
  throw new Error(`timed out waiting for ${url}`);
}

async function stopProcess(child) {
  if (child.exitCode !== null) return;
  const exited = new Promise((resolve) => child.once('exit', resolve));
  try {
    process.kill(process.platform === 'win32' ? child.pid : -child.pid, 'SIGTERM');
  } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
  if (await Promise.race([exited.then(() => true), delay(10_000).then(() => false)])) return;
  try {
    process.kill(process.platform === 'win32' ? child.pid : -child.pid, 'SIGKILL');
  } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
  await exited;
}

async function waitForClosedPorts(ports) {
  const deadline = Date.now() + 10_000;
  while (Date.now() < deadline) {
    if (await portsAvailable(ports)) return;
    await delay(100);
  }
  throw new Error(`benchmark ports did not close: ${ports.join(', ')}`);
}

function captureEnvironment() {
  const gitHead = commandOutput('git', ['rev-parse', 'HEAD'], repositoryRoot);
  return {
    harness_git_head: gitHead,
    harness_git_clean:
      commandOutput('git', ['status', '--porcelain', '--untracked-files=all'], repositoryRoot) === '',
    operating_system: `${os.type()} ${os.release()} ${os.arch()}`,
    cpu: os.cpus()[0]?.model ?? 'unknown',
    logical_cpu_count: os.cpus().length,
    total_memory_bytes: os.totalmem(),
    node: process.version,
    pnpm: commandOutput('pnpm', ['--version'], root),
    ruby: commandOutput('ruby', ['--version'], root),
    rails: {
      rspack: commandOutput('bundle', ['exec', 'rails', '--version'], path.join(root, 'starters/rspack')),
      vite: commandOutput('bundle', ['exec', 'rails', '--version'], path.join(root, 'starters/vite')),
    },
    dependencies: {
      rspack_ruby: gemVersions(['react_on_rails', 'shakapacker'], path.join(root, 'starters/rspack')),
      rspack_javascript: commandOutput(
        'pnpm',
        ['exec', 'rspack', '--version'],
        path.join(root, 'starters/rspack'),
      ),
      vite_ruby: gemVersions(['inertia_rails', 'vite_rails'], path.join(root, 'starters/vite')),
      vite_javascript: commandOutput('pnpm', ['exec', 'vite', '--version'], path.join(root, 'starters/vite')),
    },
    commands: {
      rspack: 'REACT_ON_RAILS_BASE_PORT=<PORT> bin/dev --no-open-browser',
      vite: 'PORT=<PORT> VITE_RUBY_PORT=<PORT+1> bin/dev',
    },
  };
}

function gemVersions(names, cwd) {
  const expression = `puts ${JSON.stringify(names)}.map { |name| "#{name} #{Gem.loaded_specs.fetch(name).version}" }.join("; ")`;
  return commandOutput('bundle', ['exec', 'ruby', '-e', expression], cwd);
}

function commandOutput(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8' });
  if (result.status !== 0) throw new Error(`${command} ${args.join(' ')} failed: ${result.stderr}`);
  return result.stdout.trim();
}

function readArgument(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? undefined : process.argv[index + 1];
}

function round(value) {
  return Math.round(value * 10) / 10;
}
