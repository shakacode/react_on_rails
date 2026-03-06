/**
 * Script 8: Comprehensive optimization benchmark
 *
 * Tests each optimization suggestion individually and combined to measure
 * real impact on renderToPipeableStream performance:
 *
 * Benchmark-level (no rebuild):
 *   A. Custom Writable — minimal Writable instead of PassThrough
 *   B. progressiveChunkSize: Infinity — disable progressive outlining
 *
 * Component-level (separate build):
 *   C. Consolidated elements — fewer DOM elements (lite components)
 *   D. dangerouslySetInnerHTML — static DataTable as raw HTML
 *   (C+D are combined in AppOptimized)
 *
 * Each config runs ITERATIONS times, measuring total time, TTFB, and HTML size.
 * Results are compared against the renderToString baseline.
 */

import { createRequire } from 'module';
import { PassThrough, Writable } from 'stream';
import ReactDOMServer from 'react-dom/server';
import React from 'react';
import { summarize } from './lib/stats.mjs';

const { renderToString, renderToPipeableStream } = ReactDOMServer;
const { createElement } = React;
const require = createRequire(import.meta.url);

// Load both bundles
const { default: App } = require('../dist/traditional/server-bundle.cjs');
const { default: AppOptimized } = require('../dist/traditional/server-bundle-optimized.cjs');

const WARMUP = 10;
const ITERATIONS = parseInt(process.env.ITERATIONS || '200', 10);

// ── Stream consumers ────────────────────────────────────────────────

function collectWithPassThrough(pipe) {
  return new Promise((resolve, reject) => {
    const pt = new PassThrough();
    pipe(pt);
    const chunks = [];
    pt.on('data', (c) => chunks.push(c));
    pt.on('end', () => resolve(Buffer.concat(chunks)));
    pt.on('error', reject);
  });
}

function collectWithWritable(pipe) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const dest = new Writable({
      write(chunk, _enc, cb) {
        chunks.push(chunk);
        cb();
      },
      final(cb) {
        resolve(Buffer.concat(chunks));
        cb();
      },
    });
    dest.on('error', reject);
    pipe(dest);
  });
}

// ── Render functions ────────────────────────────────────────────────

function benchString(AppComponent) {
  const start = process.hrtime.bigint();
  const html = renderToString(createElement(AppComponent));
  const end = process.hrtime.bigint();
  return {
    totalTime: Number(end - start),
    ttfb: Number(end - start),
    htmlSize: Buffer.byteLength(html, 'utf8'),
  };
}

function benchStream(AppComponent, { useWritable = false, chunkSize } = {}) {
  return new Promise((resolve, reject) => {
    const start = process.hrtime.bigint();
    const opts = {
      onShellReady() {
        const ttfb = Number(process.hrtime.bigint() - start);
        const collector = useWritable
          ? collectWithWritable(pipe)
          : collectWithPassThrough(pipe);
        collector.then((buf) => {
          const end = process.hrtime.bigint();
          resolve({
            totalTime: Number(end - start),
            ttfb,
            htmlSize: buf.length,
          });
        }).catch(reject);
      },
      onError: reject,
    };
    if (chunkSize !== undefined) {
      opts.progressiveChunkSize = chunkSize;
    }
    const { pipe } = renderToPipeableStream(createElement(AppComponent), opts);
  });
}

// ── Config definitions ──────────────────────────────────────────────

const configs = [
  // Baselines
  {
    name: 'toString (original)',
    fn: () => benchString(App),
    async: false,
  },
  {
    name: 'toString (optimized)',
    fn: () => benchString(AppOptimized),
    async: false,
  },
  // Stream variants — original app
  {
    name: 'stream (baseline)',
    fn: () => benchStream(App),
    async: true,
  },
  {
    name: 'stream + Writable',
    fn: () => benchStream(App, { useWritable: true }),
    async: true,
  },
  {
    name: 'stream + chunkInf',
    fn: () => benchStream(App, { chunkSize: Infinity }),
    async: true,
  },
  {
    name: 'stream + Writable + chunkInf',
    fn: () => benchStream(App, { useWritable: true, chunkSize: Infinity }),
    async: true,
  },
  // Stream variants — optimized app
  {
    name: 'stream (optimized)',
    fn: () => benchStream(AppOptimized),
    async: true,
  },
  {
    name: 'stream (opt) + Writable',
    fn: () => benchStream(AppOptimized, { useWritable: true }),
    async: true,
  },
  {
    name: 'stream (opt) + Writ + chunkInf',
    fn: () => benchStream(AppOptimized, { useWritable: true, chunkSize: Infinity }),
    async: true,
  },
];

