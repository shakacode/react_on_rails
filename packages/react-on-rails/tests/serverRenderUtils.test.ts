import { convertToError } from '../src/serverRenderUtils.ts';

describe('serverRenderUtils', () => {
  describe('convertToError', () => {
    it('returns Error instances unchanged', () => {
      const error = new Error('Already an error');

      expect(convertToError(error)).toBe(error);
    });

    it('wraps non-Error thrown values while preserving the original cause', () => {
      const thrownValue = { message: 'plain object failure' };

      const error = convertToError(thrownValue);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('[object Object]');
      expect((error as Error & { cause?: unknown }).cause).toBe(thrownValue);
    });
  });
});
