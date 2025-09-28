import { Readable } from 'stream';

/**
 * Creates a Node.js Readable stream with external push capability.
 * Pusing a null or undefined chunk will end the stream.
 * @returns {{
 *   stream: Readable,
 *   push: (chunk: any) => void
 * }} Object containing the stream and push function
 */
export const createNodeReadableStream = () => {
  const pendingChunks = [];
  let pushFn;
  const stream = new Readable({
    read() {
      pushFn = this.push.bind(this);
      if (pendingChunks.length > 0) {
        pushFn(pendingChunks.shift());
      }
    },
  });

  const push = (chunk) => {
    if (pushFn) {
      pushFn(chunk);
    } else {
      pendingChunks.push(chunk);
    }
  };

  return { stream, push };
};

export const getNodeVersion = () => parseInt(process.version.slice(1), 10);
