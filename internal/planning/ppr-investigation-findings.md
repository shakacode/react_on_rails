# Partial Pre-rendering (PPR) Investigation Findings

**Date**: 2026-05-18
**Status**: Research Phase
**Related Issue**: #3311

## Executive Summary

This document summarizes our investigation into Partial Pre-rendering (PPR) for React Server Components. The goal is to understand how PPR can be implemented in React on Rails Pro to enable instant page loads with streaming dynamic content.

### Key Findings

1. **PPR requires a two-layer architecture**: RSC (flight data) layer and Fizz (HTML) layer work independently
2. **RSC prerender has NO postpone/resume capability**: Unlike the Fizz layer, RSC must execute all components
3. **Everything re-renders by default**: Components without explicit caching re-execute on every request
4. **The `"use cache"` directive is essential**: It's the only mechanism to prevent component re-execution
5. **Hanging promises create dynamic boundaries**: Components awaiting request-time data suspend indefinitely during prerender

---

## 1. The Two-Layer Architecture

PPR implementations require coordinating two separate rendering layers:

### Layer 1: RSC (React Server Components)

- Generates flight data (serialized component output)
- Uses `react-server-dom-webpack` package
- `prerender()` returns `{ prelude }` only — **NO postponed state**
- Must execute ALL component functions to serialize output

### Layer 2: Fizz (HTML Generation)

- Generates HTML from React elements
- Uses `react-dom/static` and `react-dom/server` packages
- `prerender()` returns `{ prelude, postponed }` — **CAN be resumed**
- Supports postpone/resume pattern for partial rendering

### Architecture Diagram

```
BUILD TIME:
┌─────────────────────────────────────────────────────────────────────────┐
│ RSC Layer: Executes ALL components → Flight data                        │
│     │                                                                    │
│     ↓                                                                    │
│ Fizz Layer: prerender() → { HTML prelude, postponed state }             │
│                                                                          │
│ STORED: HTML shell + postponed state + flight data                      │
└─────────────────────────────────────────────────────────────────────────┘

REQUEST TIME:
┌─────────────────────────────────────────────────────────────────────────┐
│ RSC Layer: Re-executes ALL components → Fresh flight data               │
│     │      ("use cache" prevents execution via cache lookup)            │
│     ↓                                                                    │
│ Fizz Layer: resume(postponed) → Only renders dynamic parts              │
│                                                                          │
│ RESULT: Static HTML merged with dynamic HTML + fresh flight data        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. RSC vs Fizz Prerender APIs

| API           | Package                         | Returns                  | Postpone Support           | Resume Support |
| ------------- | ------------------------------- | ------------------------ | -------------------------- | -------------- |
| `prerender()` | react-server-dom-webpack/static | `{ prelude }`            | `onPostpone` callback only | **NO**         |
| `prerender()` | react-dom/static                | `{ prelude, postponed }` | **YES**                    | **YES**        |

### Critical Insight

> **PPR at the RSC layer is not directly supported by current React architecture.**
>
> RSC prerender returns only `{ prelude }` with no way to resume. The RSC layer must execute ALL components on every request unless caching is explicitly implemented.

---

## 3. Default Behavior: Everything Re-renders

Without explicit caching, ALL components (sync or async) re-execute on EVERY request:

### Experimental Evidence

We tested various component types across multiple requests:

| Component Type           | Cache Directive | Render Count (3 requests)   |
| ------------------------ | --------------- | --------------------------- |
| Sync pure component      | none            | 3 (every request)           |
| Sync with side effects   | none            | 3 (every request)           |
| Async without directive  | none            | 3 (every request)           |
| Async with `"use cache"` | `"use cache"`   | 0 (served from cache)       |
| Sync with `"use cache"`  | `"use cache"`   | 0 (served from cache)       |
| Cached function          | `"use cache"`   | 1 (cached after first call) |

### Server Log Evidence

```
Request 1:
[RENDER] StaticSibling - count: 1
[RENDER] DynamicComponent - count: 1

Request 2:
[RENDER] StaticSibling - count: 2  ← Re-executed!
[RENDER] DynamicComponent - count: 2

Request 3:
[RENDER] StaticSibling - count: 3  ← Re-executed again!
[RENDER] DynamicComponent - count: 3
```

### Key Insight

There is NO automatic "static shell" detection based on component type or content. The mental model is:

> **"Dynamic by default, opt-in caching with `use cache`"**

---

## 4. The `"use cache"` Directive

The `"use cache"` directive is essential for PPR performance. Other RSC frameworks implement this as a build-time transformation.

### How It Works

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Call: CachedComponent()                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. Generate cache key from:                                            │
│     - Function identifier (hash)                                        │
│     - Serialized arguments                                              │
│                                                                          │
│  2. Check cache:                                                        │
│     │                                                                    │
│     ├─ HIT: Return cached RSC payload                                   │
│     │   └─ Component function NOT executed!                             │
│     │                                                                    │
│     └─ MISS: Execute original function                                  │
│         ├─ Serialize result to RSC flight format                        │
│         └─ Store in cache with configured lifetime                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Cache Storage Format

The cached value is **serialized RSC flight data**, not the raw function result:

```
0:["$","div",null,{"children":["Time: ","2026-05-18T07:23:18.052Z"]}]
```

### Build-Time Transformation

Other RSC frameworks transform `"use cache"` components at build time:

```tsx
// Source
async function CachedComponent() {
  'use cache';
  const data = await fetchData();
  return <div>{data}</div>;
}

