/**
 * Experiment 4: CacheSignal-Style Settle Tracking
 * =================================================
 * Simulates the exact Next.js CacheSignal mechanism to verify it correctly
 * waits for all reachable async components before aborting.
 *
 * The idea: wrap each "cacheable" async component's promise in
 * beginRead/endRead. The signal fires when count=0 AND a deferred
 * check (setImmediate + setTimeout) confirms no new reads started.
 *
 * Setup:
 *   Same deep tree as experiment 2, but with CacheSignal tracking.
 *   Each async component calls beginRead() before its work and
 *   endRead() when done. The abort fires only when CacheSignal settles.
 *
 * This proves that the CacheSignal mechanism correctly handles:
 *   - Cascading async: L1 resolves → React renders L2 → L2's beginRead
 *     prevents premature settle
 *   - The deferred check prevents aborting between L1.endRead and
 *     L2.beginRead (React's microtask scheduling gap)
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

// ---- CacheSignal implementation (mirrors Next.js) ----

class CacheSignal {
  constructor() {
    this.count = 0;
    this._listeners = [];
    this._pendingCleanup = null;
  }

  beginRead() {
    this.count++;
    // Cancel any pending settle check
    if (this._pendingCleanup) {
      this._pendingCleanup();
      this._pendingCleanup = null;
    }
  }

  endRead() {
    if (this.count <= 0) throw new Error('endRead called with count=0');
    this.count--;
    if (this.count === 0) {
      this._scheduleSettle();
    }
  }

  _scheduleSettle() {
    // Mirror Next.js: setImmediate → setTimeout(0)
    const immediate = setImmediate(() => {
      const timeout = setTimeout(() => {
        if (this.count === 0) {
          // Settled! Resolve all listeners
          const listeners = this._listeners;
          this._listeners = [];
          for (const resolve of listeners) resolve();
        }
        this._pendingCleanup = null;
      }, 0);
      this._pendingCleanup = () => clearTimeout(timeout);
    });
    this._pendingCleanup = () => clearImmediate(immediate);
  }

  cacheReady() {
    if (this.count === 0) {
      // Already at zero — still do deferred check
      return new Promise(resolve => {
        setImmediate(() => setTimeout(() => {
          if (this.count === 0) resolve();
          else this._listeners.push(resolve);
        }, 0));
      });
    }
    return new Promise(resolve => {
      this._listeners.push(resolve);
    });
  }
}

// ---- Components ----

let log = [];
let t0;

function createTrackedComponent(name, ms, signal) {
  return async function TrackedComponent({ children }) {
    signal.beginRead();
    log.push(`[${Date.now() - t0}ms] ${name}.beginRead (count=${signal.count})`);

    await new Promise(resolve => setTimeout(resolve, ms));

    signal.endRead();
    log.push(`[${Date.now() - t0}ms] ${name}.endRead (count=${signal.count})`);

    return React.createElement('div', { id: name }, `[${name}]`, children);
  };
}

async function HangingComponent() {
  await new Promise(() => {}); // never resolves
  return null;
}

async function runExperiment() {
  log = [];
  t0 = Date.now();
  const cacheSignal = new CacheSignal();
  const controller = new AbortController();

  const L1 = createTrackedComponent('L1', 30, cacheSignal);
  const L2 = createTrackedComponent('L2', 30, cacheSignal);
  const L3 = createTrackedComponent('L3', 30, cacheSignal);

  function App() {
    return React.createElement(
      'div',
      null,
      React.createElement('h1', null, 'Shell'),
      React.createElement(
        Suspense,
        { fallback: React.createElement('p', null, 'Outer loading...') },
        React.createElement(
          L1,
          null,
          React.createElement(
            L2,
            null,
            React.createElement(
              L3,
              null,
              React.createElement(
                Suspense,
                { fallback: React.createElement('p', null, 'Inner loading...') },
                React.createElement(HangingComponent)
              )
            )
          )
        )
      )
    );
  }

  // Start render
  const renderPromise = ReactDOMServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );

  // Wait for settle
  log.push(`[${Date.now() - t0}ms] Waiting for cacheSignal.cacheReady()...`);
  await cacheSignal.cacheReady();
  log.push(`[${Date.now() - t0}ms] cacheSignal settled! Aborting render.`);
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
  console.log('EXPERIMENT 4: CacheSignal-Style Settle Tracking');
  console.log('React version:', React.version);
  console.log('============================================================');
  console.log('\nTimeline:');
  for (const entry of log) console.log(`  ${entry}`);
  console.log(`\nContains "Outer loading...": ${html.includes('Outer loading...')}`);
  console.log(`Contains "Inner loading...": ${html.includes('Inner loading...')}`);
  console.log(`Contains [L1]: ${html.includes('[L1]')}`);
  console.log(`Contains [L2]: ${html.includes('[L2]')}`);
  console.log(`Contains [L3]: ${html.includes('[L3]')}`);
  console.log(`\nFull HTML:\n${html}`);
}

await runExperiment();
