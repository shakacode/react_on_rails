// If jsdom environment is set and TextEncoder is not defined, then define TextEncoder and TextDecoder
// The current version of jsdom does not support TextEncoder and TextDecoder
// The following code will tell us when jsdom supports TextEncoder and TextDecoder
if (typeof window !== 'undefined' && typeof window.TextEncoder !== 'undefined') {
  throw new Error('TextEncoder is already defined, remove the polyfill');
}

// Similarly for MessageChannel
if (typeof window !== 'undefined' && typeof window.MessageChannel !== 'undefined') {
  throw new Error('MessageChannel is already defined, remove the polyfill');
}

if (typeof window !== 'undefined') {
  // eslint-disable-next-line global-require
  const { TextEncoder, TextDecoder } = require('util');
  // eslint-disable-next-line global-require
  const { Readable } = require('stream');
  // eslint-disable-next-line global-require
  const { ReadableStream, ReadableStreamDefaultReader } = require('stream/web');

  // Mock the fetch function to return a ReadableStream instead of Node's Readable stream
  // This matches browser behavior where fetch responses have ReadableStream bodies
  // Node's fetch and polyfills like jest-fetch-mock return Node's Readable stream,
  // so we convert it to a web-standard ReadableStream for consistency
  // Note: Node's Readable stream exists in node 'stream' built-in module, can be imported as `import { Readable } from 'stream'`
  jest.mock('../src/utils', () => ({
    ...jest.requireActual('../src/utils'),
    fetch: (...args) =>
      jest
        .requireActual('../src/utils')
        .fetch(...args)
        .then((res) => {
          const originalBody = res.body;
          if (originalBody instanceof Readable) {
            Object.defineProperty(res, 'body', {
              value: Readable.toWeb(originalBody),
            });
          }
          return res;
        }),
  }));

  global.TextEncoder = TextEncoder;
  global.TextDecoder = TextDecoder;

  // https://github.com/jsdom/jsdom/issues/2448#issuecomment-1703763542
  global.MessageChannel = jest.fn().mockImplementation(() => {
    let onmessage;
    return {
      port1: {
        set onmessage(cb) {
          onmessage = cb;
        },
      },
      port2: {
        postMessage: (data) => {
          onmessage?.({ data });
        },
      },
    };
  });
  global.ReadableStream = ReadableStream;
  global.ReadableStreamDefaultReader = ReadableStreamDefaultReader;
}
