/**
 * @jest-environment node
 */

import { InMemoryLRUCacheHandler } from '../src/cache/InMemoryLRUCacheHandler';
import type { CacheEntry } from '../src/cache/CacheHandler';

function makeEntry(overrides: Partial<CacheEntry> = {}): CacheEntry {
  return {
    value: [Buffer.from('test-data')],
    revalidate: 0,
    timestamp: Date.now(),
    ...overrides,
  };
}

describe('InMemoryLRUCacheHandler', () => {
  let handler: InMemoryLRUCacheHandler;

  beforeEach(() => {
    handler = new InMemoryLRUCacheHandler(3);
  });

  test('returns null for missing keys', async () => {
    expect(await handler.get('missing')).toBeNull();
  });

  test('stores and retrieves entries', async () => {
    const entry = makeEntry({ value: [Buffer.from('hello')] });
    await handler.set('key1', entry);
    const result = await handler.get('key1');
    expect(result).not.toBeNull();
    expect(result!.value[0].toString()).toBe('hello');
  });

  test('evicts oldest entry when at capacity', async () => {
    await handler.set('a', makeEntry());
    await handler.set('b', makeEntry());
    await handler.set('c', makeEntry());

    // Adding a 4th evicts 'a' (oldest by insertion order)
    await handler.set('d', makeEntry());
    expect(await handler.get('a')).toBeNull();
    expect(await handler.get('b')).not.toBeNull();
    expect(await handler.get('c')).not.toBeNull();
    expect(await handler.get('d')).not.toBeNull();
  });

  test('get() promotes entry to most-recently-used', async () => {
    await handler.set('a', makeEntry());
    await handler.set('b', makeEntry());
    await handler.set('c', makeEntry());

    // Access 'a' to promote it
    await handler.get('a');

    // Now insert two more, evicting b then c
    await handler.set('d', makeEntry());
    await handler.set('e', makeEntry());

    expect(await handler.get('a')).not.toBeNull();
    expect(await handler.get('b')).toBeNull();
    expect(await handler.get('c')).toBeNull();
    expect(await handler.get('d')).not.toBeNull();
    expect(await handler.get('e')).not.toBeNull();
  });

  test('TTL expiry: stale entries return null', async () => {
    const entry = makeEntry({
      revalidate: 1, // 1 second
      timestamp: Date.now() - 2000, // 2 seconds ago
    });
    await handler.set('expired', entry);
    expect(await handler.get('expired')).toBeNull();
  });

  test('TTL: non-expired entries return normally', async () => {
    const entry = makeEntry({
      revalidate: 60, // 60 seconds
      timestamp: Date.now(),
    });
    await handler.set('fresh', entry);
    expect(await handler.get('fresh')).not.toBeNull();
  });

  test('revalidate: 0 means no TTL', async () => {
    const entry = makeEntry({
      revalidate: 0,
      timestamp: Date.now() - 1000000, // Very old
    });
    await handler.set('no-ttl', entry);
    expect(await handler.get('no-ttl')).not.toBeNull();
  });

  test('set() with same key replaces the entry', async () => {
    await handler.set('key', makeEntry({ value: [Buffer.from('old')] }));
    await handler.set('key', makeEntry({ value: [Buffer.from('new')] }));
    const result = await handler.get('key');
    expect(result!.value[0].toString()).toBe('new');
  });
});
