/**
 * Script 2: RSC payload generation benchmark
 *
 * Uses buildServerRenderer to generate RSC payloads from the RSC bundle.
 * Measures: RSC generation time, payload size.
 */

import { createRequire } from 'module';
import { PassThrough } from 'stream';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import React from 'react';
const { createElement } = React;
import { summarize } from './lib/stats.mjs';
import { printSingleTable, outputJson } from './lib/reporter.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

// Load manifest — use the generated one if it exists, otherwise use empty manifest
const manifestPath = path.resolve(__dirname, '../dist/rsc/react-client-manifest.json');
let manifest;
if (fs.existsSync(manifestPath)) {
  manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
} else {
  manifest = { filePathToModuleMetadata: {}, moduleLoading: { prefix: '', crossOrigin: null } };
}

// Load RSC bundle
const rscBundle = require('../dist/rsc/rsc-bundle.cjs');

const WARMUP = 10;
const ITERATIONS = parseInt(process.env.ITERATIONS || '100', 10);
const JSON_OUTPUT = process.argv.includes('--json');

function collectChunks(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const passThrough = new PassThrough();
    stream.pipe(passThrough);
    passThrough.on('data', (chunk) => chunks.push(chunk));
    passThrough.on('end', () => resolve(Buffer.concat(chunks)));
    passThrough.on('error', reject);
  });
}

async function run() {
  // Build server renderer
  const { buildServerRenderer } = await import('react-on-rails-rsc/server.node');
  const { renderToPipeableStream } = buildServerRenderer(manifest);

  console.log(`RSC payload generation benchmark: ${WARMUP} warmup + ${ITERATIONS} iterations\n`);

  // Warmup
  for (let i = 0; i < WARMUP; i++) {
    const element = createElement(rscBundle.default);
    const stream = renderToPipeableStream(element);
    await collectChunks(stream);
  }

  if (global.gc) global.gc();

  const genTimes = [];
  const heapValues = [];
  const rssValues = [];
  let payloadSize = 0;

  for (let i = 0; i < ITERATIONS; i++) {
    const memBefore = process.memoryUsage();
    const start = process.hrtime.bigint();

    const element = createElement(rscBundle.default);
    const stream = renderToPipeableStream(element);
    const payload = await collectChunks(stream);

    const end = process.hrtime.bigint();
    const memAfter = process.memoryUsage();

    genTimes.push(Number(end - start));
    heapValues.push(Math.max(memAfter.heapUsed, memBefore.heapUsed));
    rssValues.push(Math.max(memAfter.rss, memBefore.rss));

    if (i === 0) {
      payloadSize = payload.length;
      // Save last payload for Script 3
      const outPath = path.resolve(__dirname, '../dist/rsc/rsc-payload.bin');
      fs.mkdirSync(path.dirname(outPath), { recursive: true });
      fs.writeFileSync(outPath, payload);
    }
  }

  const results = {
    rscGenTime: summarize(genTimes),
    payloadSize,
    peakHeap: summarize(heapValues),
    peakRss: summarize(rssValues),
    iterations: ITERATIONS,
  };

  if (JSON_OUTPUT) {
    outputJson(results);
  } else {
    printSingleTable('RSC Payload Generation Results', results);
  }

  return results;
}

run().catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
