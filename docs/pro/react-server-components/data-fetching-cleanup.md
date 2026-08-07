# Cancelling In-Flight Data Work with cacheSignal()

When a client disconnects during a streamed server render — whether from navigation, closing the tab, or a network timeout — React aborts the in-flight render. But any `fetch()` calls, database queries, or API requests that the render started **keep running** unless explicitly cancelled. This wastes server resources: CPU, database connections, API quotas, and memory.

React 19.2 introduces `cacheSignal()`, a cleanup primitive that solves this problem.

## The Problem: Abandoned Renders Leak Work

Consider an RSC component that fetches product data from your Rails API:

```jsx
import { cache } from 'react';

const getProduct = cache(async (id) => {
  const res = await fetch(`${process.env.RAILS_API_URL}/api/products/${id}`);
  return res.json();
});

export default async function ProductPage({ id }) {
  const product = await getProduct(id);
  return (
    <div>
      {product.name} — ${product.price}
    </div>
  );
}
```

If the client disconnects mid-stream, React on Rails Pro aborts the render — but the `fetch()` call to your Rails API continues running. The Rails controller processes the request, queries the database, serializes the response, and sends it back to the Node renderer... where nothing is listening anymore.

At scale, this means your Rails servers and database are doing work for clients that are already gone.

## The Solution: Pass `cacheSignal()` to Your Data Fetchers

`cacheSignal()` returns an `AbortSignal` scoped to the current server render. When the render ends — whether it completes successfully, is aborted (client disconnect), or fails with an error — React settles the signal. Any `fetch()` or database client using that signal is cancelled automatically.

```jsx
import { cache, cacheSignal } from 'react';

const getProduct = cache(async (id) => {
  const signal = cacheSignal();
  const res = await fetch(`${process.env.RAILS_API_URL}/api/products/${id}`, { signal });
  return res.json();
});

export default async function ProductPage({ id }) {
  const product = await getProduct(id);
  return (
    <div>
      {product.name} — ${product.price}
    </div>
  );
}
```

The only change is adding `{ signal }` to the `fetch()` call. When the client disconnects:

1. React on Rails Pro detects the disconnect and calls `PipeableStream.abort()`
2. React settles `cacheSignal()` (calls `request.cacheController.abort()`)
3. The `fetch()` throws an `AbortError` and the in-flight HTTP request is cancelled
4. Reduced wasted work — if Rails hasn't started processing the request yet, it never will; if processing has already begun, compatible server infrastructure can observe the client disconnect and stop early

## Error Handling

When the signal fires, `fetch()` and most abort-aware APIs throw an `AbortError`. You should distinguish this expected cancellation from real errors:

```jsx
const getProduct = cache(async (id) => {
  const signal = cacheSignal();
  try {
    const res = await fetch(`${process.env.RAILS_API_URL}/api/products/${id}`, { signal });
    return res.json();
  } catch (error) {
    // Check if this was an expected cancellation (render ended / client disconnected)
    if (signal?.aborted) {
      // Expected cleanup — not a real error. Return a fallback or let it propagate silently.
      return null;
    }
    // Real error — log it, rethrow, or handle
    console.error(`Failed to fetch product ${id}:`, error);
    throw error;
  }
});
```

> [!NOTE]
> Check `signal?.aborted` (with optional chaining) because `cacheSignal()` returns `null` when called outside an RSC render context.

## Database Queries

If your database client supports `AbortSignal`, pass it directly (check your client's documentation — support varies by library and version). For clients that don't support `AbortSignal` natively, listen for the abort event manually and use `try/finally` to ensure connections are always released:

```jsx
import { cache, cacheSignal } from 'react';
import { getConnection } from '../lib/db';

const getProducts = cache(async (categoryId) => {
  const signal = cacheSignal();
  const connection = await getConnection();
  const cancelQuery = () => connection.cancel();

  signal?.addEventListener('abort', cancelQuery, { once: true });
  try {
    const result = await connection.query('SELECT * FROM products WHERE category_id = $1', [categoryId]);
    return result.rows;
  } finally {
    signal?.removeEventListener('abort', cancelQuery);
    connection.release();
  }
});
```

## Caveats

- **RSC-only.** `cacheSignal()` returns `null` in Client Components and outside a server render. Always use optional chaining (`cacheSignal()?.aborted`) or a null check.

- **Cleanup-only.** The signal fires when the render _ends_ — you cannot abort it manually. It is not a request-scoped `AbortController`. If you need manual abort control, create your own `AbortController` and combine it with `cacheSignal()` via [`AbortSignal.any()`](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/any_static).

- **Requires React ≥ 19.2.** `cacheSignal()` is a React 19.2 API and is not available in earlier React versions. React on Rails Pro's RSC path runs React 19.2.7 via `react-server-dom-webpack`, so it is available in all Pro RSC components. The `null` return value indicates the call is outside an active server render, not a version issue.

- **Fires on success too.** The signal fires when the render completes _successfully_, not just on abort. This is by design — it cancels any in-flight work that was started but whose result was never consumed (e.g., a `cache()`-wrapped fetch that was started but the component tree didn't render the branch that uses it).

## How It Works in React on Rails Pro

The abort chain that makes `cacheSignal()` work was shipped in [PR #4093](https://github.com/shakacode/react_on_rails/pull/4093):

1. **Client disconnects** → Fastify `res.raw.close` event fires
2. **Node renderer worker** destroys the render source stream
3. **`cancelUpstream()`** in `streamingUtils.ts` aborts the piped render stream
4. **`cancelUpstream()`** then fires registered `onConsumerAbort` handlers
5. **`renderingStream.abort()`** (registered via `onConsumerAbort`) tells React to abort the render
6. **React internally** calls `request.cacheController.abort()` → `cacheSignal()` settles
7. **Your `fetch({ signal })`** throws `AbortError` → in-flight work cancelled

This chain works for both the HTML SSR path (`streamServerRenderedReactComponent`) and the RSC Flight path (`proRSC.ts`).

## Related

- [Sharing Per-Request Data](./per-request-data.md) — using `React.cache()` as a per-request store
- [React `cacheSignal()` reference](https://react.dev/reference/react/cacheSignal) — official React documentation
- [Streaming Server Rendering](../streaming-ssr.md) — how React on Rails Pro streams HTML
- [Issue #3885](https://github.com/shakacode/react_on_rails/issues/3885) — the tracking issue for this feature
