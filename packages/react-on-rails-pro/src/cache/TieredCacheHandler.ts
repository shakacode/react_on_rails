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

import type { CacheEntry, CacheHandler } from './CacheHandler.ts';

export interface TieredCacheHandlerOptions {
  /**
   * Maximum TTL (in seconds) for entries promoted to L1.
   * Bounds how long a stale L1 entry can persist after L2 is updated by another worker.
   * Defaults to undefined (use the entry's original revalidate value).
   */
  l1MaxTtlSeconds?: number;
}

// eslint-disable-next-line import/prefer-default-export -- designed for named import alongside the interface
export class TieredCacheHandler implements CacheHandler {
  private l1: CacheHandler;

  private l2: CacheHandler;

  private l1MaxTtlSeconds: number | undefined;

  constructor(l1: CacheHandler, l2: CacheHandler, opts: TieredCacheHandlerOptions = {}) {
    this.l1 = l1;
    this.l2 = l2;
    this.l1MaxTtlSeconds = opts.l1MaxTtlSeconds;
  }

  async get(key: string): Promise<CacheEntry | null> {
    const l1Entry = await this.l1.get(key);
    if (l1Entry) return l1Entry;

    let l2Entry: CacheEntry | null;
    try {
      l2Entry = await this.l2.get(key);
    } catch (err) {
      console.error('TieredCacheHandler: L2 get failed, treating as miss', err);
      return null;
    }

    if (l2Entry) {
      const promoted = this.applyL1Ttl(l2Entry);
      void this.l1.set(key, promoted).catch((err: unknown) => {
        console.error('TieredCacheHandler: L1 promotion failed', err);
      });
      return l2Entry;
    }

    return null;
  }

  async set(key: string, entry: CacheEntry): Promise<void> {
    const l2Write = this.l2.set(key, entry).catch((err: unknown) => {
      console.error('TieredCacheHandler: L2 set failed', err);
    });

    const l1Entry = this.applyL1Ttl(entry);
    await Promise.all([l2Write, this.l1.set(key, l1Entry)]);
  }

  private applyL1Ttl(entry: CacheEntry): CacheEntry {
    if (this.l1MaxTtlSeconds === undefined) return entry;

    const capped =
      entry.revalidate > 0
        ? Math.min(entry.revalidate, this.l1MaxTtlSeconds)
        : this.l1MaxTtlSeconds;

    if (capped === entry.revalidate) return entry;

    return { ...entry, revalidate: capped };
  }
}
