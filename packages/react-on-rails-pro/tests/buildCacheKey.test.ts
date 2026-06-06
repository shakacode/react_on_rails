/**
 * @jest-environment node
 */

import { buildCacheKey } from '../src/cache/buildCacheKey';

describe('buildCacheKey', () => {
  test('produces consistent keys for the same inputs', () => {
    const key1 = buildCacheKey('build-1', 'component-a', [1, 'two', { three: 3 }]);
    const key2 = buildCacheKey('build-1', 'component-a', [1, 'two', { three: 3 }]);
    expect(key1).toBe(key2);
  });

  test('produces different keys for different buildIds', () => {
    const key1 = buildCacheKey('build-1', 'comp', []);
    const key2 = buildCacheKey('build-2', 'comp', []);
    expect(key1).not.toBe(key2);
  });

  test('produces different keys for different ids', () => {
    const key1 = buildCacheKey('build-1', 'comp-a', []);
    const key2 = buildCacheKey('build-1', 'comp-b', []);
    expect(key1).not.toBe(key2);
  });

  test('produces different keys for different args', () => {
    const key1 = buildCacheKey('build-1', 'comp', [1]);
    const key2 = buildCacheKey('build-1', 'comp', [2]);
    expect(key1).not.toBe(key2);
  });

  test('key starts with rorp:rsc-cache: prefix', () => {
    const key = buildCacheKey('build-1', 'comp', []);
    expect(key).toMatch(/^rorp:rsc-cache:/);
  });

  test('key contains a hex SHA256 hash', () => {
    const key = buildCacheKey('build-1', 'comp', []);
    const hash = key.replace('rorp:rsc-cache:', '');
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
  });

  describe('deterministic key ordering', () => {
    test('objects with different key insertion order produce the same cache key', () => {
      const obj1 = { b: 2, a: 1 };
      const obj2 = { a: 1, b: 2 };
      const key1 = buildCacheKey('build', 'id', [obj1]);
      const key2 = buildCacheKey('build', 'id', [obj2]);
      expect(key1).toBe(key2);
    });

    test('nested objects with different key order produce the same cache key', () => {
      const obj1 = { z: { b: 2, a: 1 }, y: 'hello' };
      const obj2 = { y: 'hello', z: { a: 1, b: 2 } };
      const key1 = buildCacheKey('build', 'id', [obj1]);
      const key2 = buildCacheKey('build', 'id', [obj2]);
      expect(key1).toBe(key2);
    });

    test('arrays preserve order (not sorted)', () => {
      const key1 = buildCacheKey('build', 'id', [[1, 2, 3]]);
      const key2 = buildCacheKey('build', 'id', [[3, 2, 1]]);
      expect(key1).not.toBe(key2);
    });

    test('handles null and undefined values', () => {
      const key1 = buildCacheKey('build', 'id', [null]);
      const key2 = buildCacheKey('build', 'id', [undefined]);
      expect(key1).not.toBe(key2);
    });

    test('empty array and array with undefined produce different keys', () => {
      const key1 = buildCacheKey('build', 'id', []);
      const key2 = buildCacheKey('build', 'id', [undefined]);
      expect(key1).not.toBe(key2);
    });

    test('Date arguments produce distinct keys for different dates', () => {
      const key1 = buildCacheKey('build', 'id', [new Date('2026-01-01')]);
      const key2 = buildCacheKey('build', 'id', [new Date('2026-02-01')]);
      expect(key1).not.toBe(key2);
    });

    test('same Date arguments produce the same key', () => {
      const key1 = buildCacheKey('build', 'id', [new Date('2026-01-01')]);
      const key2 = buildCacheKey('build', 'id', [new Date('2026-01-01')]);
      expect(key1).toBe(key2);
    });
  });
});
