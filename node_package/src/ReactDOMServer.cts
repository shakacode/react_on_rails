// Depending on react-dom version, proper ESM import can be react-dom/server or react-dom/server.js
// but since we have a .cts file, it supports both.
// Remove this file and replace by imports directly from 'react-dom/server' when we drop React 16/17 support.
export { renderToPipeableStream, renderToString, type PipeableStream } from 'react-dom/server';
