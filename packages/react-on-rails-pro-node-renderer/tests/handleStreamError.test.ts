/**
 * Tests for handleStreamError utility.
 *
 * Verifies that the PassThrough stream returned by handleStreamError is properly
 * terminated in all scenarios: normal completion, mid-stream errors, errors before
 * any data, and non-fatal errors that should not interrupt rendering.
 */

import { Readable, PassThrough } from 'stream';
import { handleStreamError } from '../src/shared/utils';

describe('handleStreamError', () => {
  it('ends the PassThrough when the source stream errors mid-stream', async () => {
    const source = new Readable({ read() {} });
    const onError = jest.fn();

    const resultStream = handleStreamError(source, onError);

    // Push some data, then destroy the source
    source.push('chunk1');
    source.push('chunk2');
    source.destroy(new Error('something went wrong during rendering'));

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

  it('ends the PassThrough when the source stream errors before any data', async () => {
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

  it('non-fatal errors (emit without destroy) do not end the PassThrough', async () => {
    const source = new Readable({ read() {} });
    const onError = jest.fn();

    const resultStream = handleStreamError(source, onError);

    const receivedChunks: string[] = [];
    resultStream.on('data', (chunk: Buffer) => {
      receivedChunks.push(chunk.toString());
    });

    source.push('chunk1');

    // Emit error WITHOUT destroying — simulates non-fatal errors like Suspense boundary failures
    source.emit('error', new Error('non-fatal suspense boundary error'));

    await new Promise((resolve) => setTimeout(resolve, 50));
    expect(onError).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'non-fatal suspense boundary error' }),
    );

    // Stream is NOT destroyed — still alive
    expect(source.destroyed).toBe(false);

    // Push more data — rendering continues after non-fatal errors
    source.push('chunk2');
    source.push(null); // End normally

    const streamEnded = await Promise.race([
      new Promise<'ended'>((resolve) => {
        resultStream.on('end', () => resolve('ended'));
      }),
      new Promise<'timeout'>((resolve) => setTimeout(() => resolve('timeout'), 2000)),
    ]);

    expect(streamEnded).toBe('ended');
    expect(receivedChunks).toContain('chunk2');
  }, 5000);

  it('ends the PassThrough correctly when the source ends normally', async () => {
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

  it('preserves data emitted before the error and properly ends the stream', async () => {
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
