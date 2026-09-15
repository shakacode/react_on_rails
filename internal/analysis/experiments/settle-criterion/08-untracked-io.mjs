/**
 * Experiment 8: Untracked I/O — What Breaks
 * ============================================
 * Question: If a component does real async I/O that the framework doesn't
 * track (e.g., a raw fetch, a database query, or a cross-process cache
 * read), and we use a bare setImmediate abort, what happens?
 *
 * This simulates the react_on_rails scenario where the node renderer
 * calls across a process boundary to read from ActiveSupport::Cache.
 * That read takes real time (say 20ms), and the framework doesn't
 * know about it.
 *
 * Setup:
 *   L1: resolves via setTimeout(20ms) — simulates cross-process cache read
 *     L2: resolves via setTimeout(20ms)
 *       Suspense (fallback="Deep fallback")
 *         Hanging
 *
 * Test cases:
 *   A) Bare setImmediate abort → misses L1/L2
 *   B) CacheSignal tracking L1/L2 → waits correctly
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

let log = [];
let t0;

// Simulates a cross-process cache read (takes real wall-clock time)
async function crossProcessRead(name, ms) {
  log.push(`[${Date.now() - t0}ms] ${name}: starting cross-process read`);
  await new Promise(r => setTimeout(r, ms));
  log.push(`[${Date.now() - t0}ms] ${name}: cross-process read complete`);
  return `data-from-${name}`;
}

async function SlowL1({ children }) {
  const data = await crossProcessRead('L1', 20);
  return React.createElement('div', null, `[L1: ${data}]`, children);
}

async function SlowL2({ children }) {
  const data = await crossProcessRead('L2', 20);
  return React.createElement('div', null, `[L2: ${data}]`, children);
}

async function Hanging() {
  await new Promise(() => {});
  return null;
}

function App() {
  return React.createElement(
    'div',
    null,
    React.createElement('h1', null, 'Page'),
    React.createElement(
      Suspense,
      { fallback: React.createElement('p', null, 'Outer loading...') },
      React.createElement(SlowL1, null,
        React.createElement(SlowL2, null,
          React.createElement(
            Suspense,
            { fallback: React.createElement('p', null, 'Deep fallback') },
            React.createElement(Hanging)
          )
        )
      )
    )
  );
}

// --- CacheSignal (same as experiment 4) ---
class CacheSignal {
  constructor() {
    this.count = 0;
    this._listeners = [];
    this._pendingCleanup = null;
  }
  beginRead() {
    this.count++;
    if (this._pendingCleanup) { this._pendingCleanup(); this._pendingCleanup = null; }
  }
  endRead() {
    this.count--;
    if (this.count === 0) this._scheduleSettle();
  }
  _scheduleSettle() {
    const immediate = setImmediate(() => {
      const timeout = setTimeout(() => {
        if (this.count === 0) {
          const ls = this._listeners; this._listeners = [];
          for (const r of ls) r();
        }
        this._pendingCleanup = null;
      }, 0);
      this._pendingCleanup = () => clearTimeout(timeout);
    });
    this._pendingCleanup = () => clearImmediate(immediate);
  }
  cacheReady() {
    if (this.count === 0) {
      return new Promise(r => setImmediate(() => setTimeout(() => {
        if (this.count === 0) r(); else this._listeners.push(r);
      }, 0)));
    }
    return new Promise(r => this._listeners.push(r));
  }
}

async function runBareAbort() {
  log = [];
  t0 = Date.now();
  const controller = new AbortController();

  const renderPromise = ReactDOMServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );

  // Bare setImmediate abort — no tracking
  await new Promise(r => setImmediate(() => { controller.abort(); r(); }));

  const { prelude } = await renderPromise;
  const reader = prelude.getReader();
  const chunks = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(new TextDecoder().decode(value));
  }
  return { html: chunks.join(''), log: [...log] };
}

async function runTrackedAbort() {
  log = [];
  t0 = Date.now();
  const signal = new CacheSignal();
  const controller = new AbortController();

  // We need to intercept the crossProcessRead calls to track them
  // For this experiment, we patch crossProcessRead
  const origRead = crossProcessRead;
  const patchedRead = async (name, ms) => {
    signal.beginRead();
    log.push(`[${Date.now() - t0}ms] TRACKED: ${name} beginRead (count=${signal.count})`);
    try {
      const result = await origRead(name, ms);
      return result;
    } finally {
      signal.endRead();
      log.push(`[${Date.now() - t0}ms] TRACKED: ${name} endRead (count=${signal.count})`);
    }
  };

  // Monkey-patch for this run (ugly but effective for experiment)
  globalThis.__trackedRead = patchedRead;

  // Create tracked components
  async function TrackedL1({ children }) {
    const data = await globalThis.__trackedRead('L1', 20);
    return React.createElement('div', null, `[L1: ${data}]`, children);
  }
  async function TrackedL2({ children }) {
    const data = await globalThis.__trackedRead('L2', 20);
    return React.createElement('div', null, `[L2: ${data}]`, children);
  }

  function TrackedApp() {
    return React.createElement(
      'div',
      null,
      React.createElement('h1', null, 'Page'),
      React.createElement(
        Suspense,
        { fallback: React.createElement('p', null, 'Outer loading...') },
        React.createElement(TrackedL1, null,
          React.createElement(TrackedL2, null,
            React.createElement(
              Suspense,
              { fallback: React.createElement('p', null, 'Deep fallback') },
              React.createElement(Hanging)
            )
          )
        )
      )
    );
  }

  const renderPromise = ReactDOMServer.prerender(
    React.createElement(TrackedApp),
    { signal: controller.signal }
  );

  await signal.cacheReady();
  log.push(`[${Date.now() - t0}ms] SETTLED → aborting`);
  controller.abort();

  const { prelude } = await renderPromise;
  const reader = prelude.getReader();
  const chunks = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(new TextDecoder().decode(value));
  }
  return { html: chunks.join(''), log: [...log] };
}

console.log('============================================================');
console.log('EXPERIMENT 8: Untracked I/O — What Breaks');
console.log('React version:', React.version);
console.log('============================================================');

{
  const { html, log } = await runBareAbort();
  console.log('\n=== A: Bare setImmediate abort (NO tracking) ===');
  console.log('Timeline:', log.join(' | '));
  console.log(`Has L1: ${html.includes('[L1')}`);
  console.log(`Has L2: ${html.includes('[L2')}`);
  console.log(`Has "Outer loading...": ${html.includes('Outer loading...')}`);
  console.log(`Has "Deep fallback": ${html.includes('Deep fallback')}`);
  console.log(`Verdict: ${html.includes('Deep fallback')
    ? '✓ Deep fallback (correct)'
    : '✗ PREMATURE ABORT — ' + (html.includes('Outer loading...') ? 'outer fallback' : 'unknown')}`);
  console.log(`\nFull HTML:\n${html}`);
}

{
  const { html, log } = await runTrackedAbort();
  console.log('\n=== B: CacheSignal-tracked abort ===');
  console.log('Timeline:', log.join(' | '));
  console.log(`Has L1: ${html.includes('[L1')}`);
  console.log(`Has L2: ${html.includes('[L2')}`);
  console.log(`Has "Outer loading...": ${html.includes('Outer loading...')}`);
  console.log(`Has "Deep fallback": ${html.includes('Deep fallback')}`);
  console.log(`Verdict: ${html.includes('Deep fallback')
    ? '✓ Deep fallback (correct)'
    : '✗ PREMATURE ABORT'}`);
  console.log(`\nFull HTML:\n${html}`);
}
