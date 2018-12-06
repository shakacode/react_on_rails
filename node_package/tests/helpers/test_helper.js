import { JSDOM } from 'jsdom';

const url = 'http://localhost';
const { document } = (new JSDOM('<div id="root"></div>', { url })).window;
global.document = document;
global.window = document.defaultView;

Object.keys(window).forEach((key) => {
  if (!(key in global)) {
    global[key] = window[key];
  }
});
