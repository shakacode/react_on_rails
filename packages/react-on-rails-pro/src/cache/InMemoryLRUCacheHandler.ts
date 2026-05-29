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

// eslint-disable-next-line import/prefer-default-export -- designed for named import alongside the interface
export class InMemoryLRUCacheHandler implements CacheHandler {
  private cache = new Map<string, CacheEntry>();

  private maxEntries: number;

  constructor(maxEntries = 1000) {
    this.maxEntries = maxEntries;
  }

  // eslint-disable-next-line @typescript-eslint/require-await -- CacheHandler interface is async for remote implementations
  async get(key: string): Promise<CacheEntry | null> {
    const entry = this.cache.get(key);
    if (!entry) return null;

    if (entry.revalidate > 0 && Date.now() - entry.timestamp > entry.revalidate * 1000) {
      this.cache.delete(key);
      return null;
    }

    // Move to end (most-recently-used) by re-inserting
    this.cache.delete(key);
    this.cache.set(key, entry);
    return entry;
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async set(key: string, entry: CacheEntry): Promise<void> {
    // If key already exists, remove it first so re-insert goes to end
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }

    // Evict oldest (first) entry if at capacity
    if (this.cache.size >= this.maxEntries) {
      const oldestKey = this.cache.keys().next().value;
      if (oldestKey !== undefined) {
        this.cache.delete(oldestKey);
      }
    }

    this.cache.set(key, entry);
  }
}
