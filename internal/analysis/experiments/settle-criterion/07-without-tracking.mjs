/**
 * Experiment 7: What Happens WITHOUT Tracking (Bare setImmediate Abort)
 * ======================================================================
 * Question: If we DON'T track async work at all and just use
 * setImmediate or setTimeout(0) to abort (like the issue says
 * the RSC final pass does), what breaks with microtask-fast components?
 *
 * This is the "final pass" scenario: all caches are warm, components
 * resolve via Promise.resolve(). The question is whether a single
 * macrotask window is enough.
 *
 * Strategies:
 *   A) Abort on setImmediate (one macrotask after render starts)
 *   B) Abort on setImmediate + setTimeout(0) (two macrotask windows)
 *   C) Abort on setTimeout(0) alone
 *   D) Abort after N sequential setTimeout(0) calls (N=3)
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

// All components resolve via microtask (warm cache)
async function L1({ children }) {
  await Promise.resolve();
  return React.createElement('div', null, '[L1]', children);
}

async function L2({ children }) {
  await Promise.resolve();
  return React.createElement('div', null, '[L2]', children);
}

async function L3({ children }) {
  await Promise.resolve();
  return React.createElement('div', null, '[L3]', children);
}

async function L4({ children }) {
  await Promise.resolve();
  return React.createElement('div', null, '[L4]', children);
}

async function L5({ children }) {
  await Promise.resolve();
  return React.createElement('div', null, '[L5]', children);
}

async function Hanging() {
  await new Promise(() => {});
  return null;
}

function App() {
  return React.createElement(
    'div',
    null,
    React.createElement(
      Suspense,
      { fallback: React.createElement('p', null, 'Outer') },
      React.createElement(L1, null,
        React.createElement(L2, null,
          React.createElement(L3, null,
            React.createElement(L4, null,
              React.createElement(L5, null,
                React.createElement(
                  Suspense,
                  { fallback: React.createElement('p', null, 'Inner') },
                  React.createElement(Hanging)
                )
              )
            )
          )
        )
      )
    )
  );
}

async function run(label, abortFn) {
  const controller = new AbortController();

  const renderPromise = ReactDOMServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );

  await abortFn(controller);

  const { prelude } = await renderPromise;
  const reader = prelude.getReader();
  const chunks = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(new TextDecoder().decode(value));
  }
  const html = chunks.join('');

  const levels = [1,2,3,4,5].map(n => html.includes(`[L${n}]`));
  const hasInner = html.includes('Inner');
  const hasOuter = html.includes('Outer');

  console.log(`\n=== ${label} ===`);
  console.log(`Levels rendered: ${levels.map((v,i) => v ? `L${i+1}` : '').filter(Boolean).join(', ') || 'none'}`);
  console.log(`Fallback shown: ${hasInner ? 'Inner (deep ✓)' : hasOuter ? 'Outer (shallow ✗)' : 'neither'}`);
  console.log(`Verdict: ${hasInner ? '✓ CORRECT' : '✗ PREMATURE ABORT'}`);
}

console.log('============================================================');
console.log('EXPERIMENT 7: Bare Abort Without Tracking');
console.log('React version:', React.version);
console.log('5 levels of async components, all microtask-fast');
console.log('============================================================');

await run('A: setImmediate', (c) =>
  new Promise(resolve => setImmediate(() => { c.abort(); resolve(); }))
);

await run('B: setImmediate + setTimeout(0)', (c) =>
  new Promise(resolve => setImmediate(() => setTimeout(() => { c.abort(); resolve(); }, 0)))
);

await run('C: setTimeout(0) alone', (c) =>
  new Promise(resolve => setTimeout(() => { c.abort(); resolve(); }, 0))
);

await run('D: 3x sequential setTimeout(0)', (c) =>
  new Promise(resolve =>
    setTimeout(() => setTimeout(() => setTimeout(() => {
      c.abort(); resolve();
    }, 0), 0), 0)
  )
);

await run('E: 5x sequential setTimeout(0)', (c) =>
  new Promise(resolve =>
    setTimeout(() => setTimeout(() => setTimeout(() =>
      setTimeout(() => setTimeout(() => {
        c.abort(); resolve();
      }, 0), 0), 0), 0), 0)
  )
);

await run('F: 10x sequential setTimeout(0)', (c) => {
  return new Promise(resolve => {
    let fn = () => { c.abort(); resolve(); };
    for (let i = 0; i < 10; i++) {
      const prev = fn;
      fn = () => setTimeout(prev, 0);
    }
    fn();
  });
});
