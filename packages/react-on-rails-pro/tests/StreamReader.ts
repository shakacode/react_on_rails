import { PassThrough, Readable } from 'node:stream';
import AsyncQueue from './AsyncQueue.ts';

class StreamReader {
  private asyncQueue: AsyncQueue;

  constructor(pipeableStream: Pick<Readable, 'pipe'>) {
    this.asyncQueue = new AsyncQueue();
    const decoder = new TextDecoder();

    const readableStream = new PassThrough();
    pipeableStream.pipe(readableStream);

    readableStream.on('data', (chunk: Buffer) => {
      const decodedChunk = decoder.decode(chunk);
      this.asyncQueue.enqueue(decodedChunk);
    });

    if (readableStream.closed) {
      this.asyncQueue.end();
    } else {
      readableStream.on('end', () => {
        this.asyncQueue.end();
      });
    }
  }

  nextChunk() {
    return this.asyncQueue.dequeue();
  }
}

export default StreamReader;
