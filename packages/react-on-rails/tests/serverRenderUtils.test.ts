import { Script } from 'node:vm';

import { convertToError } from '../src/serverRenderUtils.ts';

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
      expect((error as Error & { cause?: unknown }).cause).toBe(thrownValue);
    });

    it('wraps a thrown string with the string as the message and cause', () => {
      const error = convertToError('something went wrong');

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('something went wrong');
      expect((error as Error & { cause?: unknown }).cause).toBe('something went wrong');
    });

    it('wraps a thrown number', () => {
      const error = convertToError(42);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('42');
      expect((error as Error & { cause?: unknown }).cause).toBe(42);
    });

    it('wraps circular-reference objects without throwing', () => {
      const circular: Record<string, unknown> = {};
      circular.self = circular;

      const error = convertToError(circular);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('[object Object]');
      expect((error as Error & { cause?: unknown }).cause).toBe(circular);
    });

    it('wraps errors thrown from another JavaScript realm with their original message', () => {
      const thrownValue: unknown = new Script('new Error("cross-realm failure")').runInNewContext();

      const error = convertToError(thrownValue);

      expect(error).toBeInstanceOf(Error);
      expect(error.message).toBe('cross-realm failure');
      expect((error as Error & { cause?: unknown }).cause).toBe(thrownValue);
    });
  });
});
