/**
 * Script 6: Concurrent request benchmark
 *
 * Simulates a Node.js server handling multiple SSR requests concurrently.
 * Compares renderToString (synchronous, blocks event loop) vs
 * renderToPipeableStream (async, yields via setImmediate between chunks).
 *
 * All requests in a batch are "dispatched" at the same instant (time T0).
 * Latency is measured from T0 to each request's completion — this captures
 * the queuing delay that renderToString imposes (request N must wait for
 * requests 0..N-1 to finish) and the interleaving behavior of streaming.
 *
 * TTFB is measured from T0 to each streaming request's onShellReady.
 */

import { createRequire } from 'module';
import { PassThrough } from 'stream';
import ReactDOMServer from 'react-dom/server';
import React from 'react';
import { summarize } from './lib/stats.mjs';

const { renderToString, renderToPipeableStream } = ReactDOMServer;
const { createElement } = React;
const require = createRequire(import.meta.url);
const { default: App } = require('../dist/traditional/server-bundle.cjs');

const WARMUP = 5;
const ROUNDS = parseInt(process.env.ROUNDS || '20', 10);
const CONCURRENCY_LEVELS = (process.env.CONCURRENCY || '1,5,10,25,50').split(',').map(Number);
const JSON_OUTPUT = process.argv.includes('--json');

// ── Batch runners ───────────────────────────────────────────────────

/**
 * Fire `concurrency` renderToString requests simultaneously.
 * Each is queued via setImmediate — simulating how an HTTP server dispatches
 * request handlers onto the event loop. renderToString blocks the event loop,
 * so requests serialize: request K runs only after 0..K-1 have completed.
 *
 * Latency is measured from batch dispatch time (T0), NOT from when the
 * individual render starts. This captures the queuing delay.
 */
function runStringBatch(concurrency) {
  const t0 = process.hrtime.bigint();
  return Promise.all(
    Array.from({ length: concurrency }, () =>
      new Promise((resolve) => {
        setImmediate(() => {
          renderToString(createElement(App));
          const done = process.hrtime.bigint();
          resolve({ latency: Number(done - t0), ttfb: Number(done - t0) });
        });
      })
    )
  );
}

/**
 * Fire `concurrency` renderToPipeableStream requests simultaneously.
 * All streaming renders start in the same tick — they're non-blocking.
 * renderToPipeableStream yields the event loop via setImmediate between
 * chunks, so work from different requests interleaves naturally.
 *
 * Latency and TTFB are both measured from batch dispatch time (T0).
 */
function runStreamBatch(concurrency) {
  const t0 = process.hrtime.bigint();
  return Promise.all(
    Array.from({ length: concurrency }, () =>
      new Promise((resolve, reject) => {
        let ttfb = null;
        const { pipe } = renderToPipeableStream(createElement(App), {
          onShellReady() {
            ttfb = Number(process.hrtime.bigint() - t0);
            const pt = new PassThrough();
            pipe(pt);
            const chunks = [];
            pt.on('data', (c) => chunks.push(c));
            pt.on('end', () => {
              resolve({ latency: Number(process.hrtime.bigint() - t0), ttfb });
            });
            pt.on('error', reject);
          },
          onError: reject,
        });
      })
    )
  );
}

// ── Formatting helpers ──────────────────────────────────────────────

function fmtMs(ns) { return (ns / 1e6).toFixed(2); }

function pad(s, w) {
  return String(s).padStart(w);
}

function printTable(title, rows) {
  console.log(`\n  ${title}`);
  const cols = Object.keys(rows[0]);
  const widths = cols.map((c) =>
    Math.max(c.length, ...rows.map((r) => String(r[c]).length)) + 2
  );

  const border = (l, m, r) =>
    l + widths.map((w) => '\u2500'.repeat(w)).join(m) + r;
  const row = (vals) =>
    '\u2502' + vals.map((v, i) => pad(v, widths[i])).join('\u2502') + '\u2502';

  console.log(border('\u250C', '\u252C', '\u2510'));
  console.log(row(cols));
  console.log(border('\u251C', '\u253C', '\u2524'));
  rows.forEach((r) => console.log(row(cols.map((c) => r[c]))));
  console.log(border('\u2514', '\u2534', '\u2518'));
}

// ── Main ────────────────────────────────────────────────────────────

