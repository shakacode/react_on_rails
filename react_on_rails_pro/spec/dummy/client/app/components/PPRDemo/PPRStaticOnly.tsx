/* PPR demo — fully static page. usePostpone is never called → postponedState comes back null
 * from prerender, the cache stores only the shell, and resume is skipped at the helper level.
 * This is the optimal PPR case: every request after the first reads the shell directly. */
import React, { Suspense } from 'react';

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

const FastSection = async () => {
  await sleep(50);
  return <p data-testid="ppr-static-only-fast">Fast section (50ms).</p>;
};

const SlowSection = async () => {
  await sleep(1500);
  return <p data-testid="ppr-static-only-slow">Slow section (1.5s).</p>;
};

const PPRStaticOnly: React.FC = () => (
  <main
    data-testid="ppr-static-only-root"
    style={{ fontFamily: 'system-ui, sans-serif', maxWidth: 720, margin: '0 auto' }}
  >
    <h1>PPR — Fully Static Page</h1>
    <p>No usePostpone() calls anywhere. After the first hit, this page is served entirely from cache.</p>
    <Suspense fallback={<p>Loading fast section…</p>}>
      <FastSection />
    </Suspense>
    <Suspense fallback={<p>Loading slow section…</p>}>
      <SlowSection />
    </Suspense>
    <p data-testid="ppr-static-only-sync">Synchronous content — always in the shell.</p>
  </main>
);

export default PPRStaticOnly;
