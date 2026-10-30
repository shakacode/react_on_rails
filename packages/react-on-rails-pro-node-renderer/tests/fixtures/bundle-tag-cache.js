// Fixture bundle for the multi-worker tag-revalidation integration test.
//
// Implements the sandbox-side contract the react-on-rails-pro package's cache
// module installs at bundle load (__REACT_ON_RAILS_REVALIDATE_TAGS__ plus a
// mark-stale cache judged against render-start timestamps), without depending
// on the package itself: the renderer only guarantees delivery INTO the
// sandbox, and this models the receiving side of that seam.
//
// __workerMark is a per-sandbox random id: each cluster worker compiles its own
// sandbox for this bundle, so distinct marks in HTTP responses prove which
// worker (and which in-memory cache) served a request.
global.ReactOnRails = { dummy: { html: 'Dummy Object' } };

global.__workerMark = `${Date.now().toString(36)}-${Math.floor(Math.random() * 1e12).toString(36)}`;

const cache = new Map();
const tagStamps = new Map();

global.__REACT_ON_RAILS_REVALIDATE_TAGS__ = (tags, invalidatedAt) => {
  for (const tag of tags) {
    // Carried origin stamp, never local receipt time; max() makes duplicate
    // and reordered deliveries idempotent.
    tagStamps.set(tag, Math.max(tagStamps.get(tag) ?? 0, invalidatedAt));
  }
  return Promise.resolve();
};

global.renderCached = (key, tag) => {
  const entry = cache.get(key);
  // >= : an invalidation in the same millisecond as the render refuses it.
  const stale = entry && (tagStamps.get(tag) ?? 0) >= entry.timestamp;
  if (entry && !stale) {
    return JSON.stringify({ mark: global.__workerMark, hit: true, value: entry.value });
  }
  const timestamp = Date.now();
  const value = `rendered-at-${timestamp}-${Math.floor(Math.random() * 1e9)}`;
  cache.set(key, { value, timestamp });
  return JSON.stringify({ mark: global.__workerMark, hit: false, value });
};
