import React, { Suspense } from 'react';
// eslint-disable-next-line camelcase -- matches Next.js API naming convention
import { unstable_cache } from 'react-on-rails-pro/cache';

const getCachedTimestamp = unstable_cache(
  (label: string) => (
    <span data-testid={`cached-${label}`}>
      {label}: {new Date().toISOString()}
    </span>
  ),
  { id: 'timestamp', tags: ['timestamps'] },
);

const getCachedWithTTL = unstable_cache(
  () => <span data-testid="ttl-value">TTL value: {new Date().toISOString()} (revalidates every 5s)</span>,
  { id: 'ttl-timestamp', revalidate: 5 },
);

const getCachedProduct = unstable_cache(
  (productId: number) => (
    <span data-testid={`product-${productId}`}>
      Product #{productId} rendered at {new Date().toISOString()}
    </span>
  ),
  { id: 'product', tags: ['products'] },
);

const CachedSection = async () => {
  const ts1 = await getCachedTimestamp('alpha');
  const ts2 = await getCachedTimestamp('beta');
  const ttlValue = await getCachedWithTTL();
  const product1 = await getCachedProduct(1);
  const product2 = await getCachedProduct(2);

  return (
    <div>
      <h2>Cached Results</h2>
      <p>These timestamps stay the same across refreshes (until the cache is invalidated).</p>
      <ul>
        <li>{ts1}</li>
        <li>{ts2}</li>
      </ul>

      <h3>TTL-based Revalidation</h3>
      <p>{ttlValue}</p>

      <h3>Cached by Argument (tag: products)</h3>
      <ul>
        <li>{product1}</li>
        <li>{product2}</li>
      </ul>
    </div>
  );
};

const UncachedSection = async () => {
  // eslint-disable-next-line no-promise-executor-return
  await new Promise((resolve) => setTimeout(resolve, 10));
  return (
    <div>
      <h2>Uncached (For Comparison)</h2>
      <p>This timestamp changes on every request:</p>
      <p data-testid="uncached-timestamp">{new Date().toISOString()}</p>
    </div>
  );
};

const CacheDemoPage = () => (
  <div>
    <h1>unstable_cache Demo</h1>
    <p>
      This page demonstrates <code>unstable_cache</code> from React on Rails Pro. Cached sections retain their
      timestamps across page refreshes. Uncached sections produce fresh timestamps on every render.
    </p>
    <hr />
    <Suspense fallback={<div>Loading cached content...</div>}>
      <CachedSection />
    </Suspense>
    <hr />
    <Suspense fallback={<div>Loading uncached content...</div>}>
      <UncachedSection />
    </Suspense>
  </div>
);

export default CacheDemoPage;
