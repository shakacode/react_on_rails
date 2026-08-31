/**
 * Experiment 14: prerender() vs renderToPipeableStream()
 * ========================================================
 * Shows the difference between the two React DOM APIs:
 *   - prerender() → returns prelude + postponed (PPR)
 *   - renderToPipeableStream() → streams everything
 *
 * With the same component tree, we compare:
 *   A) prerender() aborted after 100ms → static shell + postponed state
 *   B) renderToPipeableStream() left to run → streams everything including
 *      resolved content after Suspense boundaries
 */

import React, { Suspense } from 'react';
import ReactDOMStaticServer from 'react-dom/static';
import ReactDOMStreamServer from 'react-dom/server';
import { PassThrough } from 'stream';

async function SlowContent() {
  await new Promise(r => setTimeout(r, 50));
  return React.createElement('p', null, '[Slow content resolved after 50ms]');
}

async function Hanging() {
  await new Promise(() => {});
  return null;
}

function App() {
  return React.createElement('div', null,
    React.createElement('h1', null, 'Shell'),
    React.createElement(Suspense,
      { fallback: React.createElement('p', null, 'Loading slow...') },
      React.createElement(SlowContent)
    ),
    React.createElement(Suspense,
      { fallback: React.createElement('p', null, 'Loading dynamic...') },
      React.createElement(Hanging)
    )
  );
}

console.log('React version:', React.version);

// ---- A: prerender() with abort ----
{
  const controller = new AbortController();
  setTimeout(() => controller.abort(), 100);

  const { prelude, postponed } = await ReactDOMStaticServer.prerender(
    React.createElement(App),
    { signal: controller.signal }
  );

  const reader = prelude.getReader();
  const chunks = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(new TextDecoder().decode(value));
  }
  const html = chunks.join('');

  console.log('\n' + '='.repeat(60));
  console.log('A: prerender() — aborted at 100ms');
  console.log('='.repeat(60));
  console.log(`Postponed: ${postponed != null}`);
  console.log(`Has "Slow content resolved": ${html.includes('Slow content resolved')}`);
  console.log(`Has "Loading slow...": ${html.includes('Loading slow...')}`);
  console.log(`Has "Loading dynamic...": ${html.includes('Loading dynamic...')}`);
  console.log(`\nPrelude HTML:\n${html}`);
  console.log('\n→ The prelude is the STATIC SHELL. Resolved Suspense boundaries');
  console.log('  are inlined. Unresolved boundaries become postponed holes.');
  console.log('  The postponed state is an opaque object for React.resume().');
}

// ---- B: renderToPipeableStream() ----
{
  console.log('\n' + '='.repeat(60));
  console.log('B: renderToPipeableStream() — no abort, full stream');
  console.log('='.repeat(60));

  const controller = new AbortController();
  // Abort only the hanging component after collecting output
  setTimeout(() => controller.abort(), 200);

  const pt = new PassThrough();
  const allChunks = [];

  pt.on('data', chunk => allChunks.push(chunk.toString()));

  const { pipe } = ReactDOMStreamServer.renderToPipeableStream(
    React.createElement(App),
    {
      onShellReady() {
        console.log(`  [onShellReady] Shell is ready, piping...`);
        pipe(pt);
      },
      onAllReady() {
        console.log(`  [onAllReady] Everything resolved (won't fire with hanging)`);
      },
      onShellError(err) {
        console.log(`  [onShellError] ${err.message}`);
      },
      onError(err) {
        // Suppress abort errors
      },
    }
  );

  // Wait for the shell + slow content to stream
  await new Promise(r => setTimeout(r, 150));
  controller.abort();
  await new Promise(r => setTimeout(r, 50));
  pt.end();

  const fullHtml = allChunks.join('');
  console.log(`Has "Slow content resolved": ${fullHtml.includes('Slow content resolved')}`);
  console.log(`Has "Loading slow...": ${fullHtml.includes('Loading slow...')}`);
  console.log(`Has "$RC" (Suspense reveal script): ${fullHtml.includes('$RC')}`);
  console.log(`\nFull streamed HTML:\n${fullHtml}`);
  console.log('\n→ renderToPipeableStream STREAMS everything:');
  console.log('  1. Shell first (with fallbacks for pending boundaries)');
  console.log('  2. Then resolved content in hidden divs + replacement scripts');
  console.log('  3. Scripts like $RC swap fallbacks with real content');
}
