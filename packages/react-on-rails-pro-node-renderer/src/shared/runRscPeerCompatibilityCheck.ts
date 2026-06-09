/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import { createRequire } from 'node:module';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import log from './log.js';
import { checkRscPeerCompatibility } from './checkRscPeerCompatibility.js';

const DISABLE_ENV = 'REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK';
const PACKAGE_JSON = 'package.json';

interface PackageJsonManifest {
  name?: unknown;
  version?: unknown;
}

const readPackageJsonManifest = (packageJsonPath: string): PackageJsonManifest | null => {
  try {
    return JSON.parse(readFileSync(packageJsonPath, 'utf8')) as PackageJsonManifest;
  } catch {
    return null;
  }
};

const findPackageVersionFromEntrypoint = (packageName: string, entrypointPath: string): string | null => {
  let currentDir = path.dirname(entrypointPath);

  while (true) {
    const packageJsonPath = path.join(currentDir, PACKAGE_JSON);
    if (existsSync(packageJsonPath)) {
      const manifest = readPackageJsonManifest(packageJsonPath);
      if (manifest?.name === packageName && typeof manifest.version === 'string') return manifest.version;
    }

    const parentDir = path.dirname(currentDir);
    // `path.dirname(root) === root`, so this sentinel stops the upward walk at the filesystem root.
    if (parentDir === currentDir) return null;
    currentDir = parentDir;
  }
};

// `react-on-rails-rsc` and `react` are the consuming app's dependencies, not the node
// renderer's, so resolve them from the app root rather than this module's location.
const defaultResolveVersion = (packageName: string, cwd: string): string | null => {
  try {
    const appRequire = createRequire(path.join(cwd, 'noop.js'));

    try {
      return (appRequire(`${packageName}/${PACKAGE_JSON}`) as { version?: string }).version ?? null;
    } catch {
      // Some packages do not export ./package.json; fall back to the package root
      // found from the public entrypoint so the check does not silently no-op.
      try {
        const entrypointPath = appRequire.resolve(packageName);
        return findPackageVersionFromEntrypoint(packageName, entrypointPath);
      } catch {
        return null;
      }
    }
  } catch (error) {
    log.warn(
      `[ReactOnRails] Could not resolve ${packageName} version ` +
        `(createRequire failed: ${error instanceof Error ? error.message : String(error)}). Version check skipped.`,
    );
    return null;
  }
};

let alreadyRan = false;

export interface RunRscPeerCompatibilityCheckOptions {
  cwd?: string;
  proVersion?: string;
  env?: NodeJS.ProcessEnv;
  // Injectable for tests; defaults to resolving from the app root.
  resolveVersion?: (packageName: string) => string | null;
}

export function runRscPeerCompatibilityCheck(options: RunRscPeerCompatibilityCheckOptions = {}): void {
  if (alreadyRan) return;
  // Set before evaluating so a caught startup error does not rerun the same process-wide check.
  alreadyRan = true;

  const env = options.env ?? process.env;
  const cwd = options.cwd ?? process.cwd();
  const resolveVersion =
    options.resolveVersion ?? ((specifier: string) => defaultResolveVersion(specifier, cwd));

  const rscVersion = resolveVersion('react-on-rails-rsc');
  const reactVersion = resolveVersion('react');

  const result = checkRscPeerCompatibility({ rscVersion, reactVersion, proVersion: options.proVersion });
  if (result.level === 'ok') return;

  if (result.level === 'warn') {
    // DISABLE_ENV only downgrades hard errors; warnings still fire so operators see the degraded-version signal.
    log.warn(result.message);
    return;
  }

  if (env[DISABLE_ENV] === '1') {
    log.warn(`${result.message}\n(Version check downgraded to a warning via ${DISABLE_ENV}.)`);
    return;
  }

  throw new Error(result.message);
}
