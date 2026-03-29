#!/usr/bin/env node

import net from 'node:net';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import process from 'node:process';

const RENDERER_PACKAGE = 'react-on-rails-pro-node-renderer';
const RENDERER_ENTRY = path.join(
  process.cwd(),
  'packages',
  'react-on-rails-pro-node-renderer',
  'lib',
  'default-node-renderer.js',
);

const args = new Set(process.argv.slice(2));
const skipBuild = args.has('--skip-build');
const timeoutMs = Number(process.env.REPRO_TIMEOUT_MS || '8000');

if (Number.isNaN(timeoutMs) || timeoutMs <= 0) {
  console.error(`Invalid REPRO_TIMEOUT_MS value: ${process.env.REPRO_TIMEOUT_MS}`);
  process.exit(1);
}

if (!skipBuild) {
  console.log(`Building ${RENDERER_PACKAGE}...`);
  const buildResult = spawnSync('pnpm', ['--filter', RENDERER_PACKAGE, 'build'], {
    stdio: 'inherit',
    env: process.env,
  });

  if (buildResult.status !== 0) {
    process.exit(buildResult.status ?? 1);
  }
}

const blocker = net.createServer();

const closeBlocker = async () => {
  await new Promise((resolve) => {
    blocker.close(() => resolve(undefined));
  });
};

blocker.listen(0, '127.0.0.1', () => {
  const address = blocker.address();
  if (!address || typeof address === 'string') {
    console.error('Failed to allocate a blocker port for reproduction');
    process.exit(1);
  }

  const blockedPort = address.port;
  const startTime = Date.now();
  let timedOut = false;

  const renderer = spawn('node', [RENDERER_ENTRY], {
    env: {
      ...process.env,
      NODE_ENV: 'test',
      RENDERER_HOST: '127.0.0.1',
      RENDERER_PORT: String(blockedPort),
      RENDERER_WORKERS_COUNT: '2',
      RENDERER_LOG_LEVEL: 'info',
      RENDERER_LOG_HTTP_LEVEL: 'error',
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  let output = '';
  renderer.stdout.on('data', (chunk) => {
    output += chunk.toString();
  });
  renderer.stderr.on('data', (chunk) => {
    output += chunk.toString();
  });

  const timeout = setTimeout(() => {
    timedOut = true;
    renderer.kill('SIGKILL');
  }, timeoutMs);

  renderer.on('error', async (err) => {
    clearTimeout(timeout);
    await closeBlocker();
    console.error('Failed to spawn node renderer:', err);
    process.exit(1);
  });

  renderer.on('exit', async (code, signal) => {
    clearTimeout(timeout);
    await closeBlocker();

    const durationMs = Date.now() - startTime;
    const restartMessages = (output.match(/died UNEXPECTEDLY :\(, restarting/g) || []).length;
    const startupFailureMessage = new RegExp(
      `Node renderer startup failed: port ${blockedPort} is already in use`,
    ).test(output);

    const checks = {
      exitedWithoutTimeout: !timedOut,
      exitCodeIsOne: code === 1,
      noSignal: signal === null,
      startupFailureMessage,
      noUnexpectedRestartLoop: restartMessages === 0,
    };

    const passed = Object.values(checks).every(Boolean);

    if (passed) {
      console.log('PASS: startup failure path aborts cleanly with no refork loop.');
      console.log(
        JSON.stringify(
          {
            blockedPort,
            durationMs,
            code,
            signal,
            restartMessages,
          },
          null,
          2,
        ),
      );
      process.exit(0);
    }

    console.error('FAIL: startup failure reproduction did not match expected fixed behavior.');
    console.error(
      JSON.stringify(
        {
          blockedPort,
          durationMs,
          code,
          signal,
          timedOut,
          restartMessages,
          checks,
        },
        null,
        2,
      ),
    );
    console.error('--- renderer output (first 200 lines) ---');
    console.error(output.split('\n').slice(0, 200).join('\n'));
    process.exit(1);
  });
});
