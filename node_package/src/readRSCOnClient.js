/* eslint-disable no-restricted-globals */
/* eslint-disable no-underscore-dangle */
const encoder = new TextEncoder();
let streamController;
// eslint-disable-next-line import/prefer-default-export
export const rscStream = new ReadableStream({
  start(controller) {
    if (typeof window === 'undefined') {
      return;
    }
    const handleChunk = chunk => {
      if (typeof chunk === 'string') {
        controller.enqueue(encoder.encode(chunk));
      } else {
        controller.enqueue(chunk);
      }
    };
    if (!window.__FLIGHT_DATA) {
      window.__FLIGHT_DATA = [];
    }
    window.__FLIGHT_DATA.forEach(handleChunk);
    window.__FLIGHT_DATA.push = (chunk) => {
      handleChunk(chunk);
    };
    streamController = controller;
  },
});

if (typeof document !== 'undefined' && document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    streamController?.close();
  });
} else {
  streamController?.close();
}
