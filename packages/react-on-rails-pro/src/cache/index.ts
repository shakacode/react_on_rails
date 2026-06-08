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

/* eslint-disable camelcase -- matches Next.js API naming convention */
export { unstable_cache } from './unstable_cache.ts';
export type { UnstableCacheOptions } from './unstable_cache.ts';
/* eslint-enable camelcase */
export type { CacheHandler, CacheEntry } from './CacheHandler.ts';
export { registerCacheHandler } from './cacheHandlerRegistry.ts';
export { RedisCacheHandler } from './RedisCacheHandler.ts';
export type { RedisCacheHandlerOptions } from './RedisCacheHandler.ts';
export { TieredCacheHandler } from './TieredCacheHandler.ts';
export type { TieredCacheHandlerOptions } from './TieredCacheHandler.ts';
