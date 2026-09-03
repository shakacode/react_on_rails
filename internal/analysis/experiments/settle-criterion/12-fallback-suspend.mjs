/**
 * Experiment 12: Can a Fallback Itself Suspend?
 * ================================================
 * Question from #4852: "Can a fallback itself suspend, and if so what
 * lands in the shell?"
 *
 * Setup: A Suspense boundary whose fallback is itself an async component.
 *
 * Case A: Fallback is async but resolves fast (Promise.resolve)
 * Case B: Fallback is async and takes 50ms
 * Case C: Fallback is itself wrapped in another Suspense
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

async function Hanging() {
  await new Promise(() => {});
  return null;
}

async function AsyncFallbackFast() {
  await Promise.resolve();
  return React.createElement('p', null, '[AsyncFallback-fast]');
}

async function AsyncFallbackSlow() {
  await new Promise(r => setTimeout(r, 50));
  return React.createElement('p', null, '[AsyncFallback-slow]');
}

function abort(controller, ms) {
  return new Promise(r => setTimeout(() => { controller.abort(); r(); }, ms));
}

async function run(label, App, delayMs) {
  const controller = new AbortController();
  const renderPromise = ReactDOMServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );
  await abort(controller, delayMs);
  try {
    const { prelude } = await renderPromise;
    const reader = prelude.getReader();
    const chunks = [];
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(new TextDecoder().decode(value));
    }
    const html = chunks.join('');
    console.log(`\n=== ${label} (abort at ${delayMs}ms) ===`);
    console.log(`  HTML: ${html.replace(/\n/g, '')}`);
    console.log(`  Contains "AsyncFallback-fast": ${html.includes('AsyncFallback-fast')}`);
    console.log(`  Contains "AsyncFallback-slow": ${html.includes('AsyncFallback-slow')}`);
    console.log(`  Contains "Hanging": ${html.includes('Hanging')}`);
  } catch (err) {
    console.log(`\n=== ${label} (abort at ${delayMs}ms) ===`);
    console.log(`  ERROR: ${err.message}`);
  }
}

console.log('============================================================');
console.log('EXPERIMENT 12: Can a Suspense Fallback Itself Suspend?');
console.log('React version:', React.version);
console.log('============================================================');

// Case A: Fast async fallback
function CaseA() {
  return React.createElement('div', null,
    React.createElement(
      Suspense,
      { fallback: React.createElement(AsyncFallbackFast) },
      React.createElement(Hanging)
    )
  );
}

await run('A: Async fallback (fast)', CaseA, 100);
await run('A: Async fallback (fast), abort at 5ms', CaseA, 5);

// Case B: Slow async fallback
function CaseB() {
  return React.createElement('div', null,
    React.createElement(
      Suspense,
      { fallback: React.createElement(AsyncFallbackSlow) },
      React.createElement(Hanging)
    )
  );
}

await run('B: Async fallback (slow 50ms), abort at 100ms', CaseB, 100);
await run('B: Async fallback (slow 50ms), abort at 5ms', CaseB, 5);

// Case C: Fallback wrapped in Suspense
function CaseC() {
  return React.createElement('div', null,
    React.createElement(
      Suspense,
      {
        fallback: React.createElement(
          Suspense,
          { fallback: React.createElement('p', null, '[Meta-fallback]') },
          React.createElement(AsyncFallbackSlow)
        )
      },
      React.createElement(Hanging)
    )
  );
}

await run('C: Fallback inside Suspense, abort at 100ms', CaseC, 100);
await run('C: Fallback inside Suspense, abort at 5ms', CaseC, 5);
