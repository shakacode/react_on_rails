/**
 * Tests reproducing issue #2402: Streaming renders hang forever when errors occur during SSR.
 *
 * Root cause: Node.js `stream.pipe()` does NOT propagate errors or end the destination.
 * When the source stream errors, the PassThrough destination stays open indefinitely,
 * causing the HTTP response to never complete and the browser to hang.
 *
 * @see https://github.com/shakacode/react_on_rails/issues/2402
 */

import { Readable, PassThrough } from 'stream';
import { handleStreamError } from '../src/shared/utils';

describe('handleStreamError - issue #2402 reproduction', () => {
  /**
   * This test reproduces the core bug: when a source stream errors AFTER emitting
   * some data, the PassThrough returned by handleStreamError never ends.
   *
   * In the real system, this means:
   * 1. The React rendering stream errors mid-render
   * 2. handleStreamError's PassThrough stays open
   * 3. Fastify's `res.send(stream)` awaits forever
   * 4. The HTTP response never completes
   * 5. The browser loading spinner spins forever
   */
  it('PassThrough stream ends when source stream errors mid-stream', async () => {
    const source = new Readable({ read() {} });
    const onError = jest.fn();

    const resultStream = handleStreamError(source, onError);

    // Push some data (simulating partial render)
    source.push('chunk1');
    source.push('chunk2');

    // Simulate an error mid-stream (e.g., RSC payload error, missing 'use client')
    source.destroy(new Error('something went wrong during rendering'));

    // The error handler IS called (error is reported)
    await new Promise((resolve) => setTimeout(resolve, 50));
    expect(onError).toHaveBeenCalledWith(expect.objectContaining({ message: 'something went wrong during rendering' }));

    const streamEnded = await Promise.race([
      new Promise<'ended'>((resolve) => {
        resultStream.on('end', () => resolve('ended'));
        resultStream.on('close', () => resolve('ended'));
        // Need to consume the stream for 'end' to fire
        resultStream.resume();
      }),
      new Promise<'timeout'>((resolve) => setTimeout(() => resolve('timeout'), 2000)),
    ]);

    expect(streamEnded).toBe('ended');
  }, 5000);

  /**
   * This test verifies the same bug when the source errors BEFORE emitting any data.
   * This is the case when the initial React shell fails to render.
   */
  it('PassThrough stream ends when source stream errors before any data', async () => {
    const source = new Readable({ read() {} });
    const onError = jest.fn();

    const resultStream = handleStreamError(source, onError);

    // Error immediately, no data emitted
    source.destroy(new Error('shell render failed'));

    await new Promise((resolve) => setTimeout(resolve, 50));
    expect(onError).toHaveBeenCalledWith(expect.objectContaining({ message: 'shell render failed' }));

    const streamEnded = await Promise.race([
      new Promise<'ended'>((resolve) => {
        resultStream.on('end', () => resolve('ended'));
        resultStream.on('close', () => resolve('ended'));
        resultStream.resume();
      }),
      new Promise<'timeout'>((resolve) => setTimeout(() => resolve('timeout'), 2000)),
    ]);

    expect(streamEnded).toBe('ended');
  }, 5000);

  /**
   * This test shows that pipe() doesn't propagate errors to the destination.
   * This is the fundamental Node.js behavior that causes the bug.
   */
  it('demonstrates that pipe() does not propagate errors from source to destination', async () => {
    const source = new Readable({ read() {} });
    const destination = new PassThrough();

    const destinationError = jest.fn();
    const destinationEnd = jest.fn();
    const sourceError = jest.fn();

    destination.on('error', destinationError);
    destination.on('end', destinationEnd);
    source.on('error', sourceError);

    source.pipe(destination);
    source.push('hello');

    // Destroy source with error
    source.destroy(new Error('boom'));

    await new Promise((resolve) => setTimeout(resolve, 100));

    // Source error IS emitted
    expect(sourceError).toHaveBeenCalled();

    // Destination NEVER receives the error
    expect(destinationError).not.toHaveBeenCalled();

    // Destination NEVER ends
    expect(destinationEnd).not.toHaveBeenCalled();
    expect(destination.readableEnded).toBe(false);
    expect(destination.destroyed).toBe(false);
  });

  /**
   * Non-fatal errors (like throwJsErrors / emitError) emit 'error' WITHOUT destroying
   * the stream. React may continue rendering after these errors. The PassThrough must
   * stay open so pipe() can forward subsequent data. Only 'close' should trigger
   * termination — not 'error' alone.
   */
  it('non-fatal errors (emit without destroy) do not end the PassThrough', async () => {
    const source = new Readable({ read() {} });
    const onError = jest.fn();

    const resultStream = handleStreamError(source, onError);

    source.push('chunk1');

    // Emit error WITHOUT destroying — simulates emitError for throwJsErrors
    source.emit('error', new Error('non-fatal suspense boundary error'));

    await new Promise((resolve) => setTimeout(resolve, 50));
    expect(onError).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'non-fatal suspense boundary error' }),
    );

    // Stream is NOT destroyed — still alive
    expect(source.destroyed).toBe(false);

    // Push more data — React continues rendering other Suspense boundaries
    source.push('chunk2');
    source.push(null); // End normally

    const streamEnded = await Promise.race([
      new Promise<'ended'>((resolve) => {
        resultStream.on('end', () => resolve('ended'));
        resultStream.resume();
      }),
      new Promise<'timeout'>((resolve) => setTimeout(() => resolve('timeout'), 2000)),
    ]);

    // Stream ends normally — the non-fatal error did NOT cause premature termination
    expect(streamEnded).toBe('ended');
  }, 5000);

  /**
   * Control test: verifies that when the source ends normally,
   * handleStreamError works correctly (the PassThrough ends too).
   */
  it('PassThrough ends correctly when source ends normally', async () => {
    const source = new Readable({ read() {} });
    const onError = jest.fn();

    const resultStream = handleStreamError(source, onError);

    source.push('data1');
    source.push('data2');
    source.push(null); // End the stream normally

    const streamEnded = await Promise.race([
      new Promise<'ended'>((resolve) => {
        resultStream.on('end', () => resolve('ended'));
        resultStream.resume();
      }),
      new Promise<'timeout'>((resolve) => setTimeout(() => resolve('timeout'), 2000)),
    ]);

    expect(streamEnded).toBe('ended');
    expect(onError).not.toHaveBeenCalled();
  }, 5000);

  /**
   * This test verifies that data written before the error IS received.
   * The issue is not about losing data — it's about the stream never closing.
   */
  it('data emitted before the error is received, and stream properly ends', async () => {
    const source = new Readable({ read() {} });
    const onError = jest.fn();

    const resultStream = handleStreamError(source, onError);

    const receivedChunks: string[] = [];
    resultStream.on('data', (chunk: Buffer) => {
      receivedChunks.push(chunk.toString());
    });

    source.push('chunk1');
    source.push('chunk2');

    // Wait for data to propagate through pipe
    await new Promise((resolve) => setTimeout(resolve, 50));

    expect(receivedChunks).toEqual(['chunk1', 'chunk2']);

    // Now error the source
    source.destroy(new Error('mid-stream error'));

    // Wait for error handler and stream end to propagate
    await new Promise((resolve) => setTimeout(resolve, 50));
    expect(onError).toHaveBeenCalled();

    // Data was received and the stream properly ended
    expect(resultStream.writableEnded).toBe(true);
  });
});
