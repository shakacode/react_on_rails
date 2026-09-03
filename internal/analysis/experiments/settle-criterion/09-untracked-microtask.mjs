/**
 * Experiment 9: Untracked Async at Different Speeds
 * ====================================================
 * What happens when a component does async work that is NOT tracked
 * by CacheSignal? We test at different speeds:
 *
 *   A) await Promise.resolve()        — microtask-fast
 *   B) await setTimeout(0)            — one macrotask
 *   C) await setTimeout(5)            — ~5ms
 *   D) await setTimeout(20)           — ~20ms (simulates fast DB query)
 *   E) await setTimeout(100)          — ~100ms (simulates network call)
 *
 * Each component sits inside a Suspense boundary. We abort using
 * Next.js's final-pass strategy: task-schedule (runInSequentialTasks
 * equivalent — a few sequential setTimeout(0) calls).
 *
 * Question: which components make it into the shell?
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

function makeAsyncComponent(name, asyncWork) {
  return async function({ children }) {
    await asyncWork();
    return React.createElement('div', null, `[${name}]`, children);
  };
}

async function Hanging() {
  await new Promise(() => {});
  return null;
}

const components = [
  {
    name: 'A: Promise.resolve()',
    work: () => Promise.resolve(),
  },
  {
    name: 'B: setTimeout(0)',
    work: () => new Promise(r => setTimeout(r, 0)),
  },
  {
    name: 'C: setTimeout(5)',
    work: () => new Promise(r => setTimeout(r, 5)),
  },
  {
    name: 'D: setTimeout(20)',
    work: () => new Promise(r => setTimeout(r, 20)),
  },
  {
    name: 'E: setTimeout(100)',
    work: () => new Promise(r => setTimeout(r, 100)),
  },
];

// Simulate Next.js final-pass abort: N sequential setTimeout(0)
function taskScheduleAbort(controller, nTasks) {
  return new Promise(resolve => {
    let chain = () => { controller.abort(); resolve(); };
    for (let i = 0; i < nTasks; i++) {
      const prev = chain;
      chain = () => setTimeout(prev, 0);
    }
    chain();
  });
}

console.log('============================================================');
console.log('EXPERIMENT 9: Untracked Async at Different Speeds');
console.log('React version:', React.version);
console.log('Abort strategy: 4 sequential setTimeout(0) (Next.js final pass)');
console.log('============================================================');

for (const { name, work } of components) {
  const Comp = makeAsyncComponent(name, work);
  const controller = new AbortController();

  function App() {
    return React.createElement('div', null,
      React.createElement('h1', null, 'Shell'),
      React.createElement(
        Suspense,
        { fallback: React.createElement('p', null, `FALLBACK: ${name}`) },
        React.createElement(Comp, null,
          React.createElement(
            Suspense,
            { fallback: React.createElement('p', null, 'Dynamic hole') },
            React.createElement(Hanging)
          )
        )
      )
    );
  }

  const renderPromise = ReactDOMServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );

  // 4-task abort (mirrors Next.js final pass)
  await taskScheduleAbort(controller, 4);

  const { prelude } = await renderPromise;
  const reader = prelude.getReader();
  const chunks = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(new TextDecoder().decode(value));
  }
  const html = chunks.join('');

  const rendered = html.includes(`[${name}]`);
  const showsFallback = html.includes(`FALLBACK: ${name}`);
  const showsDynamic = html.includes('Dynamic hole');

  console.log(`\n${name}:`);
  console.log(`  Component rendered: ${rendered ? '✓ YES' : '✗ NO'}`);
  console.log(`  Shows own fallback: ${showsFallback ? '⚠ YES (premature abort)' : 'no'}`);
  console.log(`  Shows deep dynamic hole: ${showsDynamic ? '✓ YES (correct depth)' : '✗ NO'}`);
}
