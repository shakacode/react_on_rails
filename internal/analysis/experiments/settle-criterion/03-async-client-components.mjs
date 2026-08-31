/**
 * Experiment 3: Async Components with Mixed Sync/Async Children
 * ===============================================================
 * Question: When an async component contains a mix of sync children,
 * async children (at different delays), and Suspense boundaries at
 * various depths, what does abort timing produce?
 *
 * Setup:
 *   <App>
 *     <Header /> (sync — always in shell)
 *     <Suspense fallback="Main loading...">
 *       <AsyncLayout> (resolves 20ms)
 *         <Sidebar /> (sync child of AsyncLayout)
 *         <Suspense fallback="Content loading...">
 *           <AsyncContent> (resolves 40ms after layout)
 *             <Suspense fallback="Comments loading...">
 *               <AsyncComments> (resolves 60ms after content)
 *                 <Suspense fallback="Replies loading...">
 *                   <HangingReplies /> (never resolves — dynamic)
 *                 </Suspense>
 *               </AsyncComments>
 *             </Suspense>
 *           </AsyncContent>
 *         </Suspense>
 *       </AsyncLayout>
 *     </Suspense>
 *     <Footer /> (sync — always in shell)
 *   </App>
 *
 * Test: Abort at various times and observe which fallbacks appear.
 */

import React, { Suspense } from 'react';
import ReactDOMServer from 'react-dom/static';

let log = [];
let t0;
const mark = (msg) => {
  log.push(`[${Date.now() - t0}ms] ${msg}`);
};

function Header() {
  return React.createElement('header', null, '[Header]');
}

function Footer() {
  return React.createElement('footer', null, '[Footer]');
}

function Sidebar() {
  return React.createElement('aside', null, '[Sidebar]');
}

async function AsyncLayout({ children }) {
  await new Promise(r => setTimeout(r, 20));
  mark('AsyncLayout resolved');
  return React.createElement('div', { className: 'layout' }, '[Layout]', children);
}

async function AsyncContent({ children }) {
  await new Promise(r => setTimeout(r, 40));
  mark('AsyncContent resolved');
  return React.createElement('main', null, '[Content]', children);
}

async function AsyncComments({ children }) {
  await new Promise(r => setTimeout(r, 60));
  mark('AsyncComments resolved');
  return React.createElement('section', null, '[Comments]', children);
}

async function HangingReplies() {
  await new Promise(() => {}); // never resolves
  return React.createElement('div', null, 'NEVER');
}

function App() {
  return React.createElement(
    'div',
    null,
    React.createElement(Header),
    React.createElement(
      Suspense,
      { fallback: React.createElement('p', null, 'Main loading...') },
      React.createElement(
        AsyncLayout,
        null,
        React.createElement(Sidebar),
        React.createElement(
          Suspense,
          { fallback: React.createElement('p', null, 'Content loading...') },
          React.createElement(
            AsyncContent,
            null,
            React.createElement(
              Suspense,
              { fallback: React.createElement('p', null, 'Comments loading...') },
              React.createElement(
                AsyncComments,
                null,
                React.createElement(
                  Suspense,
                  { fallback: React.createElement('p', null, 'Replies loading...') },
                  React.createElement(HangingReplies)
                )
              )
            )
          )
        )
      )
    ),
    React.createElement(Footer)
  );
}

async function run(label, delayMs) {
  log = [];
  t0 = Date.now();
  const ac = new AbortController();
  setTimeout(() => ac.abort(), delayMs);

  const { prelude } = await ReactDOMServer.prerender(
    React.createElement(App),
    { signal: ac.signal }
  );

  const reader = prelude.getReader();
  const chunks = [];
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(new TextDecoder().decode(value));
  }
  const html = chunks.join('');

  const markers = [
    'Header', 'Footer', 'Sidebar', 'Layout', 'Content', 'Comments',
    'Main loading...', 'Content loading...', 'Comments loading...', 'Replies loading...'
  ];

  console.log(`\n=== ${label} (abort at ${delayMs}ms) ===`);
  console.log(`Timeline: ${log.join(', ') || '(nothing resolved)'}`);
  console.log('Markers found:');
  for (const m of markers) {
    if (html.includes(m)) console.log(`  ✓ "${m}"`);
  }
  console.log('Markers NOT found:');
  for (const m of markers) {
    if (!html.includes(m)) console.log(`  ✗ "${m}"`);
  }
  console.log(`\nFull HTML:\n${html}\n`);
}

console.log('============================================================');
console.log('EXPERIMENT 3: Complex Nested Async Tree');
console.log('React version:', React.version);
console.log('============================================================');

// Timeline: Layout@20ms, Content@60ms, Comments@120ms
await run('A: Abort at 5ms (nothing resolved)',    5);
await run('B: Abort at 30ms (Layout only)',        30);
await run('C: Abort at 80ms (Layout+Content)',     80);
await run('D: Abort at 150ms (all resolved)',     150);
await run('E: Abort at 300ms (well past settle)', 300);
