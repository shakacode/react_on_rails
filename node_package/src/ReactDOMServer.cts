// Depending on react-dom version, proper ESM import can be react-dom/server or react-dom/server.js
// but this always works in this .cts file
export { renderToPipeableStream, renderToString, type PipeableStream } from 'react-dom/server';
