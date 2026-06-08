/**
 * @jest-environment node
 */

import type { CacheEntry } from '../src/cache/CacheHandler';
import { InMemoryLRUCacheHandler } from '../src/cache/InMemoryLRUCacheHandler';
import { TieredCacheHandler } from '../src/cache/TieredCacheHandler';

function makeEntry(overrides: Partial<CacheEntry> = {}): CacheEntry {
  return {
    value: [Buffer.from('test-data')],
    revalidate: 0,
    timestamp: Date.now(),
    ...overrides,
  };
}

describe('TieredCacheHandler', () => {
  let l1: InMemoryLRUCacheHandler;
  let l2: InMemoryLRUCacheHandler;
  let tiered: TieredCacheHandler;

  beforeEach(() => {
    l1 = new InMemoryLRUCacheHandler(100);
    l2 = new InMemoryLRUCacheHandler(1000);
    tiered = new TieredCacheHandler(l1, l2);
  });

  test('get returns null when both L1 and L2 miss', async () => {
    expect(await tiered.get('missing')).toBeNull();
  });

  test('get returns L1 hit without touching L2', async () => {
    const entry = makeEntry({ value: [Buffer.from('l1-data')] });
    await l1.set('key', entry);

    const spy = jest.spyOn(l2, 'get');
    const result = await tiered.get('key');

    expect(result).not.toBeNull();
    expect(result!.value[0].toString()).toBe('l1-data');
    expect(spy).not.toHaveBeenCalled();
  });

  test('get promotes L2 hit to L1', async () => {
    const entry = makeEntry({ value: [Buffer.from('l2-data')] });
    await l2.set('key', entry);

    // L1 miss, L2 hit
    const result = await tiered.get('key');
    expect(result).not.toBeNull();
    expect(result!.value[0].toString()).toBe('l2-data');

    // Now L1 should have it
    const l1Result = await l1.get('key');
    expect(l1Result).not.toBeNull();
    expect(l1Result!.value[0].toString()).toBe('l2-data');
  });

  test('set writes to both L1 and L2', async () => {
    const entry = makeEntry({ value: [Buffer.from('new-data')] });
    await tiered.set('key', entry);

    const l1Result = await l1.get('key');
    const l2Result = await l2.get('key');

    expect(l1Result).not.toBeNull();
    expect(l2Result).not.toBeNull();
    expect(l1Result!.value[0].toString()).toBe('new-data');
    expect(l2Result!.value[0].toString()).toBe('new-data');
  });

  test('L2 failure on get degrades to null (not error)', async () => {
    const failingL2: InMemoryLRUCacheHandler = {
      get: jest.fn().mockRejectedValue(new Error('L2 down')),
      set: jest.fn().mockResolvedValue(undefined),
    } as unknown as InMemoryLRUCacheHandler;
    const handler = new TieredCacheHandler(l1, failingL2);

    const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
    const result = await handler.get('key');
    expect(result).toBeNull();
    consoleSpy.mockRestore();
  });

  test('L2 failure on set does not throw', async () => {
    const failingL2: InMemoryLRUCacheHandler = {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockRejectedValue(new Error('L2 write failed')),
    } as unknown as InMemoryLRUCacheHandler;
    const handler = new TieredCacheHandler(l1, failingL2);

    const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
    await expect(handler.set('key', makeEntry())).resolves.toBeUndefined();

    // L1 should still have the entry despite L2 failure
    const l1Result = await l1.get('key');
    expect(l1Result).not.toBeNull();
    consoleSpy.mockRestore();
  });

  describe('l1MaxTtlSeconds option', () => {
    test('caps revalidate on L1 promotion from L2', async () => {
      const capped = new TieredCacheHandler(l1, l2, { l1MaxTtlSeconds: 10 });
      const entry = makeEntry({ revalidate: 3600 });
      await l2.set('key', entry);

      await capped.get('key');

      const l1Entry = await l1.get('key');
      expect(l1Entry).not.toBeNull();
      expect(l1Entry!.revalidate).toBe(10);
    });

    test('does not increase revalidate beyond original', async () => {
      const capped = new TieredCacheHandler(l1, l2, { l1MaxTtlSeconds: 100 });
      const entry = makeEntry({ revalidate: 5 });
      await l2.set('key', entry);

      await capped.get('key');

      const l1Entry = await l1.get('key');
      expect(l1Entry).not.toBeNull();
      expect(l1Entry!.revalidate).toBe(5);
    });

    test('assigns l1MaxTtlSeconds when original revalidate is 0 (indefinite)', async () => {
      const capped = new TieredCacheHandler(l1, l2, { l1MaxTtlSeconds: 30 });
      const entry = makeEntry({ revalidate: 0 });
      await l2.set('key', entry);

      await capped.get('key');

      const l1Entry = await l1.get('key');
      expect(l1Entry).not.toBeNull();
      expect(l1Entry!.revalidate).toBe(30);
    });

    test('caps revalidate on set to L1', async () => {
      const capped = new TieredCacheHandler(l1, l2, { l1MaxTtlSeconds: 15 });
      const entry = makeEntry({ revalidate: 600 });
      await capped.set('key', entry);

      const l1Entry = await l1.get('key');
      expect(l1Entry).not.toBeNull();
      expect(l1Entry!.revalidate).toBe(15);

      // L2 should have the original revalidate
      const l2Entry = await l2.get('key');
      expect(l2Entry).not.toBeNull();
      expect(l2Entry!.revalidate).toBe(600);
    });
  });
});
