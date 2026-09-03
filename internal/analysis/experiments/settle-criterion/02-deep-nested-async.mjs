/**
 * Experiment 2: Deep Nested Async Components
 * ============================================
 * Question: If a "use cache"-style component resolves, revealing inner
 * async components that ALSO need to resolve before we reach the deepest
 * Suspense boundary, does a single-tick abort miss them?
 *
 * Setup (4 levels deep):
 *   Suspense (fallback="Shell loading...")
 *     AsyncLevel1 (resolves in 30ms)
 *       AsyncLevel2 (resolves in 30ms after L1)
 *         AsyncLevel3 (resolves in 30ms after L2)
 *           Suspense (fallback="Deep loading...")
 *             HangingComponent (never resolves — dynamic hole)
 *
 * Test cases:
 *   A) setImmediate abort — fires ~1-2ms after render starts
 *   B) Abort after 50ms — L1 resolved, L2/L3 not yet
 *   C) Abort after 150ms — all levels resolved, deep boundary reached
 *   D) CacheSignal-style: track all async work, abort when settled
 *
 * Expected:
 *   A) "Shell loading..." (nothing resolved yet)
 *   B) "Shell loading..." (L2/L3 not reached → outer fallback)
 *   C) "Deep loading..." (all resolved → inner fallback shown)
 *   D) "Deep loading..." (signal waits for all async to finish)
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

let resolveLog = [];

function createTimedComponent(name, ms) {
  return async function TimedComponent({ children }) {
    await new Promise(resolve => setTimeout(resolve, ms));
    resolveLog.push(`${name} resolved at ${Date.now() - startTime}ms`);
    return React.createElement('div', { id: name }, `[${name}]`, children);
  };
}

function HangingComponent() {
  // This returns a promise that never resolves
  return React.createElement(HangingInner);
}

async function HangingInner() {
  await new Promise(() => {}); // never resolves
  return React.createElement('span', null, 'SHOULD NEVER APPEAR');
}

const Level1 = createTimedComponent('level-1', 30);
const Level2 = createTimedComponent('level-2', 30);
const Level3 = createTimedComponent('level-3', 30);

let startTime;

function App() {
  return React.createElement(
    'div',
    null,
    React.createElement('h1', null, 'Page Shell'),
    React.createElement(
      Suspense,
      { fallback: React.createElement('p', null, 'Shell loading...') },
      React.createElement(
        Level1,
        null,
        React.createElement(
          Level2,
          null,
          React.createElement(
            Level3,
            null,
            React.createElement(
              Suspense,
              { fallback: React.createElement('p', null, 'Deep loading...') },
              React.createElement(HangingComponent)
            )
          )
        )
      )
    )
  );
}

// Simple CacheSignal-like tracker
class SettleTracker {
  constructor() {
    this.count = 0;
    this._resolve = null;
    this._promise = null;
  }

  beginRead() {
    this.count++;
  }

  endRead() {
    this.count--;
    if (this.count === 0 && this._resolve) {
      // Deferred settle: setImmediate + setTimeout(0)
      const resolve = this._resolve;
      setImmediate(() => {
        setTimeout(() => {
          if (this.count === 0) {
            resolve();
          }
        }, 0);
      });
    }
  }

  ready() {
    if (this.count === 0) {
      return new Promise(resolve => {
        setImmediate(() => setTimeout(resolve, 0));
      });
    }
    this._promise = new Promise(resolve => {
      this._resolve = resolve;
    });
    return this._promise;
  }
}

async function runExperiment(label, abortStrategy) {
  resolveLog = [];
  startTime = Date.now();
  const controller = new AbortController();

  if (typeof abortStrategy === 'number') {
    setTimeout(() => controller.abort(), abortStrategy);
  } else if (abortStrategy === 'setImmediate') {
    setImmediate(() => controller.abort());
  }
  // 'settle' handled below

  try {
    const renderPromise = ReactDOMServer.prerender(
      React.createElement(App),
      { signal: controller.signal }
    );

    if (abortStrategy === 'settle') {
      // Wait 200ms for all async work, then deferred abort
      await new Promise(resolve => setTimeout(resolve, 200));
      // Now do deferred settle like CacheSignal: setImmediate + setTimeout
      await new Promise(resolve => setImmediate(() => setTimeout(resolve, 0)));
      controller.abort();
    }

    const { prelude, postponed } = await renderPromise;

    const reader = prelude.getReader();
    const chunks = [];
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(new TextDecoder().decode(value));
    }
    const html = chunks.join('');

    console.log(`\n=== ${label} ===`);
    console.log(`Resolve log: ${resolveLog.join(', ') || '(none)'}`);
    console.log(`Postponed: ${postponed != null}`);
    console.log(`Contains "Shell loading...": ${html.includes('Shell loading...')}`);
    console.log(`Contains "Deep loading...": ${html.includes('Deep loading...')}`);
    console.log(`Contains "level-1": ${html.includes('[level-1]')}`);
    console.log(`Contains "level-2": ${html.includes('[level-2]')}`);
    console.log(`Contains "level-3": ${html.includes('[level-3]')}`);
    console.log(`\nFull HTML:\n${html}\n`);
  } catch (err) {
    console.log(`\n=== ${label} ===`);
    console.log(`Resolve log: ${resolveLog.join(', ') || '(none)'}`);
    console.log(`ERROR: ${err.message}`);
  }
}

console.log('============================================================');
console.log('EXPERIMENT 2: Deep Nested Async Components');
console.log('React version:', React.version);
console.log('============================================================');

await runExperiment('A: setImmediate abort', 'setImmediate');
await runExperiment('B: 50ms abort (only L1 resolved)', 50);
await runExperiment('C: 150ms abort (all resolved)', 150);
await runExperiment('D: Settle-based abort', 'settle');
