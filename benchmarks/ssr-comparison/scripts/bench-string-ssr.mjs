/**
 * Script 1: renderToString benchmark
 *
 * Loads the traditional server bundle and benchmarks React's renderToString.
 * Measures: render time, HTML size, heap usage, RSS.
 */

import { createRequire } from 'module';
import ReactDOMServer from 'react-dom/server';
import React from 'react';
const { renderToString } = ReactDOMServer;
const { createElement } = React;
import { summarize } from './lib/stats.mjs';
import { printSingleTable, outputJson } from './lib/reporter.mjs';

const require = createRequire(import.meta.url);
const { default: App } = require('../dist/traditional/server-bundle.cjs');

const WARMUP = 10;
const ITERATIONS = parseInt(process.env.ITERATIONS || '100', 10);
const JSON_OUTPUT = process.argv.includes('--json');

function collectMemory() {
  const mem = process.memoryUsage();
  return { heapUsed: mem.heapUsed, rss: mem.rss };
}

async function run() {
  console.log(`renderToString benchmark: ${WARMUP} warmup + ${ITERATIONS} iterations\n`);

  // Warmup
  for (let i = 0; i < WARMUP; i++) {
    renderToString(createElement(App));
  }

  // Force GC if available
  if (global.gc) global.gc();

  const renderTimes = [];
  const heapValues = [];
  const rssValues = [];
  let htmlSize = 0;

  for (let i = 0; i < ITERATIONS; i++) {
    const memBefore = collectMemory();
    const start = process.hrtime.bigint();

    const html = renderToString(createElement(App));

    const end = process.hrtime.bigint();
    const memAfter = collectMemory();

    renderTimes.push(Number(end - start));
    heapValues.push(Math.max(memAfter.heapUsed, memBefore.heapUsed));
    rssValues.push(Math.max(memAfter.rss, memBefore.rss));

    if (i === 0) {
      htmlSize = Buffer.byteLength(html, 'utf8');
    }
  }

  const results = {
    renderTime: summarize(renderTimes),
    htmlSize,
    peakHeap: summarize(heapValues),
    peakRss: summarize(rssValues),
    iterations: ITERATIONS,
  };

  if (JSON_OUTPUT) {
    outputJson(results);
  } else {
    printSingleTable('renderToString Results', results);
  }

  return results;
}

run().catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
