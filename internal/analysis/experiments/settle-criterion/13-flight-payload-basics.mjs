/**
 * Experiment 13: What Does a Flight Payload Look Like?
 * ======================================================
 * Uses react-server-dom-webpack/static to generate an actual Flight stream
 * and inspect the raw bytes.
 *
 * Since we can't use the full webpack machinery, we use the vanilla
 * react-dom/static prerender to show what Fizz produces and demonstrate
 * the relationship between the RSC output and HTML output.
 *
 * We show:
 *   - What HTML React produces for sync, async, and suspended components
 *   - How Suspense boundaries appear in the prelude
 *   - What "postponed" state looks like
 *   - The difference between complete and partial prerenders
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

async function renderAndInspect(label, element, abortMs) {
  const controller = new AbortController();
  if (abortMs !== undefined) {
    setTimeout(() => controller.abort(), abortMs);
  }

  const opts = { signal: controller.signal };
  const { prelude, postponed } = await ReactDOMServer.prerender(element, opts);

  const reader = prelude.getReader();
  const chunks = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
  }

  const html = chunks.map(c => new TextDecoder().decode(c)).join('');
  const totalBytes = chunks.reduce((sum, c) => sum + c.byteLength, 0);

  console.log(`\n${'='.repeat(60)}`);
  console.log(`${label}`);
  console.log(`${'='.repeat(60)}`);
  console.log(`Chunks: ${chunks.length}`);
  console.log(`Total bytes: ${totalBytes}`);
  console.log(`Postponed: ${postponed != null}`);
  if (postponed != null) {
    console.log(`Postponed type: ${typeof postponed}`);
  }
  console.log(`\nHTML output:\n${html}`);
  console.log(`\nHTML annotated:`);

  // Annotate the HTML markers
  const annotations = [
    ['<!--$-->', 'Suspense boundary START (resolved)'],
    ['<!--/$-->', 'Suspense boundary END'],
    ['<!--$?-->', 'Suspense boundary START (pending/fallback)'],
    ['<template id="B:', 'Pending boundary marker (will be replaced)'],
    ['<div hidden id="S:', 'Hidden resolved content (streamed later)'],
    ['<template id="P:', 'Postponed boundary (PPR hole)'],
  ];
  for (const [marker, desc] of annotations) {
    if (html.includes(marker)) {
      console.log(`  ✓ "${marker}" → ${desc}`);
    }
  }

  return { html, postponed, chunks };
}

// ---- Test Cases ----

// Case 1: Fully sync component — no Suspense
function SyncApp() {
  return React.createElement('div', null,
    React.createElement('h1', null, 'Hello'),
    React.createElement('p', null, 'World')
  );
}

// Case 2: Sync component inside Suspense
function SyncWithSuspense() {
  return React.createElement(Suspense,
    { fallback: React.createElement('p', null, 'Loading...') },
    React.createElement('div', null, 'Content')
  );
}

// Case 3: Async component that resolves before abort
async function ResolvedAsync() {
  await Promise.resolve();
  return React.createElement('div', null, 'Async Content');
}

function AsyncResolved() {
  return React.createElement(Suspense,
    { fallback: React.createElement('p', null, 'Loading...') },
    React.createElement(ResolvedAsync)
  );
}

// Case 4: Async component — hanging (dynamic hole)
async function Hanging() {
  await new Promise(() => {});
  return null;
}

function WithDynamicHole() {
  return React.createElement('div', null,
    React.createElement('h1', null, 'Static Header'),
    React.createElement(Suspense,
      { fallback: React.createElement('p', null, 'Dynamic Content Loading...') },
      React.createElement(Hanging)
    ),
    React.createElement('footer', null, 'Static Footer')
  );
}

// Case 5: Mixed — some resolved, some hanging
async function SlowButResolves({ children }) {
  await new Promise(r => setTimeout(r, 10));
  return React.createElement('main', null, '[Main Content]', children);
}

function MixedApp() {
  return React.createElement('div', null,
    React.createElement('h1', null, 'Page'),
    React.createElement(Suspense,
      { fallback: React.createElement('p', null, 'Loading main...') },
      React.createElement(SlowButResolves, null,
        React.createElement(Suspense,
          { fallback: React.createElement('p', null, 'Loading user...') },
          React.createElement(Hanging)
        )
      )
    )
  );
}

// Case 6: Multiple dynamic holes
function MultiHole() {
  return React.createElement('div', null,
    React.createElement(Suspense,
      { fallback: React.createElement('p', null, 'Hole A') },
      React.createElement(Hanging)
    ),
    React.createElement('p', null, 'Static between holes'),
    React.createElement(Suspense,
      { fallback: React.createElement('p', null, 'Hole B') },
      React.createElement(Hanging)
    )
  );
}

console.log('React version:', React.version);

await renderAndInspect('1. Fully sync (no Suspense)',
  React.createElement(SyncApp));

await renderAndInspect('2. Sync inside Suspense',
  React.createElement(SyncWithSuspense));

await renderAndInspect('3. Async (resolves) inside Suspense',
  React.createElement(AsyncResolved));

await renderAndInspect('4. Dynamic hole (abort at 100ms)',
  React.createElement(WithDynamicHole), 100);

await renderAndInspect('5. Mixed — resolved parent + dynamic child (abort at 100ms)',
  React.createElement(MixedApp), 100);

await renderAndInspect('6. Multiple dynamic holes (abort at 100ms)',
  React.createElement(MultiHole), 100);
