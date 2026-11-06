// Run with `node --test script/check-node-renderer-fresh-engines.test.mjs`.

import { after, describe, it, test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { findEngineMismatches, loadSemver } from './check-node-renderer-fresh-engines.mjs';

const semver = loadSemver();

// Shaped like the fresh resolution observed on 2026-11-05 (issue #5305).
const lock = {
  lockfileVersion: 3,
  packages: {
    '': { name: 'probe' },
    'node_modules/fastify': { version: '5.12.8' },
    'node_modules/cookie': { version: '2.0.1', engines: { node: '>=22' } },
    'node_modules/find-my-way': { version: '9.10.0', engines: { node: '>=20' } },
    'node_modules/fs-extra': { version: '11.4.1', engines: { node: '>=14.14' } },
    'node_modules/@scope/nested/node_modules/semver': { version: '7.8.6', engines: { node: '>=10' } },
  },
};

const known = [
  { name: 'cookie', engines: '>=22', issue: 'ISSUE' },
  { name: 'find-my-way', engines: '>=20', issue: 'ISSUE' },
];

test('passes when every mismatch is a known, tracked one', () => {
  const result = findEngineMismatches({ lock, enginesRange: '>=18.19.0', semver, knownMismatches: known });
  assert.equal(result.floor, '18.19.0');
  assert.deepEqual(result.mismatches, []);
  assert.deepEqual(
    result.allowed.map((item) => item.name),
    ['cookie', 'find-my-way'],
  );
});

test('fails on a mismatch that is not tracked', () => {
  const result = findEngineMismatches({
    lock,
    enginesRange: '>=18.19.0',
    semver,
    knownMismatches: [known[1]],
  });
  assert.deepEqual(result.mismatches, [
    { name: 'cookie', version: '2.0.1', engines: '>=22', path: 'node_modules/cookie' },
  ]);
});

test('fails when a tracked package tightens its engines range', () => {
  const stricter = structuredClone(lock);
  stricter.packages['node_modules/find-my-way'].engines.node = '>=22';
  const result = findEngineMismatches({
    lock: stricter,
    enginesRange: '>=18.19.0',
    semver,
    knownMismatches: known,
  });
  assert.deepEqual(
    result.mismatches.map((item) => `${item.name} ${item.engines}`),
    ['find-my-way >=22'],
  );
});

test('raising the floor clears mismatches and reports stale allowlist entries', () => {
  const result = findEngineMismatches({ lock, enginesRange: '>=22', semver, knownMismatches: known });
  assert.equal(result.floor, '22.0.0');
  assert.deepEqual(result.mismatches, []);
  assert.deepEqual(
    result.staleAllowlist.map((item) => item.name),
    ['cookie', 'find-my-way'],
  );
});

test('derives package names from nested lockfile paths', () => {
  const result = findEngineMismatches({ lock, enginesRange: '>=8', semver, knownMismatches: [] });
  assert.ok(result.mismatches.some((item) => item.name === 'cookie'));
  const nested = findEngineMismatches({ lock, enginesRange: '>=9', semver, knownMismatches: [] });
  assert.ok(nested.mismatches.some((item) => item.name === 'semver' && item.path.includes('@scope/nested')));
});

test('counts an engines.node npm cannot parse as a mismatch, as npm does', () => {
  const odd = {
    packages: { '': {}, 'node_modules/odd': { version: '1.0.0', engines: { node: 'node >= 14' } } },
  };
  const result = findEngineMismatches({ lock: odd, enginesRange: '>=18.19.0', semver, knownMismatches: [] });
  assert.deepEqual(
    result.mismatches.map((item) => item.name),
    ['odd'],
  );
});

test('skips dev-only lockfile entries but keeps devOptional ones, which production installs keep', () => {
  const withDev = {
    packages: {
      'node_modules/dev-tool': { version: '1.0.0', dev: true, engines: { node: '>=24' } },
      'node_modules/dev-optional': { version: '1.0.0', devOptional: true, engines: { node: '>=24' } },
      'node_modules/runtime': { version: '1.0.0', engines: { node: '>=24' } },
    },
  };
  const result = findEngineMismatches({ lock: withDev, enginesRange: '>=20', semver, knownMismatches: [] });
  assert.deepEqual(
    result.mismatches.map((item) => item.name),
    ['dev-optional', 'runtime'],
  );
});

test('names top-level scoped packages by their full scope', () => {
  const scoped = { packages: { 'node_modules/@fastify/x': { version: '1.0.0', engines: { node: '>=22' } } } };
  const result = findEngineMismatches({ lock: scoped, enginesRange: '>=20', semver, knownMismatches: [] });
  assert.equal(result.mismatches[0].name, '@fastify/x');
});

describe('command line', () => {
  const checker = fileURLToPath(new URL('./check-node-renderer-fresh-engines.mjs', import.meta.url));
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'fresh-engines-test-'));
  after(() => fs.rmSync(dir, { recursive: true, force: true }));

  function run(cookieEngines) {
    const file = path.join(dir, `lock-${cookieEngines.replace(/\W/g, '')}.json`);
    const fixture = {
      packages: { '': {}, 'node_modules/cookie': { version: '9.0.0', engines: { node: cookieEngines } } },
    };
    fs.writeFileSync(file, JSON.stringify(fixture));
    return spawnSync(process.execPath, [checker, '--lockfile', file], { encoding: 'utf8' });
  }

  it('exits 0 for a tracked mismatch', () => {
    assert.equal(run('>=22').status, 0);
  });

  it('exits 1 and names the package for new drift', () => {
    const result = run('>=24');
    assert.equal(result.status, 1);
    assert.match(result.stderr, /cookie@9\.0\.0 .* needs node >=24/);
  });

  it('accepts the Node 20 packages a fresh install resolves at the advertised floor', () => {
    // find-my-way, thread-stream and toad-cache declare >=20. They pass only while the renderer's
    // engines.node floor is Node 20 or later, so lowering it back to 18.19 fails this test.
    const file = path.join(dir, 'lock-node20.json');
    const fixture = {
      packages: {
        '': {},
        'node_modules/find-my-way': { version: '9.10.0', engines: { node: '>=20' } },
        'node_modules/thread-stream': { version: '4.2.1', engines: { node: '>=20' } },
        'node_modules/toad-cache': { version: '3.7.4', engines: { node: '>=20' } },
      },
    };
    fs.writeFileSync(file, JSON.stringify(fixture));
    const result = spawnSync(process.execPath, [checker, '--lockfile', file], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  });

  it('exits 2 when --lockfile has no path', () => {
    const result = spawnSync(process.execPath, [checker, '--lockfile'], { encoding: 'utf8' });
    assert.equal(result.status, 2);
    assert.match(result.stderr, /--lockfile needs a path/);
  });
});
