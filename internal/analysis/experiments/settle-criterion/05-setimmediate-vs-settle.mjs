/**
 * Experiment 5: setImmediate-Only vs Deferred Settle
 * ====================================================
 * Question: Is a single setImmediate enough to catch cascading async work,
 * or does it miss follow-on renders?
 *
 * This tests the specific case where:
 *   - L1 resolves → endRead → count=0 → setImmediate fires
 *   - But React hasn't yet scheduled L2's render (which would call beginRead)
 *   - A single setImmediate might fire BEFORE React processes L1's result
 *
 * We compare:
 *   A) Abort on setImmediate after count=0 (what the issue says RSC final pass does)
 *   B) Abort on setImmediate + setTimeout(0) after count=0 (what CacheSignal does)
 *   C) Abort on queueMicrotask + process.nextTick after count=0 (CacheSignal.inputReady)
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

let log = [];
let t0;

// Minimal tracker that just counts reads
class CountTracker {
  constructor(name) {
    this.name = name;
    this.count = 0;
    this._settled = null;
    this._settledResolve = null;
  }

  beginRead() {
    this.count++;
    log.push(`[${Date.now() - t0}ms] ${this.name}: beginRead (count=${this.count})`);
  }

  endRead() {
    this.count--;
    log.push(`[${Date.now() - t0}ms] ${this.name}: endRead (count=${this.count})`);
  }

  // Strategy A: just setImmediate
  waitSetImmediate() {
    return new Promise(resolve => {
      const check = () => {
        if (this.count === 0) {
          setImmediate(() => {
            if (this.count === 0) resolve();
            else {
              // count went back up, re-wait
              this._onZero = check;
            }
          });
        } else {
          this._onZero = check;
        }
      };
      check();
    });
  }

  // Strategy B: setImmediate + setTimeout(0)
  waitDeferredSettle() {
    return new Promise(resolve => {
      const check = () => {
        if (this.count === 0) {
          setImmediate(() => {
            setTimeout(() => {
              if (this.count === 0) resolve();
              else this._onZero = check;
            }, 0);
          });
        } else {
          this._onZero = check;
        }
      };
      check();
    });
  }

  // Strategy C: microtask + nextTick
  waitMicrotaskNextTick() {
    return new Promise(resolve => {
      const check = () => {
        if (this.count === 0) {
          queueMicrotask(() => {
            process.nextTick(() => {
              if (this.count === 0) resolve();
              else this._onZero = check;
            });
          });
        } else {
          this._onZero = check;
        }
      };
      check();
    });
  }

  _onZero = null;

  _checkZero() {
    if (this.count === 0 && this._onZero) {
      const fn = this._onZero;
      this._onZero = null;
      fn();
    }
  }
}

function createTrackedAsync(name, ms, tracker) {
  return async function({ children }) {
    tracker.beginRead();
    await new Promise(r => setTimeout(r, ms));
    tracker.endRead();
    tracker._checkZero();
    return React.createElement('div', null, `[${name}]`, children);
  };
}

async function Hanging() {
  await new Promise(() => {});
  return null;
}

async function run(label, strategy) {
  log = [];
  t0 = Date.now();
  const tracker = new CountTracker(strategy);
  const controller = new AbortController();

  const L1 = createTrackedAsync('L1', 20, tracker);
  const L2 = createTrackedAsync('L2', 20, tracker);
  const L3 = createTrackedAsync('L3', 20, tracker);

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

  let waitPromise;
  if (strategy === 'setImmediate') waitPromise = tracker.waitSetImmediate();
  else if (strategy === 'deferred') waitPromise = tracker.waitDeferredSettle();
  else waitPromise = tracker.waitMicrotaskNextTick();

  await waitPromise;
  log.push(`[${Date.now() - t0}ms] ${strategy} settled → aborting`);
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

  console.log(`\n=== ${label} ===`);
  console.log(`Timeline: ${log.join(' | ')}`);
  console.log(`Has L1: ${html.includes('[L1]')}`);
  console.log(`Has L2: ${html.includes('[L2]')}`);
  console.log(`Has L3: ${html.includes('[L3]')}`);
  console.log(`Has "Outer fallback": ${html.includes('Outer fallback')}`);
  console.log(`Has "Inner fallback": ${html.includes('Inner fallback')}`);
  console.log(`\nVerdict: ${html.includes('Inner fallback') ? '✓ Deep fallback reached (correct)' : '✗ Shallow fallback (premature abort!)'}`);
}

console.log('============================================================');
console.log('EXPERIMENT 5: setImmediate vs Deferred Settle');
console.log('React version:', React.version);
console.log('============================================================');

await run('A: setImmediate only', 'setImmediate');
await run('B: setImmediate + setTimeout(0)', 'deferred');
await run('C: microtask + nextTick', 'microtask');
