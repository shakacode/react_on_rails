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
import path from 'node:path';
import log from './log.js';
import { checkRscPeerCompatibility } from './checkRscPeerCompatibility.js';

const DISABLE_ENV = 'REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK';

// `react-on-rails-rsc` and `react` are the consuming app's dependencies, not the node
// renderer's, so resolve them from the app root rather than this module's location.
const defaultResolveVersion = (specifier: string, cwd: string): string | null => {
  try {
    const appRequire = createRequire(path.join(cwd, 'noop.js'));
    return (appRequire(specifier) as { version?: string }).version ?? null;
  } catch {
    return null;
  }
};

let alreadyRan = false;

export interface RunRscPeerCompatibilityCheckOptions {
  cwd?: string;
  proVersion?: string;
  env?: NodeJS.ProcessEnv;
  // Injectable for tests; defaults to resolving from the app root.
  resolveVersion?: (specifier: string) => string | null;
}

export function runRscPeerCompatibilityCheck(options: RunRscPeerCompatibilityCheckOptions = {}): void {
  if (alreadyRan) return;
  alreadyRan = true;

  const env = options.env ?? process.env;
  const cwd = options.cwd ?? process.cwd();
  const resolveVersion =
    options.resolveVersion ?? ((specifier: string) => defaultResolveVersion(specifier, cwd));

  const rscVersion = resolveVersion('react-on-rails-rsc/package.json');
  const reactVersion = resolveVersion('react/package.json');

  const result = checkRscPeerCompatibility({ rscVersion, reactVersion, proVersion: options.proVersion });
  if (result.level === 'ok') return;

  if (env[DISABLE_ENV]) {
    log.warn(`${result.message}\n(Version check downgraded to a warning via ${DISABLE_ENV}.)`);
    return;
  }

  if (result.level === 'warn') {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion -- non-ok results always carry a message
    log.warn(result.message!);
    return;
  }

  throw new Error(result.message);
}

// Test-only: reset the once-per-process memoization.
// eslint-disable-next-line no-underscore-dangle
export function __resetRscPeerCompatibilityCheckForTests(): void {
  alreadyRan = false;
}
