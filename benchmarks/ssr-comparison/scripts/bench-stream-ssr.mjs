/**
 * Script 5: renderToPipeableStream benchmark (traditional build, no RSC)
 *
 * Uses the same traditional server bundle as bench-string-ssr.mjs but renders
 * via renderToPipeableStream instead of renderToString. This isolates the
 * streaming renderer overhead from any RSC machinery.
 *
 * Measures: render time, TTFB (onShellReady), HTML size, memory.
 */

import { createRequire } from 'module';
import { PassThrough } from 'stream';
import ReactDOMServer from 'react-dom/server';
import React from 'react';
import { summarize } from './lib/stats.mjs';
import { printSingleTable, outputJson } from './lib/reporter.mjs';

const { renderToPipeableStream } = ReactDOMServer;
const { createElement } = React;
const require = createRequire(import.meta.url);
const { default: App } = require('../dist/traditional/server-bundle.cjs');

const WARMUP = 10;
const ITERATIONS = parseInt(process.env.ITERATIONS || '100', 10);
const JSON_OUTPUT = process.argv.includes('--json');

async function run() {
  console.log(`renderToPipeableStream benchmark: ${WARMUP} warmup + ${ITERATIONS} iterations\n`);

  // Warmup
  for (let i = 0; i < WARMUP; i++) {
    await new Promise((resolve, reject) => {
      const { pipe } = renderToPipeableStream(createElement(App), {
        onShellReady() {
          const pt = new PassThrough();
          pipe(pt);
          const chunks = [];
          pt.on('data', (c) => chunks.push(c));
          pt.on('end', resolve);
          pt.on('error', reject);
        },
        onError: reject,
      });
    });
  }

  if (global.gc) global.gc();

  const renderTimes = [];
  const ttfbs = [];
  const heapValues = [];
  const rssValues = [];
  let htmlSize = 0;

  for (let i = 0; i < ITERATIONS; i++) {
    const memBefore = process.memoryUsage();
    const start = process.hrtime.bigint();

    const result = await new Promise((resolve, reject) => {
      let shellReadyTime = null;
      const { pipe } = renderToPipeableStream(createElement(App), {
        onShellReady() {
          shellReadyTime = Number(process.hrtime.bigint() - start);
          const pt = new PassThrough();
          pipe(pt);
          const chunks = [];
          pt.on('data', (c) => chunks.push(c));
          pt.on('end', () => resolve({ html: Buffer.concat(chunks), shellReadyTime }));
          pt.on('error', reject);
        },
        onError: reject,
      });
    });

    const end = process.hrtime.bigint();
    const memAfter = process.memoryUsage();

    renderTimes.push(Number(end - start));
    ttfbs.push(result.shellReadyTime);
    heapValues.push(Math.max(memAfter.heapUsed, memBefore.heapUsed));
    rssValues.push(Math.max(memAfter.rss, memBefore.rss));

    if (i === 0) {
      htmlSize = result.html.length;
    }
  }

  const results = {
    renderTime: summarize(renderTimes),
    ttfb: summarize(ttfbs),
    htmlSize,
    peakHeap: summarize(heapValues),
    peakRss: summarize(rssValues),
    iterations: ITERATIONS,
  };

  if (JSON_OUTPUT) {
    outputJson(results);
  } else {
    printSingleTable('renderToPipeableStream Results (traditional build)', results);
  }

  return results;
}

run().catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
