import { Script } from 'node:vm';

import { convertToError } from '../src/serverRenderUtils.ts';

type ErrorWithCause = Error & { cause?: unknown };

describe('serverRenderUtils', () => {
  describe('convertToError', () => {
    it('returns Error instances unchanged', () => {
      const error = new Error('Already an error');

      expect(convertToError(error)).toBe(error);
    });

    it('wraps plain object thrown values with a readable message while preserving the original cause', () => {
      const thrownValue = { message: 'plain object failure' };

      const error = convertToError(thrownValue);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('{"message":"plain object failure"}');
      expect((error as ErrorWithCause).cause).toBe(thrownValue);
    });

    it('wraps a thrown string with the string as the message and cause', () => {
      const error = convertToError('something went wrong');

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('something went wrong');
      expect((error as ErrorWithCause).cause).toBe('something went wrong');
    });

    it('wraps a thrown number', () => {
      const error = convertToError(42);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('42');
      expect((error as ErrorWithCause).cause).toBe(42);
    });

    it('wraps null thrown values', () => {
      const error = convertToError(null);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('null');
      expect((error as ErrorWithCause).cause).toBeNull();
    });

    it('wraps undefined thrown values', () => {
      const error = convertToError(undefined);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('undefined');
      expect((error as ErrorWithCause).cause).toBeUndefined();
    });

    it('wraps circular-reference objects without throwing', () => {
      const circular: Record<string, unknown> = {};
      circular.self = circular;

      const error = convertToError(circular);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('[object Object]');
      expect((error as ErrorWithCause).cause).toBe(circular);
    });

    it('wraps errors thrown from another JavaScript realm with their original message and stack', () => {
      const thrownValue: unknown = new Script(`
        const error = new Error("cross-realm failure");
        error.stack = "Error: cross-realm failure\\n    at hostCallback (/tmp/bundle.js:3:1)";
        error;
      `).runInNewContext();

      const error = convertToError(thrownValue);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('cross-realm failure');
      expect(error.stack).toBe((thrownValue as { stack?: unknown }).stack);
      expect((error as ErrorWithCause).cause).toBe(thrownValue);
    });

    it('wraps cross-realm errors with non-string messages using the error tag', () => {
      const thrownValue: unknown = new Script(
        'const error = new Error(); error.message = 42; error',
      ).runInNewContext();

      const error = convertToError(thrownValue);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('[object Error]');
      expect((error as ErrorWithCause).cause).toBe(thrownValue);
    });
  });
});
