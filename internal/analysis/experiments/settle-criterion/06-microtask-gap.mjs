/**
 * Experiment 6: The Microtask Gap
 * =================================
 * Question: When async work resolves via microtask (e.g. pre-filled cache
 * hits that resolve as already-fulfilled promises), is there a gap where
 * count=0 fires but React hasn't yet begun rendering the next component?
 *
 * This simulates the "final pass" scenario where all caches are warm and
 * resolve essentially instantly (Promise.resolve()).
 *
 * Setup:
 *   L1 resolves via Promise.resolve() (microtask-fast)
 *   L2 resolves via Promise.resolve()
 *   L3 resolves via Promise.resolve()
 *   Then a hanging component (dynamic hole)
 *
 * The dangerous scenario: L1.endRead → count=0 → setImmediate fires →
 * abort fires → but React would have rendered L2 in the next microtask
 *
 * Test: Does the deferred settle (setImmediate + setTimeout) survive this?
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

let log = [];
let t0;

class CacheSignal {
  constructor() {
    this.count = 0;
    this._listeners = [];
    this._pendingCleanup = null;
  }

  beginRead() {
    this.count++;
    if (this._pendingCleanup) {
      this._pendingCleanup();
      this._pendingCleanup = null;
    }
    log.push(`[${Date.now() - t0}ms] beginRead (count=${this.count})`);
  }

  endRead() {
    this.count--;
    log.push(`[${Date.now() - t0}ms] endRead (count=${this.count})`);
    if (this.count === 0) {
      this._scheduleSettle();
    }
  }

  _scheduleSettle() {
    log.push(`[${Date.now() - t0}ms] scheduling settle check...`);
    const immediate = setImmediate(() => {
      log.push(`[${Date.now() - t0}ms] setImmediate fired (count=${this.count})`);
      const timeout = setTimeout(() => {
        log.push(`[${Date.now() - t0}ms] setTimeout fired (count=${this.count})`);
        if (this.count === 0) {
          const listeners = this._listeners;
          this._listeners = [];
          for (const r of listeners) r();
        }
        this._pendingCleanup = null;
      }, 0);
      this._pendingCleanup = () => clearTimeout(timeout);
    });
    this._pendingCleanup = () => clearImmediate(immediate);
  }

  cacheReady() {
    if (this.count === 0) {
      return new Promise(resolve => {
        setImmediate(() => setTimeout(() => {
          if (this.count === 0) resolve();
          else this._listeners.push(resolve);
        }, 0));
      });
    }
    return new Promise(resolve => this._listeners.push(resolve));
  }
}

// Components that resolve via microtask (simulating warm cache hits)
function createMicrotaskComponent(name, signal) {
  return async function({ children }) {
    signal.beginRead();
    // Resolve immediately — simulates a warm cache read
    await Promise.resolve();
    signal.endRead();
    log.push(`[${Date.now() - t0}ms] ${name} rendered`);
    return React.createElement('div', null, `[${name}]`, children);
  };
}

async function Hanging() {
  await new Promise(() => {});
  return null;
}

async function runExperiment() {
  log = [];
  t0 = Date.now();
  const signal = new CacheSignal();
  const controller = new AbortController();

  const L1 = createMicrotaskComponent('L1', signal);
  const L2 = createMicrotaskComponent('L2', signal);
  const L3 = createMicrotaskComponent('L3', signal);

  function App() {
    return React.createElement(
      'div',
      null,
      React.createElement(
        Suspense,
        { fallback: React.createElement('p', null, 'Outer fallback') },
        React.createElement(L1, null,
          React.createElement(L2, null,
            React.createElement(L3, null,
              React.createElement(
                Suspense,
                { fallback: React.createElement('p', null, 'Inner fallback') },
                React.createElement(Hanging)
              )
            )
          )
        )
      )
    );
  }

  const renderPromise = ReactDOMServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );

  log.push(`[${Date.now() - t0}ms] Waiting for settle...`);
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
  const html = chunks.join('');

  console.log('============================================================');
  console.log('EXPERIMENT 6: Microtask Gap (Warm Cache Simulation)');
  console.log('React version:', React.version);
  console.log('============================================================');
  console.log('\nTimeline:');
  for (const e of log) console.log(`  ${e}`);
  console.log(`\nHas L1: ${html.includes('[L1]')}`);
  console.log(`Has L2: ${html.includes('[L2]')}`);
  console.log(`Has L3: ${html.includes('[L3]')}`);
  console.log(`Has "Outer fallback": ${html.includes('Outer fallback')}`);
  console.log(`Has "Inner fallback": ${html.includes('Inner fallback')}`);
  console.log(`\nVerdict: ${html.includes('Inner fallback')
    ? '✓ All levels resolved, deep fallback shown (CacheSignal survived the microtask gap)'
    : '✗ PREMATURE ABORT — shallow fallback shown'}`);
  console.log(`\nFull HTML:\n${html}`);
}

await runExperiment();
