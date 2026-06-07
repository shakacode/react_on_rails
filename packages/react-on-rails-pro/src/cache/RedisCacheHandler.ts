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

import type { Redis, RedisOptions } from 'ioredis';
import type { CacheEntry, CacheHandler } from './CacheHandler.ts';

const HEADER_SIZE = 12; // 8 (timestamp float64) + 4 (revalidate int32)

function serialize(entry: CacheEntry): Buffer {
  let totalLen = HEADER_SIZE;
  for (const chunk of entry.value) totalLen += 4 + chunk.length;

  const buf = Buffer.allocUnsafe(totalLen);
  buf.writeDoubleBE(entry.timestamp, 0);
  const revalidateInt = Number.isFinite(entry.revalidate) ? Math.ceil(entry.revalidate) : 0;
  buf.writeInt32BE(revalidateInt, 8);

  let offset = HEADER_SIZE;
  for (const chunk of entry.value) {
    buf.writeUInt32BE(chunk.length, offset);
    offset += 4;
    chunk.copy(buf, offset);
    offset += chunk.length;
  }

  return buf;
}

function deserialize(buf: Buffer): CacheEntry | null {
  if (buf.length < HEADER_SIZE) return null;

  const timestamp = buf.readDoubleBE(0);
  const revalidate = buf.readInt32BE(8);
  const chunks: Buffer[] = [];

  let offset = HEADER_SIZE;
  while (offset < buf.length) {
    if (offset + 4 > buf.length) return null;
    const len = buf.readUInt32BE(offset);
    offset += 4;
    if (offset + len > buf.length) return null;
    chunks.push(buf.subarray(offset, offset + len));
    offset += len;
  }

  return { value: chunks, revalidate, timestamp };
}

export interface RedisCacheHandlerOptions {
  /** ioredis client options or a Redis URL string. Defaults to 'redis://127.0.0.1:6379'. */
  redisUrl?: string | RedisOptions;
  /** Maximum entry size in bytes. Entries larger than this are not cached. Default: 1MB. */
  maxEntryBytes?: number;
}

export class RedisCacheHandler implements CacheHandler {
  private redis: Redis;

  private maxEntryBytes: number;

  constructor(options: RedisCacheHandlerOptions = {}) {
    const { redisUrl = 'redis://127.0.0.1:6379', maxEntryBytes = 1024 * 1024 } = options;

    // Lazy-import ioredis to avoid hard dependency at module load time.
    // eslint-disable-next-line @typescript-eslint/no-require-imports, global-require -- lazy load for optional dependency
    const mod = require('ioredis') as {
      default?: typeof import('ioredis').default;
    } & typeof import('ioredis').default;
    const IORedis = mod.default ?? mod;

    const clientOpts: RedisOptions =
      typeof redisUrl === 'string'
        ? { maxRetriesPerRequest: 1, enableReadyCheck: true, lazyConnect: false }
        : { maxRetriesPerRequest: 1, enableReadyCheck: true, lazyConnect: false, ...redisUrl };

    this.redis = typeof redisUrl === 'string' ? new IORedis(redisUrl, clientOpts) : new IORedis(clientOpts);
    this.maxEntryBytes = maxEntryBytes;

    this.redis.on('error', (err: Error) => {
      console.error('[RedisCacheHandler] Redis error:', err.message);
    });
  }

  async get(key: string): Promise<CacheEntry | null> {
    try {
      const buf = await this.redis.getBuffer(key);
      if (!buf) return null;
      return deserialize(buf);
    } catch {
      return null;
    }
  }

  async set(key: string, entry: CacheEntry): Promise<void> {
    try {
      const blob = serialize(entry);
      if (blob.length > this.maxEntryBytes) {
        console.debug(
          `[RedisCacheHandler] Skipping oversized entry for key "${key}": ${blob.length} bytes > maxEntryBytes (${this.maxEntryBytes}).`,
        );
        return;
      }

      const ttl = Number.isFinite(entry.revalidate) ? Math.ceil(entry.revalidate) : 0;
      if (ttl > 0) {
        await this.redis.set(key, blob, 'EX', ttl);
      } else {
        await this.redis.set(key, blob);
      }
    } catch (err) {
      console.warn('[RedisCacheHandler] set failed, skipping cache write:', (err as Error).message);
    }
  }
}
