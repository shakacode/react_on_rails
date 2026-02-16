// HelloServer - React Server Component
//
// This component runs ONLY on the server. No JavaScript for it is sent to the browser.
// It demonstrates key RSC capabilities:
//
// 1. Async data fetching — use await directly in the component (no useEffect needed)
// 2. Server-only code — access databases, file systems, or secrets safely
// 3. Zero client JS — heavy libraries used here don't increase your bundle size
// 4. Streaming — wrapped in <Suspense>, this component streams HTML as it resolves
//
// For more information, see:
// https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/

import React from 'react';
import LikeButton from './LikeButton';

// Simulate an async data fetch (replace with a real API call or DB query)
async function fetchGreeting(name) {
  // In a real app, you could do:
  //   const data = await db.query('SELECT greeting FROM greetings WHERE name = ?', [name]);
  //   const file = await fs.readFile('./data/greeting.txt', 'utf-8');
  //   const res = await fetch('http://internal-api/greeting');
  // eslint-disable-next-line no-promise-executor-return
  await new Promise((resolve) => setTimeout(resolve, 100));

  const now = new Date();
  return {
    message: `Hello, ${name}!`,
    serverTime: now.toLocaleString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      timeZoneName: 'short',
    }),
    facts: [
      'This component rendered entirely on the server — zero JS was sent to the browser for it.',
      'The date formatting above used server-side Intl APIs — no date library shipped to the client.',
      'The "Like" button below IS a client component — only its JS is sent to the browser.',
    ],
  };
}

const HelloServer = async ({ name = 'World' }) => {
  const { message, serverTime, facts } = await fetchGreeting(name);

  return (
    <div style={{ fontFamily: 'system-ui, sans-serif', maxWidth: 600, margin: '0 auto' }}>
      <h2>{message}</h2>
      <p style={{ color: '#666', fontSize: '0.9em' }}>Server-rendered at: {serverTime}</p>

      <div
        style={{
          background: '#f0f9ff',
          border: '1px solid #bae6fd',
          borderRadius: 8,
          padding: 16,
          margin: '16px 0',
        }}
      >
        <h3 style={{ margin: '0 0 12px' }}>How is this different from SSR?</h3>
        <ul style={{ margin: 0, paddingLeft: 20 }}>
          {facts.map((fact) => (
            <li key={fact} style={{ marginBottom: 8 }}>
              {fact}
            </li>
          ))}
        </ul>
      </div>

      {/* LikeButton is a client component — it ships JS for interactivity */}
      <LikeButton />
    </div>
  );
};

export default HelloServer;
