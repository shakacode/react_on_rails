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

/* eslint-disable @typescript-eslint/no-unused-vars */

/**
 * Stub module for non-react-server contexts (e.g. SSR server bundle).
 *
 * The auto-load system includes .server.tsx files in both the RSC bundle
 * and the SSR server bundle. The SSR bundle never executes server component
 * code (it delegates to the RSC bundle), but webpack still needs to resolve
 * all imports at build time. This stub satisfies that requirement.
 */

import type { ReactNode } from 'react';
import type { CacheHandler, CacheEntry } from './CacheHandler.ts';

export type { CacheHandler, CacheEntry };

export interface UnstableCacheOptions {
  id: string;
  revalidate?: number;
  kind?: string;
}

const STUB_ERROR =
  'unstable_cache is only available in the react-server bundle. ' +
  'It should not be called from the SSR server bundle or client bundle.';

// eslint-disable-next-line camelcase -- matches Next.js API naming convention
export function unstable_cache<TArgs extends unknown[]>(
  originalFn: (...args: TArgs) => Promise<ReactNode> | ReactNode,
  options: UnstableCacheOptions,
): (...args: TArgs) => Promise<ReactNode> {
  return () => {
    throw new Error(STUB_ERROR);
  };
}

export function registerCacheHandler(kind: string, handler: CacheHandler): void {
  throw new Error(STUB_ERROR);
}

export type { RedisCacheHandlerOptions } from './RedisCacheHandler.ts';
export type { TieredCacheHandlerOptions } from './TieredCacheHandler.ts';

export class RedisCacheHandler implements CacheHandler {
  constructor(_options?: unknown) {
    throw new Error(STUB_ERROR);
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async get(_key: string): Promise<CacheEntry | null> {
    throw new Error(STUB_ERROR);
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async set(_key: string, _entry: CacheEntry): Promise<void> {
    throw new Error(STUB_ERROR);
  }
}

export class TieredCacheHandler implements CacheHandler {
  constructor(_l1: CacheHandler, _l2: CacheHandler, _opts?: unknown) {
    throw new Error(STUB_ERROR);
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async get(_key: string): Promise<CacheEntry | null> {
    throw new Error(STUB_ERROR);
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async set(_key: string, _entry: CacheEntry): Promise<void> {
    throw new Error(STUB_ERROR);
  }
}
