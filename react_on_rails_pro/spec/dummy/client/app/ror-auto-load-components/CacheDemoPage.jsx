import React, { Suspense } from 'react';
import { unstable_cache } from 'react-on-rails-pro/cache'; // eslint-disable-line camelcase

const formatTimestamp = () => new Date().toISOString();

// --- Edge case 1: Indefinite cache (revalidate: 0) ---
// This timestamp should never change once cached (until process restart).
const getIndefiniteTimestamp = unstable_cache(async () => formatTimestamp(), {
  id: 'indefinite-timestamp',
  revalidate: 0,
});

// --- Edge case 2: Short TTL cache (revalidate: 10) ---
// This timestamp should change after 10 seconds.
const getShortTTLTimestamp = unstable_cache(async () => formatTimestamp(), {
  id: 'short-ttl-timestamp',
  revalidate: 10,
});

// --- Edge case 3: Distinct args produce distinct cache entries ---
// Same function, different arguments → separate cache keys.
const getTimestampForItem = unstable_cache(async (itemId) => ({ itemId, timestamp: formatTimestamp() }), {
  id: 'item-timestamp',
  revalidate: 60,
});

// --- Edge case 4: Sync function wrapped in unstable_cache ---
// The wrapped function doesn't have to be async.
const getSyncValue = unstable_cache(
  (label) => (
    <span>
      Sync value for &quot;{label}&quot; at {formatTimestamp()}
    </span>
  ),
  { id: 'sync-value', revalidate: 30 },
);

// --- Edge case 5: Nested cached components ---
// Parent and child both use unstable_cache independently.
const getChildContent = unstable_cache(async () => `Child cached at ${formatTimestamp()}`, {
  id: 'nested-child',
  revalidate: 15,
});

const getParentContent = unstable_cache(async () => `Parent cached at ${formatTimestamp()}`, {
  id: 'nested-parent',
  revalidate: 30,
});

// --- Edge case 6: Suspense + cache ---
// Async cached function inside a Suspense boundary with simulated delay.
const getSlowData = unstable_cache(
  async () => {
    await new Promise((resolve) => {
      setTimeout(resolve, 500);
    });
    return { message: 'Slow data loaded', timestamp: formatTimestamp() };
  },
  { id: 'slow-data', revalidate: 20 },
);

const SlowDataSection = async () => {
  const data = await getSlowData();
  return (
    <div>
      <p>
        <strong>Message:</strong> {data.message}
      </p>
      <p>
        <strong>Cached at:</strong> <code>{data.timestamp}</code>
      </p>
      <p className="hint">First load takes ~500ms (MISS). Subsequent loads are instant (HIT). TTL: 20s.</p>
    </div>
  );
};

// --- Edge case 7: Multiple calls with complex args ---
const getComplexArgsResult = unstable_cache(
  async (config) => ({
    receivedConfig: config,
    timestamp: formatTimestamp(),
  }),
  { id: 'complex-args', revalidate: 60 },
);

const CacheDemoPage = async () => {
  const uncachedTimestamp = formatTimestamp();

  const indefiniteTs = await getIndefiniteTimestamp();
  const shortTTLTs = await getShortTTLTimestamp();
  const item1 = await getTimestampForItem('item-1');
  const item2 = await getTimestampForItem('item-2');
  const item1Again = await getTimestampForItem('item-1');
  const syncResult = await getSyncValue('demo');
  const parentContent = await getParentContent();
  const childContent = await getChildContent();
  const complexResult = await getComplexArgsResult({ page: 1, sort: 'date', filter: { active: true } });

  return (
    <div style={{ fontFamily: 'system-ui, sans-serif', maxWidth: 800, margin: '0 auto', padding: 20 }}>
      <h1>unstable_cache Demo</h1>
      <p>
        <strong>Current server time (uncached):</strong> <code>{uncachedTimestamp}</code>
      </p>
      <p style={{ color: '#666', fontSize: 14 }}>
        Compare this with the cached timestamps below. Matching timestamps = cache HIT.
      </p>

      <hr />

      <section>
        <h2>1. Indefinite Cache (revalidate: 0)</h2>
        <p>
          <strong>Cached at:</strong> <code>{String(indefiniteTs)}</code>
        </p>
        <p className="hint">This value never expires. It stays the same until the Node renderer restarts.</p>
      </section>

      <hr />

      <section>
        <h2>2. Short TTL Cache (revalidate: 10s)</h2>
        <p>
          <strong>Cached at:</strong> <code>{String(shortTTLTs)}</code>
        </p>
        <p className="hint">Refresh after 10 seconds to see a new timestamp (cache expired).</p>
      </section>

      <hr />

      <section>
        <h2>3. Distinct Args → Distinct Entries</h2>
        <p>
          <strong>item-1 (first call):</strong> <code>{item1.timestamp}</code>
        </p>
        <p>
          <strong>item-2:</strong> <code>{item2.timestamp}</code>
        </p>
        <p>
          <strong>item-1 (second call):</strong> <code>{item1Again.timestamp}</code>
        </p>
        <p className="hint">
          item-1 timestamps should match (same cache entry). item-2 may differ (separate entry). TTL: 60s.
        </p>
      </section>

      <hr />

      <section>
        <h2>4. Sync Function in unstable_cache</h2>
        <p>{syncResult}</p>
        <p className="hint">The wrapped function returns a ReactNode synchronously. TTL: 30s.</p>
      </section>

      <hr />

      <section>
        <h2>5. Nested Cached Components</h2>
        <p>
          <strong>Parent (TTL 30s):</strong> <code>{String(parentContent)}</code>
        </p>
        <p>
          <strong>Child (TTL 15s):</strong> <code>{String(childContent)}</code>
        </p>
        <p className="hint">Child expires before parent. After 15s, only the child timestamp changes.</p>
      </section>

      <hr />

      <section>
        <h2>6. Suspense + Cache (500ms simulated delay)</h2>
        <Suspense fallback={<div>Loading slow data...</div>}>
          <SlowDataSection />
        </Suspense>
      </section>

      <hr />

      <section>
        <h2>7. Complex Object Args</h2>
        <p>
          <strong>Received config:</strong>
        </p>
        <pre style={{ background: '#f5f5f5', padding: 10, borderRadius: 4 }}>
          {JSON.stringify(complexResult.receivedConfig, null, 2)}
        </pre>
        <p>
          <strong>Cached at:</strong> <code>{complexResult.timestamp}</code>
        </p>
        <p className="hint">Object args are JSON-serialized into the cache key. TTL: 60s.</p>
      </section>
    </div>
  );
};

export default CacheDemoPage;
