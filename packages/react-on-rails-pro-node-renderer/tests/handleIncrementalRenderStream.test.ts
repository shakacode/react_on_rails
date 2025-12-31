import { handleIncrementalRenderStream } from '../src/worker/handleIncrementalRenderStream';
import { FIELD_SIZE_LIMIT } from '../src/shared/constants';
import type { ResponseResult } from '../src/shared/utils';

/**
 * Creates a mock async iterable stream from an array of buffers
 */
function createMockStream(chunks: Buffer[]): { raw: AsyncIterable<Buffer> } {
  return {
    raw: {
      async *[Symbol.asyncIterator]() {
        for (const chunk of chunks) {
          yield chunk;
        }
      },
    },
  };
}

/**
 * Creates a mock response result
 */
function createMockResponse(): ResponseResult {
  return {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
    data: '{"result": "ok"}',
  };
}

describe('handleIncrementalRenderStream', () => {
  describe('size limits', () => {
    it('rejects request exceeding total size limit (100MB)', async () => {
      // Create chunks that total > 100MB, with newlines to avoid hitting line limit
      // Each chunk is valid JSON + newline, so buffer resets after each
      const chunkSize = 9 * 1024 * 1024; // ~9MB per JSON line (under 10MB line limit)
      const numChunks = 12; // ~108MB total > 100MB limit
      const chunks: Buffer[] = [];

      // First chunk is valid JSON that will be parsed
      const initialJson = JSON.stringify({ type: 'initial', data: 'x'.repeat(chunkSize) });
      chunks.push(Buffer.from(initialJson + '\n'));

      // Subsequent chunks are also valid JSON with newlines
      for (let i = 1; i < numChunks; i++) {
        const updateJson = JSON.stringify({ type: 'update', id: i, data: 'y'.repeat(chunkSize) });
        chunks.push(Buffer.from(updateJson + '\n'));
      }

      const mockRequest = createMockStream(chunks);
      const onRenderRequestReceived = jest.fn().mockResolvedValue({
        response: createMockResponse(),
        shouldContinue: true,
      });
      const onResponseStart = jest.fn();
      const onUpdateReceived = jest.fn().mockResolvedValue(undefined);
      const onRequestEnded = jest.fn();

      await expect(
        handleIncrementalRenderStream({
          request: mockRequest,
          onRenderRequestReceived,
          onResponseStart,
          onUpdateReceived,
          onRequestEnded,
        }),
      ).rejects.toThrow(/NDJSON request exceeds maximum size/);

      await expect(
        handleIncrementalRenderStream({
          request: createMockStream(chunks),
          onRenderRequestReceived: jest.fn().mockResolvedValue({
            response: createMockResponse(),
            shouldContinue: true,
          }),
          onResponseStart: jest.fn(),
          onUpdateReceived: jest.fn().mockResolvedValue(undefined),
          onRequestEnded: jest.fn(),
        }),
      ).rejects.toThrow(/100MB/);
    });

    it('rejects single line exceeding line size limit (10MB)', async () => {
      // Create a single chunk > 10MB without any newlines
      const oversizedLine = Buffer.alloc(FIELD_SIZE_LIMIT + 1024, 'x');
      const chunks = [oversizedLine];

      const mockRequest = createMockStream(chunks);
      const onRenderRequestReceived = jest.fn();
      const onResponseStart = jest.fn();
      const onUpdateReceived = jest.fn();
      const onRequestEnded = jest.fn();

      await expect(
        handleIncrementalRenderStream({
          request: mockRequest,
          onRenderRequestReceived,
          onResponseStart,
          onUpdateReceived,
          onRequestEnded,
        }),
      ).rejects.toThrow(/NDJSON line exceeds maximum size/);

      await expect(
        handleIncrementalRenderStream({
          request: createMockStream(chunks),
          onRenderRequestReceived,
          onResponseStart,
          onUpdateReceived,
          onRequestEnded,
        }),
      ).rejects.toThrow(/Ensure each JSON object is followed by a newline/);
    });

    it('allows valid requests within limits', async () => {
      const validJson = JSON.stringify({ message: 'hello', data: 'x'.repeat(1000) });
      const chunk = Buffer.from(validJson + '\n');
      const chunks = [chunk];

      const mockRequest = createMockStream(chunks);
      const onRenderRequestReceived = jest.fn().mockResolvedValue({
        response: createMockResponse(),
        shouldContinue: false,
      });
      const onResponseStart = jest.fn();
      const onUpdateReceived = jest.fn();
      const onRequestEnded = jest.fn();

      await handleIncrementalRenderStream({
        request: mockRequest,
        onRenderRequestReceived,
        onResponseStart,
        onUpdateReceived,
        onRequestEnded,
      });

      expect(onRenderRequestReceived).toHaveBeenCalledTimes(1);
      expect(onRenderRequestReceived).toHaveBeenCalledWith(expect.objectContaining({ message: 'hello' }));
      expect(onResponseStart).toHaveBeenCalledTimes(1);
    });

    it('processes multiple valid JSON objects with newlines', async () => {
      const obj1 = JSON.stringify({ id: 1, type: 'initial' });
      const obj2 = JSON.stringify({ id: 2, type: 'update' });
      const obj3 = JSON.stringify({ id: 3, type: 'update' });
      const chunk = Buffer.from(`${obj1}\n${obj2}\n${obj3}\n`);

      const mockRequest = createMockStream([chunk]);
      const onRenderRequestReceived = jest.fn().mockResolvedValue({
        response: createMockResponse(),
        shouldContinue: true,
      });
      const onResponseStart = jest.fn();
      const onUpdateReceived = jest.fn().mockResolvedValue(undefined);
      const onRequestEnded = jest.fn();

      await handleIncrementalRenderStream({
        request: mockRequest,
        onRenderRequestReceived,
        onResponseStart,
        onUpdateReceived,
        onRequestEnded,
      });

      expect(onRenderRequestReceived).toHaveBeenCalledTimes(1);
      expect(onUpdateReceived).toHaveBeenCalledTimes(2);
      expect(onRequestEnded).toHaveBeenCalledTimes(1);
    });

    it('resets buffer after processing newlines (no false positive on total size)', async () => {
      // Send multiple small chunks with newlines that total > line limit but each line is small
      const smallJson = JSON.stringify({ data: 'x'.repeat(1000) });
      const chunks: Buffer[] = [];

      // Create 100 chunks of ~1KB each with newlines = 100KB total, all valid
      for (let i = 0; i < 100; i++) {
        chunks.push(Buffer.from(smallJson + '\n'));
      }

      const mockRequest = createMockStream(chunks);
      const onRenderRequestReceived = jest.fn().mockResolvedValue({
        response: createMockResponse(),
        shouldContinue: true,
      });
      const onResponseStart = jest.fn();
      const onUpdateReceived = jest.fn().mockResolvedValue(undefined);
      const onRequestEnded = jest.fn();

      // Should not throw - buffer resets after each newline
      await handleIncrementalRenderStream({
        request: mockRequest,
        onRenderRequestReceived,
        onResponseStart,
        onUpdateReceived,
        onRequestEnded,
      });

      expect(onRenderRequestReceived).toHaveBeenCalledTimes(1);
      expect(onUpdateReceived).toHaveBeenCalledTimes(99); // First is render, rest are updates
      expect(onRequestEnded).toHaveBeenCalledTimes(1);
    });
  });
});
