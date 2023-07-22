//
// polyfills for mini_racer v8 runtime (which has less features than node.js)
//

// `URL` constructor
import 'core-js/actual/url';
// `URLSearchParams` constructor
import 'core-js/actual/url-search-params';

// polyfill TextEncoder & TextDecoder onto `util` b/c `node-util` polyfill doesn't include them
// https://github.com/browserify/node-util/issues/46
import util from 'util';
import 'fast-text-encoding';

Object.assign(util, { TextDecoder, TextEncoder });

// some packages (e.g. `react-dnd`) expect `global` to be available during SSR
globalThis.global = globalThis;
