/**
 * Experiment 11: Which Suspense Fallback Wins?
 * ===============================================
 * When an async component is still pending at abort time, React shows a
 * Suspense fallback. But WHICH one? The nearest boundary? The outermost?
 *
 * Setup: nested Suspense boundaries with an untracked async component
 * at different positions in the tree.
 *
 * Case A: Untracked component IS the direct child of a Suspense boundary
 * Case B: Untracked component is BETWEEN two Suspense boundaries
 * Case C: Two Suspense boundaries, untracked in the outer one
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

async function SlowComponent({ children }) {
  await new Promise(r => setTimeout(r, 50)); // 50ms, untracked
  return React.createElement('div', null, '[SlowComponent]', children);
}

function SyncComponent({ children }) {
  return React.createElement('div', null, '[SyncComponent]', children);
}

async function Hanging() {
  await new Promise(() => {});
  return null;
}

// 2-task abort (simulates Next.js HTML pass)
function abort2Tasks(controller) {
  return new Promise(r => setTimeout(() => setTimeout(() => { controller.abort(); r(); }, 0), 0));
}

async function run(label, App) {
  const controller = new AbortController();
  const renderPromise = ReactDOMServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );
  await abort2Tasks(controller);
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
  const markers = [
    'Fallback-outer', 'Fallback-inner', 'Fallback-deep',
    'SlowComponent', 'SyncComponent',
  ];
  for (const m of markers) {
    if (html.includes(m)) console.log(`  ✓ "${m}" found`);
  }
  for (const m of markers) {
    if (!html.includes(m)) console.log(`  ✗ "${m}" NOT found`);
  }
  console.log(`  HTML: ${html.replace(/\n/g, '')}`);
}

console.log('============================================================');
console.log('EXPERIMENT 11: Which Suspense Fallback Wins?');
console.log('React version:', React.version);
console.log('============================================================');

// Case A: SlowComponent is direct child of inner Suspense
function CaseA() {
  return React.createElement('div', null,
    React.createElement(Suspense, { fallback: React.createElement('p', null, 'Fallback-outer') },
      React.createElement(SyncComponent, null,
        React.createElement(Suspense, { fallback: React.createElement('p', null, 'Fallback-inner') },
          React.createElement(SlowComponent, null,
            React.createElement(Suspense, { fallback: React.createElement('p', null, 'Fallback-deep') },
              React.createElement(Hanging)
            )
          )
        )
      )
    )
  );
}

// Case B: SlowComponent wraps the inner Suspense (between two boundaries)
function CaseB() {
  return React.createElement('div', null,
    React.createElement(Suspense, { fallback: React.createElement('p', null, 'Fallback-outer') },
      React.createElement(SlowComponent, null,
        React.createElement(Suspense, { fallback: React.createElement('p', null, 'Fallback-inner') },
          React.createElement(Hanging)
        )
      )
    )
  );
}

// Case C: SlowComponent is between outer Suspense and no inner one
function CaseC() {
  return React.createElement('div', null,
    React.createElement(Suspense, { fallback: React.createElement('p', null, 'Fallback-outer') },
      React.createElement(SlowComponent, null,
        React.createElement('p', null, 'Static content below slow')
      )
    )
  );
}

await run('Case A: Slow inside inner Suspense', CaseA);
await run('Case B: Slow wraps inner Suspense (between boundaries)', CaseB);
await run('Case C: Slow with no inner Suspense (just static children)', CaseC);
