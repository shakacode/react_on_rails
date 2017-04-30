import JsDom from 'jsdom';

global.document = JsDom.jsdom('<div id="root"></div>');
global.window = document.defaultView;

Object.keys(window).forEach((key) => {
  if (!(key in global)) {
    global[key] = window[key];
  }
});
