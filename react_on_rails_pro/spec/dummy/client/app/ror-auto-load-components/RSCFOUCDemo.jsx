import React, { Suspense } from 'react';
import StyledClientCard from '../components/RSCFOUCDemo/StyledClientCard';

const wait = (ms) =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

const DelayedClientCard = async ({ artificialDelay }) => {
  if (artificialDelay > 0) {
    await wait(artificialDelay);
  }
  return <StyledClientCard message="rendered via RSC + 'use client'" />;
};

const RSCFOUCDemo = ({ artificialDelay = 0 } = {}) => (
  <div data-testid="rsc-fouc-demo-root">
    <h1>RSC FOUC Demo (issue #3211)</h1>
    <p>
      This page renders a true React Server Component tree containing a <code>&apos;use client&apos;</code>{' '}
      boundary. The client component imports a CSS Module. With the bug, the CSS only loads as a side-effect
      of the JS chunk evaluating, producing a flash-of-unstyled-content. With the fix, React on Rails Pro
      emits a stylesheet preload for each client reference and React hoists it into <code>&lt;head&gt;</code>{' '}
      with a<code>data-precedence</code> attribute.
    </p>
    <Suspense fallback={<p data-testid="styled-client-card-fallback">loading client card...</p>}>
      <DelayedClientCard artificialDelay={artificialDelay} />
    </Suspense>
  </div>
);

export default RSCFOUCDemo;
