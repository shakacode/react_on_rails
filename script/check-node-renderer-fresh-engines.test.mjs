// Run with `node --test script/check-node-renderer-fresh-engines.test.mjs`.

import { test } from 'node:test';
import assert from 'node:assert/strict';
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
