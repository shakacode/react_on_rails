/**
 * Experiment 15: Prerender → Postpone → Resume
 * ===============================================
 * Demonstrates the complete PPR lifecycle:
 *   1. prerender() produces a static shell + postponed state
 *   2. resume() fills in the dynamic holes at request time
 *
 * This is the core of PPR: build-time prerender + request-time resume.
 */

import React, { Suspense } from 'react';
import ReactDOMStaticServer from 'react-dom/static';
import ReactDOMStreamServer from 'react-dom/server';
import { PassThrough } from 'stream';

// Simulates a dynamic component (e.g., reads cookies)
let requestData = null;

async function UserGreeting() {
  // During prerender: hangs (no user data available)
  // During resume: resolves with the user's name
  if (requestData === null) {
    await new Promise(() => {}); // hang during prerender
  }
  return React.createElement('p', null, `Hello, ${requestData.name}!`);
}

function App() {
  return React.createElement('html', null,
    React.createElement('body', null,
      React.createElement('div', null,
        React.createElement('h1', null, 'My App'),
        React.createElement('nav', null, 'Home | About | Contact'),
        React.createElement(Suspense,
          { fallback: React.createElement('p', null, '👤 Loading user...') },
          React.createElement(UserGreeting)
        ),
        React.createElement('footer', null, '© 2024 MyApp')
      )
    )
  );
}

console.log('React version:', React.version);

// ---- Step 1: Build-time prerender ----
console.log('\n' + '='.repeat(60));
console.log('STEP 1: Build-time prerender (no user data)');
console.log('='.repeat(60));

requestData = null; // no user during build

const controller = new AbortController();
setTimeout(() => controller.abort(), 100);

const { prelude, postponed } = await ReactDOMStaticServer.prerender(
  React.createElement(App),
  { signal: controller.signal }
);

const reader = prelude.getReader();
const preludeChunks = [];
while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  preludeChunks.push(new TextDecoder().decode(value));
}
const shellHtml = preludeChunks.join('');

console.log(`Postponed state exists: ${postponed != null}`);
console.log(`Shell includes "My App": ${shellHtml.includes('My App')}`);
console.log(`Shell includes nav: ${shellHtml.includes('Home | About | Contact')}`);
console.log(`Shell includes footer: ${shellHtml.includes('© 2024 MyApp')}`);
console.log(`Shell includes user greeting: ${shellHtml.includes('Hello,')}`);
console.log(`Shell includes loading fallback: ${shellHtml.includes('Loading user...')}`);

console.log(`\nStatic shell (cached at build time):\n${shellHtml}`);

// ---- Step 2: Request-time resume ----
console.log('\n' + '='.repeat(60));
console.log('STEP 2: Request-time resume (with user "Abanoub")');
console.log('='.repeat(60));

requestData = { name: 'Abanoub' }; // real user at request time

if (postponed) {
  const pt = new PassThrough();
  const resumeChunks = [];
  pt.on('data', chunk => resumeChunks.push(chunk.toString()));

  const { pipe } = ReactDOMStreamServer.resumeToPipeableStream(
    React.createElement(App),
    postponed,
    {
      onShellReady() {
        pipe(pt);
      },
      onError(err) {
        // suppress
      },
    }
  );

  await new Promise(r => setTimeout(r, 200));
  pt.end();

  const resumeHtml = resumeChunks.join('');
  console.log(`Resume output includes "Hello, Abanoub!": ${resumeHtml.includes('Hello, Abanoub!')}`);
  console.log(`Resume includes replacement script ($RC): ${resumeHtml.includes('$RC')}`);

  console.log(`\nResume stream (sent at request time):\n${resumeHtml}`);

  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log(`
The complete page the user sees is assembled from TWO pieces:

1. STATIC SHELL (cached, served instantly):
   - <h1>My App</h1>
   - <nav>Home | About | Contact</nav>
   - 👤 Loading user...  ← fallback placeholder
   - <footer>© 2024 MyApp</footer>

2. RESUME STREAM (generated per-request, streamed in):
   - Hello, Abanoub!     ← replaces the fallback
   - Replacement script  ← $RC swaps fallback → real content

The browser shows the shell instantly (fast TTFB/LCP),
then the resume stream swaps in the dynamic content.
`);
} else {
  console.log('No postponed state — page was fully static!');
}
