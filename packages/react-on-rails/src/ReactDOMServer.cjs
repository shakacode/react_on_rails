"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.renderToString = exports.renderToPipeableStream = void 0;
// Depending on react-dom version, proper ESM import can be react-dom/server or react-dom/server.js
// but since we have a .cts file, it supports both.
// Remove this file and replace by imports directly from 'react-dom/server' when we drop React 16/17 support.
var server_1 = require("react-dom/server");
Object.defineProperty(exports, "renderToPipeableStream", { enumerable: true, get: function () { return server_1.renderToPipeableStream; } });
Object.defineProperty(exports, "renderToString", { enumerable: true, get: function () { return server_1.renderToString; } });
//# sourceMappingURL=ReactDOMServer.cjs.map