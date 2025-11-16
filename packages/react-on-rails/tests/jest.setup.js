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
  const { ReadableStream, ReadableStreamDefaultReader } = require('stream/web');

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

if (!['yes', 'true', 'y', 't'].includes(process.env.ENABLE_JEST_CONSOLE || ''.toLowerCase())) {
  global.console.log('All calls to console have been disabled in jest.setup.js');

  global.console = {
    log: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    info: jest.fn(),
    debug: jest.fn(),
  };
}