// Transformed (conceptual)
async function CachedComponent() {
  const cacheKey = computeCacheKey(CachedComponent, arguments);

  const cached = await cache.get(cacheKey);
  if (cached) return cached;

  const result = await originalFunction();
  await cache.set(cacheKey, result);
  return result;
}
```

---

## 5. The Hanging Promise Mechanism

To create dynamic boundaries during prerender, frameworks use "hanging promises" — promises that never resolve naturally:

```typescript
function makeHangingPromise<T>(signal: AbortSignal, expression: string): Promise<T> {
  return new Promise<T>((_, reject) => {
    signal.addEventListener('abort', () => {
      reject(new Error(`${expression} rejects when prerender completes.`));
    });
  });
}
```

### How It Works

1. Dynamic APIs (cookies, headers, request data) return hanging promises during prerender
2. Components awaiting these promises suspend indefinitely
3. When all caches are filled, the AbortController signals completion
4. Hanging promises reject, marking those components as "dynamic holes"

---

## 6. CacheSignal: Coordinating Cache Completion

Other RSC frameworks use a signal mechanism to track when all cached components finish:

```typescript
class CacheSignal {
  private pendingCacheReads = 0;
  private resolvers: Array<() => void> = [];

  beginRead() {
    this.pendingCacheReads++;
  }

  endRead() {
    this.pendingCacheReads--;
    if (this.pendingCacheReads === 0) {
      this.resolvers.forEach((resolve) => resolve());
    }
  }

  cacheReady(): Promise<void> {
    if (this.pendingCacheReads === 0) return Promise.resolve();
    return new Promise((resolve) => this.resolvers.push(resolve));
  }
}
```

### Prerender Flow

```typescript
const controller = new AbortController();
const cacheSignal = new CacheSignal();

// Start prerender
const { prelude } = await prerenderToNodeStream(<App />, {
  signal: controller.signal,
});

// Wait for all caches to fill
await cacheSignal.cacheReady();

// Signal completion - hanging promises reject
controller.abort();
```

---

## 7. Streaming Protocol

The browser receives HTML with placeholders, then JavaScript chunks fill them:

```html
<!-- 1. Initial HTML with placeholders -->
<main>
  <div>Cached content from build</div>
  <template id="B:0"></template>
  <div data-fallback>Loading...</div>
</main>

<!-- 2. Streamed chunks as dynamic components complete -->
<script>
  $RC('B:0', '<div>Dynamic content</div>');
</script>
```

The `$RC` function (provided by React) replaces placeholders:

```javascript
function $RC(id, html) {
  const template = document.getElementById(id);
  const fallback = template.nextSibling;
  const content = parseHTML(html);
  fallback.replaceWith(content);
  template.remove();
}
```

---

## 8. Constraints and Limitations

### Non-Deterministic Operations

Operations like `Date.now()`, `Math.random()`, `crypto.randomUUID()` in non-cached components cause build errors. They must be explicitly handled:

- **Option A**: Cache the value with `"use cache"`
- **Option B**: Mark as dynamic (defer to request time)

### No Dynamic APIs Inside Cached Components

You cannot use request-time APIs inside a cached component or its children:

```tsx
// ERROR!
async function CachedParent() {
  'use cache';
  return <DynamicChild />; // DynamicChild uses cookies() - fails!
}
```

### Nested Caching

Nested `"use cache"` components are cached independently with separate cache entries.

---

## 9. Summary: What We've Learned

| Aspect             | Finding                                        |
| ------------------ | ---------------------------------------------- |
| Static detection   | None — all components dynamic by default       |
| Caching mechanism  | `"use cache"` directive only                   |
| RSC resumption     | Not supported — must re-execute all components |
| Fizz resumption    | Supported via `postponed` state                |
| Build HTML         | Not served at runtime — page re-renders        |
| Cache format       | Serialized RSC flight data                     |
| Dynamic boundaries | Created via hanging promises                   |
| Coordination       | CacheSignal tracks cache completion            |

---

## 10. Open Questions Requiring Further Investigation

### 10.1 RSC Payload Generation with Partial Prerendering

**Problem**: We have not found a specific API that integrates partial prerendering with `renderToPipeableStream` in `react-server-dom-webpack`.

**Current Understanding**:

- `react-server-dom-webpack/static.prerender()` returns only `{ prelude }` with no postponed state
- The RSC layer has no built-in mechanism to skip component execution
- Other frameworks work around this by implementing caching at the framework level

**Investigation Needed**:

- How can we avoid running server components on every rendering request?
- Is there a way to serialize and restore partial RSC state?
- Should we implement our own caching layer similar to other frameworks?

### 10.2 Implementing the `"use cache"` Directive

**Problem**: The `"use cache"` directive requires:

1. Build-time code transformation (SWC/Babel plugin)
2. Runtime cache wrapper implementation
3. Cache storage backend integration
4. CacheSignal coordination mechanism

**Investigation Needed**:

- What build tooling changes are required for React on Rails?
- How should the cache wrapper integrate with Rails caching?
- What cache invalidation strategies should we support?
- How do we handle cache key generation with Rails-specific context?

---

## References

- React Server Components RFC
- React DOM Server API documentation
- `react-server-dom-webpack` package source
- `react-dom/static` prerender API

---

_This document represents findings from May 2026. React and RSC APIs may evolve._
