/**
 * Script 7: Concurrent benchmark — String vs Stream vs Stream+Suspense
 *
 * Three-way comparison under concurrent load:
 * 1. renderToString (original App, synchronous) — blocks event loop
 * 2. renderToPipeableStream (original App, no Suspense) — yields but full render
 * 3. renderToPipeableStream (SuspenseApp, with Suspense) — shell first, data streams
 *
 * Suspense boundaries wrap the 4 heaviest sections (products, reviews, comments,
 * data table). Data is provided as promises that resolve in a microtask, so
 * the shell (nav, hero, sidebar, skeletons) renders immediately.
 *
 * All latencies measured from batch dispatch time (T0).
 */

import { createRequire } from 'module';
import { PassThrough } from 'stream';
import ReactDOMServer from 'react-dom/server';
import React from 'react';
import { summarize } from './lib/stats.mjs';

const { renderToString, renderToPipeableStream } = ReactDOMServer;
const { createElement } = React;
const require = createRequire(import.meta.url);

// Load both bundles
const { default: App } = require('../dist/traditional/server-bundle.cjs');
const suspenseBundle = require('../dist/traditional/server-bundle-suspense.cjs');
const SuspenseApp = suspenseBundle.default;
const { products, reviews, comments, comparisonData } = suspenseBundle;

const WARMUP = 5;
const ROUNDS = parseInt(process.env.ROUNDS || '20', 10);
const CONCURRENCY_LEVELS = (process.env.CONCURRENCY || '1,5,10,25,50').split(',').map(Number);
const JSON_OUTPUT = process.argv.includes('--json');

// ── Data promise factory ────────────────────────────────────────────

function microtaskPromise(data) {
  return new Promise((resolve) => queueMicrotask(() => resolve(data)));
}

function makeSuspenseProps() {
  return {
    productsPromise: microtaskPromise(products),
    reviewsPromise: microtaskPromise(reviews),
    commentsPromise: microtaskPromise(comments),
    comparisonDataPromise: microtaskPromise(comparisonData),
  };
}

// ── Batch runners ───────────────────────────────────────────────────

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

function runStreamBatch(concurrency) {
  const t0 = process.hrtime.bigint();
  return Promise.all(
    Array.from({ length: concurrency }, () =>
      new Promise((resolve, reject) => {
        const { pipe } = renderToPipeableStream(createElement(App), {
          onShellReady() {
            const ttfb = Number(process.hrtime.bigint() - t0);
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

function runSuspenseBatch(concurrency) {
  const t0 = process.hrtime.bigint();
  return Promise.all(
    Array.from({ length: concurrency }, () =>
      new Promise((resolve, reject) => {
        const element = createElement(SuspenseApp, makeSuspenseProps());
        const { pipe } = renderToPipeableStream(element, {
          onShellReady() {
            const ttfb = Number(process.hrtime.bigint() - t0);
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

// ── Formatting ──────────────────────────────────────────────────────

function fmtMs(ns) { return (ns / 1e6).toFixed(2); }
function pad(s, w) { return String(s).padStart(w); }

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
  console.log(`Concurrent Suspense benchmark: ${ROUNDS} rounds per concurrency level`);
  console.log(`Concurrency levels: ${CONCURRENCY_LEVELS.join(', ')}\n`);

  // Warmup all three paths
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
    await new Promise((resolve, reject) => {
      const { pipe } = renderToPipeableStream(createElement(SuspenseApp, makeSuspenseProps()), {
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
    const strLat = [], strTtfb = [];
    const stmLat = [], stmTtfb = [];
    const susLat = [], susTtfb = [];

    for (let r = 0; r < ROUNDS; r++) {
      const sr = await runStringBatch(concurrency);
      strLat.push(...sr.map((x) => x.latency));
      strTtfb.push(...sr.map((x) => x.ttfb));
      await new Promise((r) => setTimeout(r, 5));

      const stm = await runStreamBatch(concurrency);
      stmLat.push(...stm.map((x) => x.latency));
      stmTtfb.push(...stm.map((x) => x.ttfb));
      await new Promise((r) => setTimeout(r, 5));

      const sus = await runSuspenseBatch(concurrency);
      susLat.push(...sus.map((x) => x.latency));
      susTtfb.push(...sus.map((x) => x.ttfb));
      await new Promise((r) => setTimeout(r, 5));
    }

    allResults.push({
      concurrency,
      string: summarize(strLat),
      stringTtfb: summarize(strTtfb),
      stream: summarize(stmLat),
      streamTtfb: summarize(stmTtfb),
      suspense: summarize(susLat),
      suspenseTtfb: summarize(susTtfb),
    });
  }

  if (JSON_OUTPUT) {
    console.log(JSON.stringify(allResults, null, 2));
    return;
  }

  // ── Total Latency table ──
  const latRows = allResults.map((r) => ({
    'Conc': String(r.concurrency),
    'Str mean': fmtMs(r.string.mean) + ' ms',
    'Str p95': fmtMs(r.string.p95) + ' ms',
    'Stm mean': fmtMs(r.stream.mean) + ' ms',
    'Stm p95': fmtMs(r.stream.p95) + ' ms',
    'Sus mean': fmtMs(r.suspense.mean) + ' ms',
    'Sus p95': fmtMs(r.suspense.p95) + ' ms',
  }));
  printTable('Total Latency — dispatch to complete (Str=String, Stm=Stream, Sus=Stream+Suspense)', latRows);

  // ── TTFB table ──
  const ttfbRows = allResults.map((r) => ({
    'Conc': String(r.concurrency),
    'Str TTFB mean': fmtMs(r.stringTtfb.mean) + ' ms',
    'Str TTFB p95': fmtMs(r.stringTtfb.p95) + ' ms',
    'Stm TTFB mean': fmtMs(r.streamTtfb.mean) + ' ms',
    'Stm TTFB p95': fmtMs(r.streamTtfb.p95) + ' ms',
    'Sus TTFB mean': fmtMs(r.suspenseTtfb.mean) + ' ms',
    'Sus TTFB p95': fmtMs(r.suspenseTtfb.p95) + ' ms',
  }));
  printTable('TTFB — dispatch to first bytes (Str=complete, Stm=shell, Sus=shell)', ttfbRows);

  // ── Ratio analysis ──
  console.log('\n  Ratio Analysis');
  console.log('  ' + '\u2500'.repeat(80));
  console.log('  ' + pad('Conc', 5) +
    pad('Stm/Str', 10) + pad('Sus/Str', 10) + pad('Sus/Stm', 10) +
    '  |' + pad('TTFB Sus/Str', 14) + pad('TTFB Sus/Stm', 14));
  console.log('  ' + '\u2500'.repeat(80));
  for (const r of allResults) {
    const stmStr = (r.stream.mean / r.string.mean).toFixed(2);
    const susStr = (r.suspense.mean / r.string.mean).toFixed(2);
    const susStm = (r.suspense.mean / r.stream.mean).toFixed(2);
    const ttfbSusStr = (r.suspenseTtfb.mean / r.stringTtfb.mean).toFixed(2);
    const ttfbSusStm = (r.suspenseTtfb.mean / r.streamTtfb.mean).toFixed(2);
    console.log('  ' + pad(r.concurrency, 5) +
      pad(stmStr + 'x', 10) + pad(susStr + 'x', 10) + pad(susStm + 'x', 10) +
      '  |' + pad(ttfbSusStr + 'x', 14) + pad(ttfbSusStm + 'x', 14));
  }
  console.log();
}

run().catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
