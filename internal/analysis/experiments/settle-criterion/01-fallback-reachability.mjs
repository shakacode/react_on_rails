/**
 * Experiment 1: Fallback Reachability
 * ====================================
 * Question: When we abort React's prerender, does it emit the fallback for
 * a Suspense boundary that React has NOT yet descended into?
 *
 * Setup:
 * - Outer Suspense (fallback="Loading outer...")
 *   - Async component (resolves after 50ms)
 *     - Inner Suspense (fallback="Loading inner...")
 *       - Another async component (hanging promise — never resolves)
 *
 * Test cases:
 *   A) Abort IMMEDIATELY (0ms) — before outer async resolves
 *   B) Abort after 100ms — outer resolved, inner not yet (hanging)
 *   C) Abort after settling — wait for outer, then abort
 *
 * Expected:
 *   A) "Loading outer..." — inner boundary never reached
 *   B) "Loading inner..." — outer resolved, inner boundary's OWN fallback shown
 *   C) Same as B
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

// A component that resolves after `ms` milliseconds
function createAsyncComponent(name, ms) {
  return async function AsyncComponent({ children }) {
    await new Promise(resolve => setTimeout(resolve, ms));
    return React.createElement('div', { id: name }, `[${name} rendered]`, children);
  };
}

// A component that NEVER resolves (simulates a dynamic hole)
function createHangingComponent(name) {
  return async function HangingComponent() {
    await new Promise(() => {}); // never resolves
    return React.createElement('div', null, `[${name} — should never appear]`);
  };
}

const FastComponent = createAsyncComponent('fast-outer', 50);
const HangingComponent = createHangingComponent('dynamic-hole');

function App() {
  return React.createElement(
    'div',
    null,
    React.createElement('h1', null, 'Shell Header'),
    React.createElement(
      Suspense,
      { fallback: React.createElement('p', null, 'Loading outer...') },
      React.createElement(
        FastComponent,
        null,
        React.createElement(
          Suspense,
          { fallback: React.createElement('p', null, 'Loading inner...') },
          React.createElement(HangingComponent)
        )
      )
    )
  );
}

async function runExperiment(label, abortDelayMs) {
  const controller = new AbortController();

  // Schedule the abort
  if (abortDelayMs === 'settle') {
    // We'll manually settle: wait 200ms (enough for 50ms component)
    setTimeout(() => controller.abort(), 200);
  } else {
    setTimeout(() => controller.abort(), abortDelayMs);
  }

  try {
    const { prelude, postponed } = await ReactDOMServer.prerender(
      React.createElement(App),
      { signal: controller.signal }
    );

    // Read the prelude stream
    const reader = prelude.getReader();
    const chunks = [];
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(new TextDecoder().decode(value));
    }
    const html = chunks.join('');

    console.log(`\n=== ${label} (abort after ${abortDelayMs}) ===`);
    console.log(`HTML length: ${html.length}`);
    console.log(`Postponed: ${postponed != null}`);
    console.log(`Contains "Shell Header": ${html.includes('Shell Header')}`);
    console.log(`Contains "Loading outer...": ${html.includes('Loading outer...')}`);
    console.log(`Contains "Loading inner...": ${html.includes('Loading inner...')}`);
    console.log(`Contains "fast-outer rendered": ${html.includes('[fast-outer rendered]')}`);
    console.log(`Contains "dynamic-hole": ${html.includes('dynamic-hole')}`);
    console.log(`\nFull HTML:\n${html}\n`);
  } catch (err) {
    console.log(`\n=== ${label} (abort after ${abortDelayMs}) ===`);
    console.log(`ERROR: ${err.message}`);
  }
}

console.log('============================================================');
console.log('EXPERIMENT 1: Fallback Reachability');
console.log('React version:', React.version);
console.log('============================================================');

// Run sequentially
await runExperiment('A: Immediate abort', 0);
await runExperiment('B: Abort after 100ms (outer resolved)', 100);
await runExperiment('C: Abort after settle (200ms)', 'settle');
