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
        postMessage: data => {
          onmessage?.({ data });
        },
      },
    };
  });
}
