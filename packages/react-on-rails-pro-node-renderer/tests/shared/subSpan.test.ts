import { jest } from '@jest/globals';
import { subSpan, setupSubSpan, __resetSubSpanForTest, type SubSpanFn } from '../../src/shared/tracing';

beforeEach(() => {
  __resetSubSpanForTest();
});

describe('subSpan', () => {
  test('default implementation is a pass-through that returns fn() result', async () => {
    const result = await subSpan({ name: 'test.span' }, async () => 42);
    expect(result).toBe(42);
  });

  test('default implementation propagates errors from fn()', async () => {
    await expect(
      subSpan({ name: 'test.span' }, async () => {
        throw new Error('boom');
      }),
    ).rejects.toThrow('boom');
  });

  test('setupSubSpan installs custom implementation that receives name + attributes', async () => {
    const impl = jest.fn(async (_opts: Parameters<SubSpanFn>[0], fn: Parameters<SubSpanFn>[1]) => fn());
    setupSubSpan(impl as unknown as SubSpanFn);
    const result = await subSpan(
      { name: 'test.span', attributes: { 'bundle.timestamp': '123' } },
      async () => 'ok',
    );
    expect(result).toBe('ok');
    expect(impl).toHaveBeenCalledTimes(1);
    expect(impl.mock.calls[0]![0]).toEqual({
      name: 'test.span',
      attributes: { 'bundle.timestamp': '123' },
    });
  });

  test('installed implementation that throws inside the wrapper still surfaces fn() result via fallback', async () => {
    setupSubSpan(() => {
      throw new Error('impl crashed');
    });
    const fn = jest.fn(async () => 'fallback-ok');
    const result = await subSpan({ name: 'test.span' }, fn);
    expect(result).toBe('fallback-ok');
    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('installed implementation that throws after invoking fn does not invoke fn twice', async () => {
    setupSubSpan((_opts, fn) => {
      void fn();
      throw new Error('impl crashed after invoking fn');
    });
    const fn = jest.fn(async () => 'already-started');

    await expect(subSpan({ name: 'test.span' }, fn)).rejects.toThrow('impl crashed after invoking fn');
    expect(fn).toHaveBeenCalledTimes(1);
  });

  test('impl async rejection propagates to caller (not swallowed by sync try/catch)', async () => {
    setupSubSpan(async () => {
      throw new Error('async-crash');
    });
    await expect(subSpan({ name: 'test.span' }, async () => 'never')).rejects.toThrow('async-crash');
  });

  test('setupSubSpan called twice logs a warning and keeps the first impl installed', async () => {
    const firstImpl = jest.fn(async (_opts: Parameters<SubSpanFn>[0], fn: Parameters<SubSpanFn>[1]) => fn());
    const secondImpl = jest.fn(async (_opts: Parameters<SubSpanFn>[0], fn: Parameters<SubSpanFn>[1]) => fn());
    setupSubSpan(firstImpl as unknown as SubSpanFn);
    setupSubSpan(secondImpl as unknown as SubSpanFn);

    await subSpan({ name: 'test.span' }, async () => undefined);
    expect(firstImpl).toHaveBeenCalledTimes(1);
    expect(secondImpl).not.toHaveBeenCalled();
  });
});