async function run() {
  console.log(`Concurrent SSR benchmark: ${ROUNDS} rounds per concurrency level`);
  console.log(`Concurrency levels: ${CONCURRENCY_LEVELS.join(', ')}\n`);
  console.log(`Latency = time from batch dispatch (T0) to request completion.`);
  console.log(`This includes queuing delay for renderToString.\n`);

  // Warmup both paths
  for (let i = 0; i < WARMUP; i++) {
    renderToString(createElement(App));
    await new Promise((resolve, reject) => {
      const { pipe } = renderToPipeableStream(createElement(App), {
        onShellReady() {
          const pt = new PassThrough();
          pipe(pt);
          pt.on('data', () => {});
          pt.on('end', resolve);
          pt.on('error', reject);
        },
        onError: reject,
      });
    });
  }
  if (global.gc) global.gc();

  const allResults = [];

  for (const concurrency of CONCURRENCY_LEVELS) {
    const stringLatencies = [];
    const streamLatencies = [];
    const streamTtfbs = [];
    const stringTtfbs = [];

    for (let r = 0; r < ROUNDS; r++) {
      // Run string batch
      const stringResults = await runStringBatch(concurrency);
      stringLatencies.push(...stringResults.map((x) => x.latency));
      stringTtfbs.push(...stringResults.map((x) => x.ttfb));

      // Small gap to let GC settle
      await new Promise((r) => setTimeout(r, 5));

      // Run stream batch
      const streamResults = await runStreamBatch(concurrency);
      streamLatencies.push(...streamResults.map((x) => x.latency));
      streamTtfbs.push(...streamResults.map((x) => x.ttfb));

      await new Promise((r) => setTimeout(r, 5));
    }

    allResults.push({
      concurrency,
      string: summarize(stringLatencies),
      stringTtfb: summarize(stringTtfbs),
      stream: summarize(streamLatencies),
      streamTtfb: summarize(streamTtfbs),
    });
  }

  if (JSON_OUTPUT) {
    console.log(JSON.stringify(allResults, null, 2));
    return;
  }

  // Print comparison table
  const tableRows = allResults.map((r) => ({
    'Conc': String(r.concurrency),
    'Str mean': fmtMs(r.string.mean) + ' ms',
    'Str p50': fmtMs(r.string.p50) + ' ms',
    'Str p95': fmtMs(r.string.p95) + ' ms',
    'Str p99': fmtMs(r.string.p99) + ' ms',
    'Stm mean': fmtMs(r.stream.mean) + ' ms',
    'Stm p50': fmtMs(r.stream.p50) + ' ms',
    'Stm p95': fmtMs(r.stream.p95) + ' ms',
    'Stm p99': fmtMs(r.stream.p99) + ' ms',
  }));

  printTable('Total Latency (dispatch → complete)', tableRows);

  // TTFB table
  const ttfbRows = allResults.map((r) => ({
    'Conc': String(r.concurrency),
    'Str TTFB mean': fmtMs(r.stringTtfb.mean) + ' ms',
    'Str TTFB p50': fmtMs(r.stringTtfb.p50) + ' ms',
    'Str TTFB p95': fmtMs(r.stringTtfb.p95) + ' ms',
    'Stm TTFB mean': fmtMs(r.streamTtfb.mean) + ' ms',
    'Stm TTFB p50': fmtMs(r.streamTtfb.p50) + ' ms',
    'Stm TTFB p95': fmtMs(r.streamTtfb.p95) + ' ms',
  }));

  printTable('TTFB (dispatch → first bytes / shell ready)', ttfbRows);

  // Ratio analysis
  console.log('\n  Ratio Analysis (Stream / String)');
  console.log('  ' + '\u2500'.repeat(70));
  for (const r of allResults) {
    const meanR = r.stream.mean / r.string.mean;
    const p95R = r.stream.p95 / r.string.p95;
    const ttfbR = r.streamTtfb.mean / r.stringTtfb.mean;
    console.log(`  Conc ${String(r.concurrency).padStart(3)}:  ` +
      `Total mean ${meanR.toFixed(2)}x  ` +
      `Total p95 ${p95R.toFixed(2)}x  ` +
      `TTFB mean ${ttfbR.toFixed(2)}x`);
  }
  console.log();
}

run().catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
