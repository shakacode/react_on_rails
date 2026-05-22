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
    const impl = jest.fn<SubSpanFn>(async (_opts, fn) => fn());
    setupSubSpan(impl);
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
    const result = await subSpan({ name: 'test.span' }, async () => 'fallback-ok');
    expect(result).toBe('fallback-ok');
  });
});
