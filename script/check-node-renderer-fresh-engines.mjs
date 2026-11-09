#!/usr/bin/env node

// Resolves react-on-rails-pro-node-renderer's runtime dependencies the way a
// fresh `npm install` does today (no lockfile), then fails when any resolved
// package declares an `engines.node` range that excludes the lowest Node
// version the renderer advertises in its own `engines.node`.
//
// This repository's pnpm lockfile pins old transitive versions, so normal CI
// never sees what new installs resolve. Issue #5305 is the case that motivated
// this check: light-my-request 6.8.0 moved to cookie 2.x, which needs Node 22.
//
// Known mismatches live in KNOWN_MISMATCHES with the issue that tracks them. The
// check stays green for those and fails on any new or changed one, so the next
// drift is visible. Remove an entry once the engines floor or the dependency
// changes.
//
// npm prefers versions whose engines accept the Node that runs it, so run this
// on the newest Node release. npm then picks the highest version in range, as
// pnpm and Yarn do, for every package whose newest release accepts that Node.
// A newest release with a closed range that leaves it out (say `^20 || ^22`
// on Node 24) is still skipped for an older one, and this check misses it.
//
// Usage:
//   node script/check-node-renderer-fresh-engines.mjs            # resolve from the npm registry
//   node script/check-node-renderer-fresh-engines.mjs --lockfile PATH   # check an existing npm lockfile

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const RENDERER_PACKAGE_JSON = fileURLToPath(
  new URL('../packages/react-on-rails-pro-node-renderer/package.json', import.meta.url),
);

// Each entry matches one package name and its exact `engines.node` string.
// A new version that keeps the same range stays allowed; a stricter range fails.
// cookie 2.x arrives through light-my-request 6.8+, which Fastify loads only for inject().
export const KNOWN_MISMATCHES = [
  { name: 'cookie', engines: '>=22', issue: 'https://github.com/shakacode/react_on_rails/issues/5305' },
];

function packageNameFromLockPath(lockPath) {
  const marker = 'node_modules/';
  return lockPath.slice(lockPath.lastIndexOf(marker) + marker.length);
}

// Returns { floor, mismatches, allowed, staleAllowlist } for an npm v2/v3 lockfile object.
export function findEngineMismatches({ lock, enginesRange, semver, knownMismatches = KNOWN_MISMATCHES }) {
  const floor = semver.minVersion(enginesRange);
  if (!floor) throw new Error(`Cannot find a minimum Node version in engines.node "${enginesRange}"`);
  if (!lock.packages)
    throw new Error('Lockfile has no "packages" map; npm lockfileVersion 2 or later is required');

  const mismatches = [];
  const allowed = [];
  const seenAllowlist = new Set();

  // Same test as npm's engine check: an unparseable range rejects every version.
  // Dev-only entries, present when --lockfile names a project's own lockfile, are not installed
  // for production. A devOptional entry is also an optional dependency of a production package,
  // so it stays.
  const excluding = Object.entries(lock.packages).filter(([lockPath, entry]) => {
    const required = entry.engines?.node;
    const devOnly = entry.dev === true;
    return (
      lockPath !== '' &&
      !devOnly &&
      required &&
      !semver.satisfies(floor, required, { includePrerelease: true })
    );
  });

  for (const [lockPath, entry] of excluding) {
    const required = entry.engines.node;
    const name = entry.name ?? packageNameFromLockPath(lockPath);
    const found = { name, version: entry.version, engines: required, path: lockPath };
    const known = knownMismatches.find((item) => item.name === name && item.engines === required);
    if (known) {
      allowed.push({ ...found, issue: known.issue });
      seenAllowlist.add(known);
    } else {
      mismatches.push(found);
    }
  }

  const staleAllowlist = knownMismatches.filter((item) => !seenAllowlist.has(item));
  return { floor: floor.version, mismatches, allowed, staleAllowlist };
}

export function loadSemver() {
  try {
    return createRequire(import.meta.url)('semver');
  } catch {
    // Without a workspace install, use the copy npm bundles; npm is required here anyway.
    const npmGlobalRoot = execFileSync('npm', ['root', '-g'], { encoding: 'utf8' }).trim();
    return createRequire(path.join(npmGlobalRoot, 'npm', 'package.json'))('semver');
  }
}

function resolveFreshLockfile(dependencies) {
  const workspaceSpecs = Object.entries(dependencies).filter(([, spec]) =>
    /^(workspace|link|file):/.test(spec),
  );
  if (workspaceSpecs.length > 0) {
    throw new Error(
      `Cannot resolve local dependency specs from the registry: ${JSON.stringify(workspaceSpecs)}`,
    );
  }

  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'node-renderer-fresh-engines-'));
  try {
    fs.writeFileSync(
      path.join(dir, 'package.json'),
      `${JSON.stringify({ name: 'node-renderer-fresh-engines-probe', private: true, dependencies }, null, 2)}\n`,
    );
    execFileSync(
      'npm',
      [
        'install',
        '--package-lock-only',
        '--ignore-scripts',
        '--no-audit',
        '--no-fund',
        '--engine-strict=false',
      ],
      { cwd: dir, stdio: ['ignore', 'inherit', 'inherit'] },
    );
    return JSON.parse(fs.readFileSync(path.join(dir, 'package-lock.json'), 'utf8'));
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function main(argv) {
  const lockfileIndex = argv.indexOf('--lockfile');
  if (lockfileIndex !== -1 && !argv[lockfileIndex + 1]) throw new Error('--lockfile needs a path');
  const rendererPackage = JSON.parse(fs.readFileSync(RENDERER_PACKAGE_JSON, 'utf8'));
  const enginesRange = rendererPackage.engines?.node;
  if (!enginesRange) throw new Error(`${RENDERER_PACKAGE_JSON} has no engines.node`);

  const lock =
    lockfileIndex === -1
      ? resolveFreshLockfile(rendererPackage.dependencies ?? {})
      : JSON.parse(fs.readFileSync(argv[lockfileIndex + 1], 'utf8'));

  const result = findEngineMismatches({ lock, enginesRange, semver: loadSemver() });

  console.log(`react-on-rails-pro-node-renderer engines.node: ${enginesRange} (lowest: ${result.floor})`);
  for (const item of result.allowed) {
    console.log(`  known: ${item.name}@${item.version} needs node ${item.engines} (${item.issue})`);
  }
  for (const item of result.staleAllowlist) {
    console.log(
      `  not seen with this range: ${item.name} node ${item.engines}; remove the entry, or update its range if the package now needs a different one`,
    );
  }
  if (result.mismatches.length === 0) {
    console.log('No new engines.node mismatches in the fresh resolution.');
    return 0;
  }

  for (const item of result.mismatches) {
    console.error(
      `::error::${item.name}@${item.version} (${item.path}) needs node ${item.engines}, ` +
        `which excludes the renderer's advertised Node ${result.floor}.`,
    );
  }
  console.error(
    'A fresh install of the renderer now resolves a package that rejects its lowest advertised Node version. ' +
      'Raise engines.node, constrain the dependency, or add a tracked entry to KNOWN_MISMATCHES.',
  );
  return 1;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    process.exitCode = main(process.argv.slice(2));
  } catch (error) {
    console.error(`::error::${error.message}`);
    process.exitCode = 2;
  }
}
