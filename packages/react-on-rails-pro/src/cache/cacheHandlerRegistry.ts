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

import type { CacheHandler } from './CacheHandler.ts';
import { InMemoryLRUCacheHandler } from './InMemoryLRUCacheHandler.ts';

const handlers = new Map<string, CacheHandler>();

handlers.set('default', new InMemoryLRUCacheHandler());

export function registerCacheHandler(kind: string, handler: CacheHandler): void {
  handlers.set(kind, handler);
}

export function getCacheHandler(kind: string): CacheHandler {
  const handler = handlers.get(kind);
  if (!handler) {
    throw new Error(
      `No CacheHandler registered for kind "${kind}". ` +
        `Available kinds: ${[...handlers.keys()].join(', ')}. ` +
        'Register a handler with registerCacheHandler(kind, handler).',
    );
  }
  return handler;
}
