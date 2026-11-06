#!/usr/bin/env node
// Check Pro package license headers in packed output
//
// script/check-pro-license-headers checks Pro source files. This script checks
// what npm users actually receive: it packs each Pro npm package and fails if any
// packed .js file lacks the license sentinel. The compiler can drop a source
// header (for example, when the header sits above an import TypeScript elides),
// so a passing source check does not prove the published files carry it (#5308).
//
// Usage:
//   node script/check-pro-package-license-headers.mjs   # packages must be built first
//
// This file is OSS tooling, so it carries no Pro header itself.

import { execFileSync } from 'node:child_process';
import { mkdtempSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Keep in sync with SENTINEL in script/check-pro-license-headers.
export const SENTINEL = 'NOT licensed under the MIT';

export const PRO_PACKAGES = ['packages/react-on-rails-pro', 'packages/react-on-rails-pro-node-renderer'];

// Returns the packed .js paths whose content lacks the sentinel.
// `files` is an array of { path, content }.
export const findMissingHeaders = (files) =>
  files
    .filter(({ path }) => path.endsWith('.js'))
    .filter(({ content }) => !content.includes(SENTINEL))
    .map(({ path }) => path);

const packPackage = (packageDir, destination) => {
  execFileSync('pnpm', ['pack', '--pack-destination', destination], { cwd: packageDir, stdio: 'ignore' });
  const tarballs = readdirSync(destination).filter((file) => file.endsWith('.tgz'));
  if (tarballs.length !== 1) {
    throw new Error(`Expected one tarball from ${packageDir}, found ${tarballs.length}`);
  }
  return join(destination, tarballs[0]);
};

const readPackedJsFiles = (tarballPath) =>
  execFileSync('tar', ['-tzf', tarballPath], { encoding: 'utf8' })
    .split('\n')
    .filter((path) => path.endsWith('.js'))
    .map((path) => ({
      path,
      content: execFileSync('tar', ['-xOzf', tarballPath, path], {
        encoding: 'utf8',
        maxBuffer: 64 * 1024 * 1024,
      }),
    }));

const checkPackage = (repoRoot, packageDir) => {
  const destination = mkdtempSync(join(tmpdir(), 'pro-license-headers-'));
  try {
    const files = readPackedJsFiles(packPackage(join(repoRoot, packageDir), destination));
    if (files.length === 0) {
      return { packageDir, checked: 0, missing: [], error: 'packed no .js files; build the package first' };
    }
    return { packageDir, checked: files.length, missing: findMissingHeaders(files) };
  } finally {
    rmSync(destination, { recursive: true, force: true });
  }
};

const main = () => {
  const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  let failed = false;
  PRO_PACKAGES.forEach((packageDir) => {
    const { checked, missing, error } = checkPackage(repoRoot, packageDir);
    if (error) {
      failed = true;
      console.error(`${packageDir}: ${error}`);
    } else if (missing.length > 0) {
      failed = true;
      console.error(`${packageDir}: ${missing.length} of ${checked} packed .js file(s) lack "${SENTINEL}":`);
      missing.forEach((path) => console.error(`  ${path}`));
    } else {
      console.log(`${packageDir}: all ${checked} packed .js files carry the Pro license header.`);
    }
  });
  if (failed) {
    console.error('\nPut each source header above a statement that survives compilation (see #5308).');
    process.exit(1);
  }
};

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main();
}
