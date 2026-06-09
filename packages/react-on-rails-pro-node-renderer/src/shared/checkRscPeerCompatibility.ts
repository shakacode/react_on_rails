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

import { RSC_PEER_SUPPORT } from './rscPeerSupport.js';

export type RscPeerCheckLevel = 'ok' | 'warn' | 'error';

export type RscPeerCheckResult =
  | { level: 'ok'; message?: undefined }
  | { level: Exclude<RscPeerCheckLevel, 'ok'>; message: string };

export interface RscPeerCheckInput {
  rscVersion: string | null;
  reactVersion: string | null;
  reactDomVersion?: string | null;
  // Optional, only used to enrich the message (e.g. the node-renderer version).
  proVersion?: string;
}

type VersionTuple = [number, number, number];

// Strip build metadata (`+...`) and prerelease (`-...`) so a coordinated RC such as
// `19.0.5-rc.6` compares as `19.0.5`. We only need major/minor/patch ordering, so this
// avoids semver's prerelease rules (and a `semver` dependency) entirely.
const parseTuple = (version: string): VersionTuple => {
  // `resolveVersion` is a public injection point, so tolerate a leading `v`/`=` (e.g. `v19.0.4`).
  // Malformed versions intentionally coerce to 0 segments so the major mismatch
  // branch reports the original string instead of hiding it behind a parse error.
  const normalized = version.replace(/^[v=]+/, '');
  const [withoutBuild = ''] = normalized.split('+', 1);
  const [core = ''] = withoutBuild.split('-', 1);
  const parts = core.split('.');
  return [Number(parts[0]) || 0, Number(parts[1]) || 0, Number(parts[2]) || 0];
};

const isAtLeast = (actual: VersionTuple, floor: VersionTuple): boolean => {
  for (let i = 0; i < 3; i += 1) {
    const a = actual[i] ?? 0;
    const f = floor[i] ?? 0;
    if (a > f) return true;
    if (a < f) return false;
  }
  return true;
};

const sameTuple = (left: VersionTuple, right: VersionTuple): boolean =>
  left.every((value, index) => value === right[index]);

const proLabel = (proVersion?: string) =>
  proVersion ? `React on Rails Pro (${proVersion})` : 'React on Rails Pro';

const errorMessage = (pkg: string, found: string, want: string, proVersion?: string) =>
  [
    `[ReactOnRails] Incompatible ${pkg} version.`,
    `  ${proLabel(proVersion)} requires ${pkg} ${want} (found ${found}).`,
    `  Upgrade or downgrade ${pkg} to a compatible release. See https://www.shakacode.com/react-on-rails-pro/docs/.`,
    `  (Set REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK=1 to downgrade this error to a warning.)`,
  ].join('\n');

const warnMessage = (found: string, recommendedMin: string, proVersion?: string) =>
  [
    `[ReactOnRails] react-on-rails-rsc ${found} is older than the recommended minimum ${recommendedMin}.`,
    `  ${proLabel(proVersion)} may behave incorrectly (missing coordinated RSC fixes).`,
    `  Upgrade react-on-rails-rsc to ${recommendedMin} or newer.`,
  ].join('\n');

export function checkRscPeerCompatibility(input: RscPeerCheckInput): RscPeerCheckResult {
  const { rscVersion, reactVersion, reactDomVersion, proVersion } = input;

  // react-on-rails-rsc is an optional peer. Absent => the consumer is not on the RSC
  // path (or not using RSC at all) => nothing to validate.
  if (!rscVersion) return { level: 'ok' };

  const { reactOnRailsRsc, react } = RSC_PEER_SUPPORT;
  const rscTuple = parseTuple(rscVersion);
  const [rscMajor] = rscTuple;

  if (rscMajor !== reactOnRailsRsc.supportedMajor) {
    return {
      level: 'error',
      message: errorMessage(
        'react-on-rails-rsc',
        rscVersion,
        `${reactOnRailsRsc.supportedMajor}.x`,
        proVersion,
      ),
    };
  }

  // If React is not resolvable (unusual, since RSC requires React), skip this check;
  // an app with React truly absent will fail during normal module loading.
  let reactTuple: VersionTuple | null = null;
  if (reactVersion) {
    reactTuple = parseTuple(reactVersion);
    const [reactMajor] = reactTuple;
    if (reactMajor < react.minMajor) {
      return {
        level: 'error',
        message: errorMessage('react', reactVersion, `>= ${react.minMajor}`, proVersion),
      };
    }
  }

  if (reactDomVersion) {
    const reactDomTuple = parseTuple(reactDomVersion);
    const [reactDomMajor] = reactDomTuple;
    if (reactDomMajor < react.minMajor) {
      return {
        level: 'error',
        message: errorMessage('react-dom', reactDomVersion, `>= ${react.minMajor}`, proVersion),
      };
    }

    if (reactTuple && !sameTuple(reactTuple, reactDomTuple)) {
      return {
        level: 'error',
        message: errorMessage('react-dom', reactDomVersion, `match react ${reactVersion}`, proVersion),
      };
    }
  }

  if (!isAtLeast(rscTuple, parseTuple(reactOnRailsRsc.recommendedMin))) {
    return { level: 'warn', message: warnMessage(rscVersion, reactOnRailsRsc.recommendedMin, proVersion) };
  }

  return { level: 'ok' };
}
