/**
 * Experiment 10: Real-World Patterns — Tracked vs Untracked
 * ===========================================================
 * Simulates real-world component patterns:
 *
 * Pattern 1: "use cache" function (tracked) — resolves via CacheSignal
 * Pattern 2: Raw await fetch (untracked) — app does its own fetch
 * Pattern 3: Database query (untracked) — app does raw DB call
 * Pattern 4: Mixed — some tracked, some untracked
 * Pattern 5: Nested untracked — parent and child both do untracked I/O
 *
 * For each pattern, we test:
 *   A) Final-pass abort (task schedule, no tracking)
 *   B) CacheSignal-tracked abort
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

// --- CacheSignal ---
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

// Simulate I/O
const simulateIO = (ms) => new Promise(r => setTimeout(r, ms));

async function Hanging() {
  await new Promise(() => {});
  return null;
}

// Task-schedule abort (mirrors Next.js final pass)
function taskAbort(controller) {
  return new Promise(resolve => {
    setTimeout(() => setTimeout(() => setTimeout(() => setTimeout(() => {
      controller.abort(); resolve();
    }, 0), 0), 0), 0);
  });
}

async function runTest(label, AppFactory, abortMode) {
  const signal = new CacheSignal();
  const controller = new AbortController();

  const App = AppFactory(signal);

  const renderPromise = ReactDOMServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );

  if (abortMode === 'task') {
    await taskAbort(controller);
  } else {
    await signal.cacheReady();
    controller.abort();
  }

  const { prelude } = await renderPromise;
  const reader = prelude.getReader();
  const chunks = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(new TextDecoder().decode(value));
  }
  const html = chunks.join('');
  return html;
}

function report(label, html, expectedMarkers) {
  console.log(`\n--- ${label} ---`);
  for (const [marker, desc] of expectedMarkers) {
    const found = html.includes(marker);
    console.log(`  ${found ? '✓' : '✗'} "${marker}" — ${desc}`);
  }
}

console.log('============================================================');
console.log('EXPERIMENT 10: Real-World Patterns');
console.log('React version:', React.version);
console.log('============================================================');

// ============================================================
// Pattern 1: Tracked "use cache" component (20ms I/O)
// ============================================================
console.log('\n\n========= PATTERN 1: Tracked "use cache" component =========');

function pattern1(signal) {
  async function CachedProducts({ children }) {
    signal.beginRead();
    await simulateIO(20); // Cache read takes 20ms
    signal.endRead();
    return React.createElement('div', null, '[Products loaded]', children);
  }
  return function App() {
    return React.createElement('div', null,
      React.createElement('h1', null, 'Store'),
      React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading products...') },
        React.createElement(CachedProducts, null,
          React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading reviews...') },
            React.createElement(Hanging)
          )
        )
      )
    );
  };
}

{
  const html1 = await runTest('P1 task abort', pattern1, 'task');
  report('Pattern 1 + Task Abort', html1, [
    ['Products loaded', 'Products rendered in shell'],
    ['Loading products...', 'Shows outer fallback (premature!)'],
    ['Loading reviews...', 'Shows inner fallback (correct depth)'],
  ]);

  const html2 = await runTest('P1 CacheSignal', pattern1, 'signal');
  report('Pattern 1 + CacheSignal Abort', html2, [
    ['Products loaded', 'Products rendered in shell'],
    ['Loading products...', 'Shows outer fallback (premature!)'],
    ['Loading reviews...', 'Shows inner fallback (correct depth)'],
  ]);
}

// ============================================================
// Pattern 2: RAW fetch (untracked, 20ms)
// ============================================================
console.log('\n\n========= PATTERN 2: Raw fetch (untracked) =========');

function pattern2(signal) {
  async function RawFetchProducts({ children }) {
    // App does a raw fetch — NOT wrapped in beginRead/endRead
    await simulateIO(20);
    return React.createElement('div', null, '[Products loaded]', children);
  }
  return function App() {
    return React.createElement('div', null,
      React.createElement('h1', null, 'Store'),
      React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading products...') },
        React.createElement(RawFetchProducts, null,
          React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading reviews...') },
            React.createElement(Hanging)
          )
        )
      )
    );
  };
}

{
  const html1 = await runTest('P2 task abort', pattern2, 'task');
  report('Pattern 2 + Task Abort (UNTRACKED)', html1, [
    ['Products loaded', 'Products rendered in shell'],
    ['Loading products...', 'Shows outer fallback (premature!)'],
    ['Loading reviews...', 'Shows inner fallback (correct depth)'],
  ]);
}

// ============================================================
// Pattern 3: Nested untracked (parent 20ms → child 20ms)
// ============================================================
console.log('\n\n========= PATTERN 3: Nested untracked (parent → child) =========');

function pattern3(signal) {
  async function Layout({ children }) {
    await simulateIO(20); // untracked
    return React.createElement('div', null, '[Layout]', children);
  }
  async function Content({ children }) {
    await simulateIO(20); // untracked
    return React.createElement('div', null, '[Content]', children);
  }
  return function App() {
    return React.createElement('div', null,
      React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading all...') },
        React.createElement(Layout, null,
          React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading content...') },
            React.createElement(Content, null,
              React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading details...') },
                React.createElement(Hanging)
              )
            )
          )
        )
      )
    );
  };
}

{
  const html1 = await runTest('P3 task abort', pattern3, 'task');
  report('Pattern 3 + Task Abort (UNTRACKED)', html1, [
    ['[Layout]', 'Layout rendered'],
    ['[Content]', 'Content rendered'],
    ['Loading all...', 'Shows outermost fallback (premature!)'],
    ['Loading content...', 'Shows middle fallback'],
    ['Loading details...', 'Shows deepest fallback (correct depth)'],
  ]);
}

// ============================================================
// Pattern 4: Mixed — tracked parent, untracked child
// ============================================================
console.log('\n\n========= PATTERN 4: Mixed (tracked parent, untracked child) =========');

function pattern4(signal) {
  async function TrackedLayout({ children }) {
    signal.beginRead();
    await simulateIO(20);
    signal.endRead();
    return React.createElement('div', null, '[Layout-tracked]', children);
  }
  async function UntrackedContent({ children }) {
    await simulateIO(20); // NOT tracked!
    return React.createElement('div', null, '[Content-untracked]', children);
  }
  return function App() {
    return React.createElement('div', null,
      React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading all...') },
        React.createElement(TrackedLayout, null,
          React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading content...') },
            React.createElement(UntrackedContent, null,
              React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading details...') },
                React.createElement(Hanging)
              )
            )
          )
        )
      )
    );
  };
}

{
  const html1 = await runTest('P4 CacheSignal (mixed)', pattern4, 'signal');
  report('Pattern 4 + CacheSignal Abort (MIXED)', html1, [
    ['[Layout-tracked]', 'Tracked layout rendered'],
    ['[Content-untracked]', 'Untracked content rendered'],
    ['Loading all...', 'Outermost fallback'],
    ['Loading content...', 'Middle fallback'],
    ['Loading details...', 'Deepest fallback (correct depth)'],
  ]);
}

// ============================================================
// Pattern 5: Tracked parent → tracked child → untracked grandchild
// ============================================================
console.log('\n\n========= PATTERN 5: Tracked → Tracked → Untracked =========');

function pattern5(signal) {
  async function TrackedA({ children }) {
    signal.beginRead();
    await simulateIO(20);
    signal.endRead();
    return React.createElement('div', null, '[A-tracked]', children);
  }
  async function TrackedB({ children }) {
    signal.beginRead();
    await simulateIO(20);
    signal.endRead();
    return React.createElement('div', null, '[B-tracked]', children);
  }
  async function UntrackedC({ children }) {
    await simulateIO(20);
    return React.createElement('div', null, '[C-untracked]', children);
  }
  return function App() {
    return React.createElement('div', null,
      React.createElement(Suspense, { fallback: React.createElement('p', null, 'Loading all...') },
        React.createElement(TrackedA, null,
          React.createElement(TrackedB, null,
            React.createElement(UntrackedC, null,
              React.createElement(Suspense, { fallback: React.createElement('p', null, 'Dynamic hole') },
                React.createElement(Hanging)
              )
            )
          )
        )
      )
    );
  };
}

{
  const html1 = await runTest('P5 CacheSignal', pattern5, 'signal');
  report('Pattern 5 + CacheSignal Abort (tracked→tracked→UNTRACKED)', html1, [
    ['[A-tracked]', 'A rendered'],
    ['[B-tracked]', 'B rendered'],
    ['[C-untracked]', 'C rendered (piggybacked on B settle window?)'],
    ['Loading all...', 'Outermost fallback'],
    ['Dynamic hole', 'Deepest fallback (correct depth)'],
  ]);
}
