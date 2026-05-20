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

  private tagIndex = new Map<string, Set<string>>();

  private maxEntries: number;

  constructor(maxEntries = 1000) {
    this.maxEntries = maxEntries;
  }

  // eslint-disable-next-line @typescript-eslint/require-await, @typescript-eslint/no-unused-vars -- CacheHandler interface is async for remote implementations; softTags reserved for future use
  async get(key: string, _softTags: string[]): Promise<CacheEntry | null> {
    const entry = this.cache.get(key);
    if (!entry) return null;

    if (entry.revalidate > 0 && Date.now() - entry.timestamp > entry.revalidate * 1000) {
      this.deleteEntry(key);
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
      this.deleteEntry(key);
    }

    // Evict oldest (first) entry if at capacity
    if (this.cache.size >= this.maxEntries) {
      const oldestKey = this.cache.keys().next().value;
      if (oldestKey !== undefined) {
        this.deleteEntry(oldestKey);
      }
    }

    this.cache.set(key, entry);

    for (const tag of entry.tags) {
      let keys = this.tagIndex.get(tag);
      if (!keys) {
        keys = new Set();
        this.tagIndex.set(tag, keys);
      }
      keys.add(key);
    }
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async revalidateTag(tag: string): Promise<void> {
    const keys = this.tagIndex.get(tag);
    if (!keys) return;

    for (const key of keys) {
      this.deleteEntry(key);
    }
    this.tagIndex.delete(tag);
  }

  private deleteEntry(key: string): void {
    const entry = this.cache.get(key);
    if (entry) {
      for (const tag of entry.tags) {
        const tagKeys = this.tagIndex.get(tag);
        if (tagKeys) {
          tagKeys.delete(key);
          if (tagKeys.size === 0) {
            this.tagIndex.delete(tag);
          }
        }
      }
    }
    this.cache.delete(key);
  }
}
