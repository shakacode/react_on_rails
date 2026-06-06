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

import { createHash } from 'crypto';

/**
 * Deterministic JSON serialization that sorts object keys to ensure
 * consistent cache keys across different workers and hosts.
 * JSON.stringify does not guarantee key order, which can cause
 * duplicate cache entries for semantically identical arguments.
 */
function stableStringify(value: unknown): string {
  if (value === undefined) return 'undefined';
  if (value === null) return 'null';
  if (typeof value !== 'object') return JSON.stringify(value);
  if (value instanceof Date) return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`;

  const sorted = Object.keys(value as Record<string, unknown>)
    .sort()
    .map((k) => `${JSON.stringify(k)}:${stableStringify((value as Record<string, unknown>)[k])}`);
  return `{${sorted.join(',')}}`;
}

// eslint-disable-next-line import/prefer-default-export -- will grow with additional key utilities
export function buildCacheKey(buildId: string, id: string, args: unknown[]): string {
  const hash = createHash('sha256');
  hash.update(buildId);
  hash.update(':');
  hash.update(id);
  hash.update(':');
  hash.update(stableStringify(args));
  return `rorp:rsc-cache:${hash.digest('hex')}`;
}
