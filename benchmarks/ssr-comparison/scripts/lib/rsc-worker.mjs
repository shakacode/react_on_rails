/**
 * Worker thread: generates RSC payloads in react-server condition.
 * Communicates via parentPort messages.
 */

import { parentPort } from 'worker_threads';
import { createRequire } from 'module';
import { PassThrough } from 'stream';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import React from 'react';

const { createElement } = React;
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

const manifestPath = path.resolve(__dirname, '../../dist/rsc/react-client-manifest.json');
let manifest;
if (fs.existsSync(manifestPath)) {
  manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
} else {
  manifest = { filePathToModuleMetadata: {}, moduleLoading: { prefix: '', crossOrigin: null } };
}

const rscBundle = require('../../dist/rsc/rsc-bundle.cjs');

async function init() {
  const { buildServerRenderer } = await import('react-on-rails-rsc/server.node');
  const { renderToPipeableStream } = buildServerRenderer(manifest);

  parentPort.on('message', async (msg) => {
    if (msg.type === 'generate') {
      const start = process.hrtime.bigint();
      const element = createElement(rscBundle.default);
      const stream = renderToPipeableStream(element);
      const chunks = [];
      const pt = new PassThrough();
      stream.pipe(pt);
      pt.on('data', (chunk) => chunks.push(chunk));
      pt.on('end', () => {
        const end = process.hrtime.bigint();
        const payload = Buffer.concat(chunks);
        parentPort.postMessage({
          type: 'payload',
          id: msg.id,
          payload,
          timeNs: Number(end - start),
        }, [payload.buffer]);
      });
      pt.on('error', (err) => {
        parentPort.postMessage({ type: 'error', id: msg.id, error: err.message });
      });
    } else if (msg.type === 'exit') {
      process.exit(0);
    }
  });

  parentPort.postMessage({ type: 'ready' });
}

init().catch((err) => {
  parentPort.postMessage({ type: 'error', error: err.message });
  process.exit(1);
});
