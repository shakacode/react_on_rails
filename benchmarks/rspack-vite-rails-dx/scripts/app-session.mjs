import { spawn, spawnSync } from 'node:child_process';
import { readFile, realpath, rm } from 'node:fs/promises';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { setTimeout as delay } from 'node:timers/promises';
import { redactLocalPaths } from './local-paths.mjs';
import { createWorkspace } from './starter-workspace.mjs';

const maxLogCharacters = 8_000;

export async function startApp({ browser, label, root, tool, extraEnv = {} }) {
  const repositoryRoot = path.resolve(root, '../..');
  const rootAliases = [
    ...new Set([root, await realpath(root), repositoryRoot, await realpath(repositoryRoot)]),
  ];
  const nonce = `${label}-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const workspace = await createWorkspace(root, tool, nonce);
  const marker = `ready-${tool}-${nonce}`;
  await workspace.setMarker(marker);
  await clearSharedToolCache(root, tool);
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
    ...extraEnv,
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
        await stopResidualProcesses(nonce);
        await waitForClosedPorts([webPort, assetPort]);
      } finally {
        await workspace.remove();
      }
    })();
    await stopPromise;
  };

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
    return {
      assetPort,
      basePort,
      log: () => redactLocalPaths(logTail, rootAliases),
      marker,
      page,
      readyMs: round(performance.now() - startedAt),
      stop,
      webPort,
      workspace,
    };
  } catch (error) {
    await stop();
    throw new Error(
      `${tool} failed to become browser-ready: ${error.message}\n${redactLocalPaths(logTail, rootAliases)}`,
    );
  }
}

export function residualProcessGroups(processList, nonce, ownPid = process.pid) {
  const groups = new Set();
  for (const line of processList.split('\n')) {
    const match = line.match(/^\s*(\d+)\s+(\d+)\s+(.+)$/);
    if (!match) continue;
    const [, pidText, groupText, command] = match;
    const pid = Number(pidText);
    const group = Number(groupText);
    if (pid !== ownPid && group > 1 && command.includes(nonce)) groups.add(group);
  }
  return [...groups];
}

export function captureEnvironment(root) {
  const repositoryRoot = path.resolve(root, '../..');
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

async function clearSharedToolCache(root, tool) {
  const candidates =
    tool === 'rspack' ? ['starters/rspack/node_modules/.cache'] : ['starters/vite/node_modules/.vite'];
  await Promise.all(
    candidates.map((candidate) => rm(path.join(root, candidate), { recursive: true, force: true })),
  );
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
    if (child.exitCode !== null || child.signalCode !== null) {
      const result = child.exitCode === null ? `after ${child.signalCode}` : child.exitCode;
      throw new Error(`process exited ${result}: ${readLog().slice(-2_000)}`);
    }
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
  const alreadyExited = child.exitCode !== null || child.signalCode !== null;
  if (process.platform === 'win32' && alreadyExited) return;

  const exited = alreadyExited ? Promise.resolve() : new Promise((resolve) => child.once('exit', resolve));
  const target = process.platform === 'win32' ? child.pid : -child.pid;
  signalProcess(target, 'SIGTERM');

  if (process.platform !== 'win32') {
    if (!(await waitForProcessGroupExit(child.pid, 10_000))) {
      signalProcess(target, 'SIGKILL');
      if (!(await waitForProcessGroupExit(child.pid, 10_000)))
        throw new Error(`process group ${child.pid} did not exit`);
    }
    await exited;
    return;
  }

  if (await Promise.race([exited.then(() => true), delay(10_000).then(() => false)])) return;
  signalProcess(target, 'SIGKILL');
  await exited;
}

async function stopResidualProcesses(nonce) {
  if (process.platform === 'win32') return;
  let groups = currentResidualProcessGroups(nonce);
  for (const group of groups) signalProcess(-group, 'SIGTERM');
  const deadline = Date.now() + 5_000;
  while (groups.length > 0 && Date.now() < deadline) {
    await delay(50);
    groups = currentResidualProcessGroups(nonce);
  }
  for (const group of groups) signalProcess(-group, 'SIGKILL');
  if (groups.length > 0) {
    await delay(50);
    const survivors = currentResidualProcessGroups(nonce);
    if (survivors.length > 0)
      throw new Error(`benchmark session processes did not exit: ${survivors.join(', ')}`);
  }
}

function currentResidualProcessGroups(nonce) {
  const result = spawnSync('ps', ['-axo', 'pid=,pgid=,command='], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error(`could not inspect benchmark session processes: ${result.stderr}`);
  return residualProcessGroups(result.stdout, nonce);
}

function signalProcess(target, signal) {
  try {
    process.kill(target, signal);
  } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
}

async function waitForProcessGroupExit(pid, timeout) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    try {
      process.kill(-pid, 0);
    } catch (error) {
      if (error.code === 'ESRCH') return true;
      throw error;
    }
    await delay(50);
  }
  return false;
}

async function waitForClosedPorts(ports) {
  const deadline = Date.now() + 10_000;
  while (Date.now() < deadline) {
    if (await portsAvailable(ports)) return;
    await delay(100);
  }
  throw new Error(`benchmark ports did not close: ${ports.join(', ')}`);
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

function round(value) {
  return Math.round(value * 10) / 10;
}
