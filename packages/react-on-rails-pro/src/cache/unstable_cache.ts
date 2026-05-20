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

import { PassThrough } from 'stream';
import type { ReactNode } from 'react';
import type { CacheEntry } from './CacheHandler.ts';
import { getCacheHandler } from './cacheHandlerRegistry.ts';
import { buildCacheKey } from './buildCacheKey.ts';
import { getBuildId } from './buildIdProvider.ts';
import { getServerRenderer, getClientRenderer } from './manifestLoader.ts';

export interface UnstableCacheOptions {
  /** Stable identifier for this cached function. Required. */
  id: string;
  /** Cache tags for targeted invalidation via unstable_revalidateTag. */
  tags?: string[];
  /** Time in seconds before the cache entry is considered stale. 0 = indefinite. */
  revalidate?: number;
  /** Cache handler kind to use. Defaults to 'default' (in-memory LRU). */
  kind?: string;
}

function chunksToNodeStream(chunks: Buffer[]): PassThrough {
  const stream = new PassThrough();
  for (const chunk of chunks) {
    stream.push(chunk);
  }
  stream.push(null);
  return stream;
}

function bufferNodeStream(stream: PassThrough): Promise<Buffer[]> {
  const chunks: Buffer[] = [];
  return new Promise((resolve, reject) => {
    stream.on('data', (chunk: Buffer) => chunks.push(chunk));
    stream.on('end', () => resolve(chunks));
    stream.on('error', reject);
  });
}

// eslint-disable-next-line camelcase -- matches Next.js API naming convention
export function unstable_cache<TArgs extends unknown[]>(
  originalFn: (...args: TArgs) => Promise<ReactNode> | ReactNode,
  options: UnstableCacheOptions,
): (...args: TArgs) => Promise<ReactNode> {
  const { id, tags = [], revalidate = 0, kind = 'default' } = options;

  return async function cachedFn(...args: TArgs): Promise<ReactNode> {
    const handler = getCacheHandler(kind);
    const cacheKey = buildCacheKey(getBuildId(), id, args);

    // --- HIT path ---
    const entry = await handler.get(cacheKey, tags);
    if (entry) {
      const replayStream = chunksToNodeStream(entry.value);
      const { createFromNodeStream } = await getClientRenderer();
      return createFromNodeStream<ReactNode>(replayStream);
    }

    // --- MISS path ---
    const reactTree = await originalFn(...args);
    const { renderToPipeableStream } = await getServerRenderer();
    const rscPipeable = renderToPipeableStream(reactTree);

    const source = new PassThrough();
    const forCache = new PassThrough();
    const forReturn = new PassThrough();
    rscPipeable.pipe(source);

    source.on('data', (chunk: Buffer) => {
      forCache.push(chunk);
      forReturn.push(chunk);
    });
    source.on('end', () => {
      forCache.push(null);
      forReturn.push(null);
    });
    source.on('error', (err: Error) => {
      forCache.destroy(err);
      forReturn.destroy(err);
    });

    bufferNodeStream(forCache)
      .then((chunks) => {
        const newEntry: CacheEntry = {
          value: chunks,
          tags,
          revalidate,
          timestamp: Date.now(),
        };
        return handler.set(cacheKey, newEntry);
      })
      .catch((err: unknown) => {
        console.error('unstable_cache: failed to store cache entry', err);
      });

    const { createFromNodeStream } = await getClientRenderer();
    return createFromNodeStream<ReactNode>(forReturn);
  };
}
