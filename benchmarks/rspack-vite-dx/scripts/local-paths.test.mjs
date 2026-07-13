import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { assertNoLocalPaths, redactLocalPaths } from './local-paths.mjs';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const benchmarkRoot = path.resolve(scriptDirectory, '..');

test('redacts exact benchmark roots and common local user paths across platforms', () => {
  const value = [
    '/workspace/benchmark/controls/vite/src/message.js',
    '/private/var/folders/xy/real-benchmark/controls/rspack/src/message.js',
    '/Users/alice/project/error.js',
    '/home/bob/project/error.js',
    String.raw`C:\users\Carol\project\error.js`,
    'D:/a/repo/error.js',
  ].join('\n');

  assert.equal(
    redactLocalPaths(value, [
      '/workspace/benchmark',
      '/private/var/folders/xy/real-benchmark',
      String.raw`D:\a\repo`,
    ]),
    ['<LOCAL_PATH>', '<LOCAL_PATH>', '<LOCAL_PATH>', '<LOCAL_PATH>', '<LOCAL_PATH>', '<LOCAL_PATH>'].join(
      '\n',
    ),
  );
});

test('preserves remote web URLs and relative compiler paths', () => {
  const value = 'https://example.com/Users/alice/docs\nERROR in ./src/message.js';

  assert.equal(redactLocalPaths(value), value);
});

test('redacts local paths embedded in loopback dev-server URLs', () => {
  const value = 'http://127.0.0.1:5173/@fs//Users/alice/project/file.js';

  assert.equal(redactLocalPaths(value), 'http://127.0.0.1:5173/@fs/<LOCAL_PATH>');
  assert.throws(() => assertNoLocalPaths({ overlay_url: value }), /unredacted local path/);
});

test('redacts local paths embedded in unspecified-address dev-server URLs', () => {
  const cases = [
    ['http://0.0.0.0:5173/@fs//Users/alice/project/file.js', 'http://0.0.0.0:5173/@fs/<LOCAL_PATH>'],
    ['http://[::]:5173/@fs//home/bob/project/file.js', 'http://[::]:5173/@fs/<LOCAL_PATH>'],
  ];

  for (const [value, expected] of cases) {
    assert.equal(redactLocalPaths(value), expected);
    assert.throws(() => assertNoLocalPaths({ overlay_url: value }), /unredacted local path/);
  }
});

test('fails closed when a committed artifact still contains a local path', () => {
  assert.throws(
    () => assertNoLocalPaths({ overlay_text_excerpt: '/Users/alice/project/error.js' }),
    /unredacted local path/,
  );
  assert.throws(
    () => assertNoLocalPaths({ overlay_text_excerpt: String.raw`C:\Users\Carol\project\error.js` }),
    /unredacted local path/,
  );
  assert.doesNotThrow(() => assertNoLocalPaths({ overlay_text_excerpt: './src/message.js' }));
});

test('report replay rejects an artifact containing an unredacted local path', async () => {
  const temporaryDirectory = await mkdtemp(path.join(os.tmpdir(), 'rspack-vite-local-path-'));
  const raw = JSON.parse(await readFile(path.join(benchmarkRoot, 'results', 'recorded.json'), 'utf8'));
  raw.overlay.rspack.overlay_text_excerpt = '/Users/alice/project/error.js';
  const rawPath = path.join(temporaryDirectory, 'recorded.json');

  try {
    await writeFile(rawPath, JSON.stringify(raw));
    const result = spawnSync(
      process.execPath,
      [path.join(scriptDirectory, 'report.mjs'), '--raw', rawPath, '--check'],
      { encoding: 'utf8' },
    );

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /artifact contains an unredacted local path/);
  } finally {
    await rm(temporaryDirectory, { recursive: true, force: true });
  }
});
