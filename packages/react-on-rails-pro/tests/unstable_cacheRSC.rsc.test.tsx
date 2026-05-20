/**
 * @jest-environment node
 */

/* eslint-disable @typescript-eslint/no-require-imports */

import { unstable_revalidateTag } from '../src/cache/revalidateTag';
import { setBuildId } from '../src/cache/buildIdProvider';
import { registerCacheHandler } from '../src/cache/cacheHandlerRegistry';
import { InMemoryLRUCacheHandler } from '../src/cache/InMemoryLRUCacheHandler';

// jest.mock is hoisted, so we build renderers inside the factory using require()
jest.mock('../src/cache/manifestLoader', () => {
  const { buildServerRenderer } = require('react-on-rails-rsc/server.node');
  const { buildClientRenderer } = require('react-on-rails-rsc/client.node');

  const emptyManifest = {
    filePathToModuleMetadata: {},
    moduleLoading: { prefix: '', crossOrigin: null },
  };

  const sr = buildServerRenderer(emptyManifest);
  const cr = buildClientRenderer(emptyManifest, emptyManifest);

  return {
    __esModule: true,
    setManifestFileNames: jest.fn(),
    getServerRenderer: jest.fn().mockResolvedValue(sr),
    getClientRenderer: jest.fn().mockResolvedValue(cr),
  };
});

// Import unstable_cache AFTER the mock is set up (jest handles this via hoisting)
import { unstable_cache } from '../src/cache/unstable_cache';

beforeAll(() => {
  setBuildId('test-build-id-001');
});

describe('unstable_cache', () => {
  beforeEach(() => {
    registerCacheHandler('default', new InMemoryLRUCacheHandler());
  });

  test('cold MISS: calls the original function and returns a result', async () => {
    let callCount = 0;
    const cachedFn = unstable_cache(
      async (name: string) => {
        callCount++;
        return `Hello, ${name}!`;
      },
      { id: 'greeting' },
    );

    const result = await cachedFn('World');
    expect(callCount).toBe(1);
    expect(String(result)).toBe('Hello, World!');
  });

  test('warm HIT: second call returns from cache without re-calling the function', async () => {
    let callCount = 0;
    const cachedFn = unstable_cache(
      async (name: string) => {
        callCount++;
        return `Hi, ${name}!`;
      },
      { id: 'greeting-hit' },
    );

    const result1 = await cachedFn('Alice');
    await new Promise((resolve) => setTimeout(resolve, 50));
    const result2 = await cachedFn('Alice');

    expect(callCount).toBe(1);
    expect(String(result1)).toBe('Hi, Alice!');
    expect(String(result2)).toBe('Hi, Alice!');
  });

  test('distinct args produce distinct cache entries', async () => {
    let callCount = 0;
    const cachedFn = unstable_cache(
      async (id: number) => {
        callCount++;
        return `Item #${id}`;
      },
      { id: 'item-by-id' },
    );

    const result1 = await cachedFn(1);
    await new Promise((resolve) => setTimeout(resolve, 50));
    const result2 = await cachedFn(2);
    await new Promise((resolve) => setTimeout(resolve, 50));
    const result3 = await cachedFn(1);

    expect(callCount).toBe(2);
    expect(String(result1)).toBe('Item #1');
    expect(String(result2)).toBe('Item #2');
    expect(String(result3)).toBe('Item #1');
  });

  test('tag invalidation: revalidateTag removes cached entries', async () => {
    let callCount = 0;
    const cachedFn = unstable_cache(
      async () => {
        callCount++;
        return `call-${callCount}`;
      },
      { id: 'tagged-fn', tags: ['my-tag'] },
    );

    await cachedFn();
    await new Promise((resolve) => setTimeout(resolve, 50));

    await unstable_revalidateTag('my-tag');

    const result = await cachedFn();
    expect(callCount).toBe(2);
    expect(String(result)).toBe('call-2');
  });

  test('single exit point: HIT and MISS produce same type of result', async () => {
    const cachedFn = unstable_cache(async () => 'consistent-value', { id: 'single-exit' });

    const missResult = await cachedFn();
    await new Promise((resolve) => setTimeout(resolve, 50));
    const hitResult = await cachedFn();

    expect(String(missResult)).toBe('consistent-value');
    expect(String(hitResult)).toBe('consistent-value');
    expect(typeof missResult).toBe(typeof hitResult);
  });

  test('different cache kinds use different handlers', async () => {
    const customHandler = new InMemoryLRUCacheHandler();
    registerCacheHandler('custom', customHandler);

    let defaultCallCount = 0;
    let customCallCount = 0;

    const defaultCached = unstable_cache(
      async () => {
        defaultCallCount++;
        return 'default';
      },
      { id: 'kind-test', kind: 'default' },
    );

    const customCached = unstable_cache(
      async () => {
        customCallCount++;
        return 'custom';
      },
      { id: 'kind-test', kind: 'custom' },
    );

    await defaultCached();
    await customCached();
    await new Promise((resolve) => setTimeout(resolve, 50));
    await defaultCached();
    await customCached();

    expect(defaultCallCount).toBe(1);
    expect(customCallCount).toBe(1);
  });

  test('cache errors in storage do not fail the render', async () => {
    const brokenHandler = {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockRejectedValue(new Error('storage failure')),
      revalidateTag: jest.fn().mockResolvedValue(undefined),
    };
    registerCacheHandler('broken', brokenHandler);

    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    const cachedFn = unstable_cache(async () => 'still-works', { id: 'broken-storage', kind: 'broken' });

    const result = await cachedFn();
    await new Promise((resolve) => setTimeout(resolve, 50));

    expect(String(result)).toBe('still-works');
    expect(consoleSpy).toHaveBeenCalledWith('unstable_cache: failed to store cache entry', expect.any(Error));

    consoleSpy.mockRestore();
  });
});