// ── Runner ──────────────────────────────────────────────────────────

async function runConfig(config) {
  // Warmup
  for (let i = 0; i < WARMUP; i++) {
    if (config.async) {
      await config.fn();
    } else {
      config.fn();
    }
  }
  if (global.gc) global.gc();

  const totalTimes = [];
  const ttfbs = [];
  let htmlSize = 0;

  for (let i = 0; i < ITERATIONS; i++) {
    const result = config.async ? await config.fn() : config.fn();
    totalTimes.push(result.totalTime);
    ttfbs.push(result.ttfb);
    if (i === 0) htmlSize = result.htmlSize;
  }

  return {
    name: config.name,
    totalTime: summarize(totalTimes),
    ttfb: summarize(ttfbs),
    htmlSize,
  };
}

// ── Formatting ──────────────────────────────────────────────────────

function fmtMs(ns) { return (ns / 1e6).toFixed(2); }
function fmtKB(b) { return (b / 1024).toFixed(1); }
function pad(s, w) { return String(s).padStart(w); }

function printResults(results, baselineIdx) {
  const nameW = Math.max(...results.map((r) => r.name.length)) + 2;
  const colW = 11;
  const cols = ['mean (ms)', 'p50 (ms)', 'p95 (ms)', 'TTFB (ms)', 'HTML (KB)', 'vs base'];
  const totalW = nameW + 2 + cols.length * (colW + 1) + 1;

  const border = (l, m, r) => {
    let s = l + '\u2500'.repeat(nameW + 2) + m;
    s += cols.map(() => '\u2500'.repeat(colW + 2)).join(m);
    return s + r;
  };
  const row = (name, vals) => {
    let s = '\u2502 ' + name.padEnd(nameW) + ' \u2502';
    s += vals.map((v) => ' ' + pad(v, colW) + '\u2502').join('');
    return s;
  };

  console.log('\n' + border('\u250C', '\u252C', '\u2510'));
  console.log(row('Configuration', cols));
  console.log(border('\u251C', '\u253C', '\u2524'));

  const baseMean = results[baselineIdx].totalTime.mean;

  for (const r of results) {
    const ratio = (r.totalTime.mean / baseMean).toFixed(2) + 'x';
    console.log(row(r.name, [
      fmtMs(r.totalTime.mean),
      fmtMs(r.totalTime.p50),
      fmtMs(r.totalTime.p95),
      fmtMs(r.ttfb.mean),
      fmtKB(r.htmlSize),
      ratio,
    ]));
  }

  console.log(border('\u2514', '\u2534', '\u2518'));
}

// ── Main ────────────────────────────────────────────────────────────

async function run() {
  console.log(`Optimization benchmark: ${WARMUP} warmup + ${ITERATIONS} iterations per config\n`);

  const results = [];

  for (const config of configs) {
    process.stdout.write(`  Running: ${config.name}...`);
    const result = await runConfig(config);
    results.push(result);
    console.log(` ${fmtMs(result.totalTime.mean)} ms (mean)`);
  }

  printResults(results, 0); // baseline = toString (original)

  // Print impact analysis
  console.log('\n  Impact Analysis (vs stream baseline)');
  console.log('  ' + '\u2500'.repeat(70));
  const streamBaseIdx = results.findIndex((r) => r.name === 'stream (baseline)');
  const streamBase = results[streamBaseIdx].totalTime.mean;
  for (let i = 0; i < results.length; i++) {
    if (i === streamBaseIdx) continue;
    const r = results[i];
    const diff = r.totalTime.mean - streamBase;
    const pct = ((diff / streamBase) * 100).toFixed(1);
    const sign = diff > 0 ? '+' : '';
    console.log(`  ${r.name.padEnd(35)} ${sign}${fmtMs(diff)} ms (${sign}${pct}%)`);
  }
  console.log();
}

run().catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
