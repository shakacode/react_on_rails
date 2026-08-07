# React APIs Deep Dive for PPR Implementation

**Date:** 2026-08-04
**Author:** Abanoub Ghadban (reference document, composed with Claude Code)
**Purpose:** Book-style explanation of every React API needed to understand and
implement PPR in React on Rails. Goes beyond the official docs with source-level
detail from `facebook/react`.

---

## Table of Contents

1. [`cache()` — Per-Request Memoization](#1-cache--per-request-memoization)
2. [`cacheSignal()` — Render Lifecycle Cleanup](#2-cachesignal--render-lifecycle-cleanup)
3. [The Flight Wire Protocol — RSC Serialization Format](#3-the-flight-wire-protocol)
4. [`renderToReadableStream` (Flight) — RSC Serialization](#4-rendertoreadablestream-flight)
5. [`prerender` (Flight) — RSC Static Prerender](#5-prerender-flight)
6. [`createFromReadableStream` / `createFromNodeStream` — Flight Deserialization](#6-createfromreadablestream--createfromnodestream)
7. [The Fizz Renderer — HTML Generation Internals](#7-the-fizz-renderer)
8. [`renderToPipeableStream` (Fizz) — Streaming SSR](#8-rendertopipeablestream-fizz)
9. [`prerenderToNodeStream` (Fizz) — Static HTML with PPR](#9-prerendertonodestream-fizz)
10. [`resumeToPipeableStream` — Resume Postponed Rendering](#10-resumetopipeablestream)
11. [`React.unstable_postpone()` — Creating Dynamic Holes](#11-reactunstable_postpone)
12. [`encodeReply` / `decodeReply` — Argument Serialization](#12-encodereply--decodereply)
13. [How These APIs Compose for PPR](#13-how-these-apis-compose-for-ppr)

---

## 1. `cache()` — Per-Request Memoization

**Import:** `import { cache } from 'react'`
**Source:** `packages/react/src/ReactCacheImpl.js`

### What It Does

`cache()` wraps a function so that calling it with the same arguments during
the same server request returns the cached result instead of re-executing. It
is **per-request memoization**, not a persistent cache.

```tsx
import { cache } from 'react';

const getUser = cache(async (id: string) => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
});

// Component A calls getUser('42') → fetches from API
// Component B calls getUser('42') → returns cached result (no fetch)
// Next request → cache is empty, fetches again
```

### How It Works Internally — The Argument Trie

Each cached function gets a **trie** (prefix tree) keyed by arguments. The
data structure is a `CacheNode`:

```
CacheNode = {
  s: number,       // status: UNTERMINATED(0), TERMINATED(1), ERRORED(2)
  v: any,          // cached value or error
  o: WeakMap,      // branches for object/function args (identity-compared, GC-friendly)
  p: Map,          // branches for primitive args (value-compared via SameValueZero)
}
```

When you call `cachedFn(arg1, arg2, arg3)`, each argument walks one level
deeper into the trie:

```
Root CacheNode
  └─ arg1 (via WeakMap if object, Map if primitive)
       └─ arg2
            └─ arg3 → leaf node
                       s: TERMINATED
                       v: <cached result>
```

At the leaf:

- `s === TERMINATED` → return `v` (cache hit)
- `s === ERRORED` → re-throw `v`
- `s === UNTERMINATED` → call the original function, set leaf to TERMINATED or ERRORED

This means:

- **Every unique argument combination** gets its own cache slot
- **All results are retained** for the request lifetime (unlike `useMemo` which
  only caches the last call)
- **Object arguments are identity-compared** (via WeakMap), so `getUser({id: 1})`
  called twice with two different object literals = two cache misses
- **Primitive arguments are value-compared** (via Map)

### Cache Scope — Per-Request, Not Global

The critical question: where does the trie live?

The resolution chain in the source:

```
cache(fn) wrapper
  → ReactSharedInternals.A           // the AsyncDispatcher
    → dispatcher.getCacheForType(createCacheRoot)
      → resolveCache()
        → resolveRequest()
          → requestStorage.getStore()  // Node.js AsyncLocalStorage
            → request.cache            // Map<Function, mixed>, created per-request
```

When the Flight server starts processing a request, it calls
`requestStorage.run(request, performWork, request)`, establishing the async
context. Every `cache()` call during that request resolves to the same
`request.cache` Map.

**Key implications:**

- The cache lives for exactly one server request, then is garbage-collected
- Two different requests never share a cache
- Two different `cache(fn)` calls on the same `fn` do **not** share a cache
  (they get separate wrapper functions with separate closures)
- Outside a render context (`ReactSharedInternals.A === null`), the wrapper
  just calls `fn` directly with no caching
- WeakMap branches are GC'd when argument objects become unreachable;
  Map branches (primitives) persist for the request lifetime

### What `cache()` Is NOT

- **Not a persistent cache.** It does not survive across requests. For that,
  you need `"use cache"` (which uses a `CacheHandler` backend).
- **Not `useMemo`.** `useMemo` is a hook that runs during client rendering and
  caches the last result. `cache()` runs on the server and caches all results
  for the request.
- **Not `React.memo`.** `React.memo` skips re-rendering when props haven't
  changed. `cache()` skips re-executing a function when arguments haven't
  changed.

### The Relationship to `"use cache"`

`cache()` is a **deduplication primitive** — it prevents the same function from
being called twice with the same arguments during a single render.

`"use cache"` is a **persistence mechanism** — it stores RSC byte blobs across
requests in a `CacheHandler` backend (memory, Redis, etc.).

In practice, `"use cache"` components use `cache()` internally (the build-time
transform wraps them in `reactCache()`), so the deduplication and persistence
layers compose:

```
Request 1: cache() MISS → "use cache" MISS → execute function → store in CacheHandler
Request 1: cache() HIT  → return memoized result (no CacheHandler lookup needed)
Request 2: cache() MISS → "use cache" HIT  → return from CacheHandler (no function execution)
```

---

## 2. `cacheSignal()` — Render Lifecycle Cleanup

**Import:** `import { cacheSignal } from 'react'`
**Source:** `packages/react/src/ReactCacheImpl.js` (definition),
`packages/react-server/src/ReactFlightServer.js` (abort triggers)

### What It Does

`cacheSignal()` returns an `AbortSignal` tied to the **lifetime of the current
server render**. When the render ends (for any reason), the signal fires, and
any in-flight work using that signal is cancelled.

```tsx
import { cache, cacheSignal } from 'react';

const fetchProduct = cache(async (id: string) => {
  const signal = cacheSignal();
  const res = await fetch(`/api/products/${id}`, { signal });
  return res.json();
});
```

### How It Works Internally — Extremely Thin

The entire implementation:

```js
// packages/react/src/ReactCacheImpl.js
export function cacheSignal(): null | AbortSignal {
  const dispatcher = ReactSharedInternals.A;  // the AsyncDispatcher
  if (!dispatcher) return null;               // outside render → null
  return dispatcher.cacheSignal();
}
```

The dispatcher's `cacheSignal()` returns `request.cacheController.signal` —
the `AbortSignal` from an `AbortController` created in the Request constructor:

```js
// packages/react-server/src/ReactFlightServer.js (RequestInstance constructor)
this.cacheController = new AbortController();
```

That's it. One `AbortController` per request, one `AbortSignal` returned by
`cacheSignal()`.

### When Exactly the Signal Fires — Three Scenarios

The signal fires in exactly three places in `ReactFlightServer.js`:

#### Scenario 1: Successful Render Completion

```js
// ~line 6525
request.cacheController.abort(
  new Error('This render completed successfully. All cacheSignals are now aborted...'),
);
```

The render finished normally. All data has been consumed. The signal fires to
clean up any lingering async work (e.g., a `cache()`-wrapped fetch that was
started but whose result was never `await`-ed because the component tree didn't
need it).

#### Scenario 2: Fatal Error

```js
// ~line 4406
request.cacheController.abort(new Error('The render was aborted due to a fatal error.', { cause: error }));
```

The render crashed. The signal fires so in-flight work doesn't continue
against a dead render.

#### Scenario 3: Explicit Abort (Client Disconnect, Timeout)

```js
// ~line 6675
request.cacheController.abort(reason);
```

The server explicitly aborted the render (e.g., via `PipeableStream.abort()`
on client disconnect). The caller's reason is passed through as the abort
reason.

**The signal fires exactly once** (standard `AbortController` behavior). There
is no partial or incremental signaling.

### How to Use the Abort Reason

```tsx
const fetchData = cache(async (id: string) => {
  try {
    const signal = cacheSignal();
    return await fetch(`/api/data/${id}`, { signal });
  } catch (error) {
    if (cacheSignal()?.aborted) {
      // Expected cancellation — render ended, not a real error.
      // Return a fallback or just let it propagate silently.
      return null;
    }
    // Real error — log it
    console.error('Fetch failed:', error);
    throw error;
  }
});
```

### Relationship to `cache()`

`cache()` and `cacheSignal()` are **siblings**, not parent-child. They share
the same `Request` object but serve different purposes:

|                | `cache()`                         | `cacheSignal()`                        |
| -------------- | --------------------------------- | -------------------------------------- |
| **Uses**       | `request.cache` (a Map)           | `request.cacheController.signal`       |
| **Purpose**    | Deduplication — don't fetch twice | Cleanup — cancel work when render ends |
| **Scope**      | Per-request                       | Per-request                            |
| **Resolution** | Same `resolveRequest()` chain     | Same `resolveRequest()` chain          |

### Return Value Outside Rendering

- **During a server render:** Returns the `AbortSignal`
- **Outside a render** (no `AsyncDispatcher`): Returns `null`
- **In a Client Component:** Returns `null` (may change in future React versions)

This means you should always check: `const signal = cacheSignal(); if (signal) { ... }`

### Why This Matters for PPR

During the **prospective prerender pass** (Phase 1 of the two-pass build):

1. Components execute, triggering data fetches
2. Caches warm up
3. The framework aborts the prospective render (all caches are warm)
4. `PipeableStream.abort()` fires → React calls `request.cacheController.abort(reason)`
5. `cacheSignal()` fires in every `cache()` scope → in-flight fetches cancelled
6. Clean cleanup — no leaked DB connections or wasted API calls

During **normal streaming SSR**:

1. Client disconnects mid-stream
2. Our abort wiring (PR #4093) calls `PipeableStream.abort()`
3. React settles `cacheSignal()` → in-flight fetches cancelled

---

## 3. The Flight Wire Protocol

The Flight protocol is the **RSC serialization format** — how React Server
Components serialize their output into a stream that can be deserialized on
the client (or during SSR) back into React elements.

### Wire Format Basics

Flight is a **line-delimited, streaming text format** served with
`Content-Type: text/x-component`. Each line is a **row**:

```
<ROW_ID>:<ROW_TAG><PAYLOAD>\n
```

- **ROW_ID**: Hexadecimal integer (`0`, `1`, `a`, `1f`) — the chunk identifier
- **ROW_TAG**: Optional single character indicating the type
- **PAYLOAD**: JSON or raw bytes

If the byte after `:` is not a recognized tag (starts with `{`, `"`, `[`,
digit), it's an **untagged model row** — plain JSON.

### Row Tag Table

**Text-format tags (newline-terminated):**

| Tag       | Name               | Description                                                                   |
| --------- | ------------------ | ----------------------------------------------------------------------------- |
| _(none)_  | **Model**          | Regular JSON data — React elements, props, component trees                    |
| `I`       | **Import**         | Client component module metadata                                              |
| `H`       | **Hint**           | Resource preload hints. Special: **no chunk ID** — format is `:H<code><JSON>` |
| `E`       | **Error**          | Serialized server-side error                                                  |
| `D`       | **Debug**          | Server component metadata and environment info (DEV only)                     |
| `R` / `r` | **ReadableStream** | Opens a text/byte ReadableStream                                              |
| `X` / `x` | **AsyncIterable**  | Opens a text/byte AsyncIterable                                               |
| `C`       | **Close**          | Closes/ends a stream or iterable                                              |

**Binary-format tags (length-delimited: `<hex_id>:<tag><hex_length>,<raw_bytes>`):**

| Tag       | Type                                            |
| --------- | ----------------------------------------------- |
| `T`       | Long text (≥1KB, avoids JSON escaping overhead) |
| `A`       | ArrayBuffer                                     |
| `O` / `o` | Int8Array / Uint8Array                          |
| `U`       | Uint8ClampedArray                               |
| `S` / `s` | Int16Array / Uint16Array                        |
| `L` / `l` | Int32Array / Uint32Array                        |
| `G` / `g` | Float32Array / Float64Array                     |
| `M` / `m` | BigInt64Array / BigUint64Array                  |
| `V`       | DataView                                        |
| `b`       | Blob                                            |

### The `$` Prefix System (In-Value References)

Within JSON payloads, any string starting with `$` is intercepted by
`parseModelString` in `ReactFlightClient.js`. This is how the protocol
encodes references, types, and special values inline in JSON:

**Chunk references:**

| Prefix     | Name               | What it does                                                                         |
| ---------- | ------------------ | ------------------------------------------------------------------------------------ |
| `$<hex>`   | Direct reference   | Resolves to another chunk's value. Enables deduplication.                            |
| `$L<hex>`  | Lazy reference     | Wraps in `React.lazy()`. Used for client component element types.                    |
| `$@<hex>`  | Promise reference  | Returns the raw Thenable. React can suspend on it.                                   |
| `$w<hex>`  | Weak promise       | Like `$@` but halts silently on stream close (no error).                             |
| `$:<path>` | Property traversal | Colon-separated path on a resolved chunk. `"$1:user:name"` → chunk 1's `.user.name`. |

**Key distinction:** `$<id>` is used when a client component is a **prop
value** (passed around). `$L<id>` is used when it is an **element type**
(rendered as `<Component />`). `$@<id>` hands you the raw promise so React
can suspend on it.

**Primitives:**

| Prefix                     | Value                                      |
| -------------------------- | ------------------------------------------ |
| `$$`                       | Literal string starting with `$` (escaped) |
| `$undefined`               | `undefined`                                |
| `$Infinity` / `$-Infinity` | `Infinity` / `-Infinity`                   |
| `$NaN`                     | `NaN`                                      |
| `$-0`                      | Negative zero                              |
| `$D<ISO>`                  | `Date` object                              |
| `$n<digits>`               | `BigInt`                                   |

**Special types:**

| Prefix              | Type                               |
| ------------------- | ---------------------------------- |
| `$S<name>`          | `Symbol.for(name)`                 |
| `$F<ref>`           | Server Action (function reference) |
| `$Q<id>` / `$W<id>` | Map / Set                          |
| `$K<id>`            | FormData                           |
| `$i<id>`            | Iterator                           |
| `$T`                | Temporary reference                |

### React Elements in the Payload

React elements are serialized as 4-element JSON arrays:

```json
["$", type, key, props]
```

- `"$"` at position 0 marks `REACT_ELEMENT_TYPE`
- `type` is a string for HTML elements (`"div"`), `$L<id>` for client
  components, or `$<id>` referencing a Symbol (`$Sreact.suspense`)
- `key` is the React key or `null`
- `props` is the props object

### Annotated Example

```
:HD["/_next/static/css/layout.css","style"]       ← Hint: preload stylesheet (no chunk ID)
3:I["./src/Counter.js",["app/page","chunks/page.js"],"Counter"]  ← Import: chunk 3 = Counter module
0:["$","div",null,{"children":[["$","h1",null,{"children":"Title"}],["$","$L3",null,{"initialCount":0}]]}]
                                                   ← Model: chunk 0 = root tree, $L3 = lazy ref to Counter
5:["$","p",null,{"children":"Async data loaded"}]  ← Model: chunk 5 = async content (arrived later)
```

### Flush Priority Order

The server flushes chunks in this priority:

1. **Import chunks** (`I` tag) → client modules start loading
2. **Hint chunks** (`H` tag) → browser starts preloading resources
3. **Debug chunks** (DEV only)
4. **Model chunks** (element trees, data)
5. **Error chunks** (`E` tag) → deferred to not block content

By the time the client starts parsing model data, the JavaScript modules and
resources it needs are already downloading.

### Progressive Streaming via Suspense

When a server component is async:

1. The initial tree is sent with an unresolved promise reference:
   `"children":"$@8"` (chunk 8, not yet emitted)
2. The client shows Suspense fallbacks where references are unresolved
3. When the async operation completes, the resolved chunk arrives: `8:[...]`
4. The Flight client resolves the promise, React reconciles, fallback replaced

Chunks can arrive in **any order** — chunk 10 does not need to arrive after
chunk 9. Each chunk has its own ID and dependency tracking.

---

## 4. `renderToReadableStream` (Flight) — RSC Serialization

**Import:** `import { renderToReadableStream } from 'react-server-dom-webpack/server'`
(also `renderToPipeableStream` for Node.js streams)
**Source:** `packages/react-server/src/ReactFlightServer.js` (~6,800 lines)

### What It Does

Takes a React element tree and serializes it into a Flight byte stream. This
is the **RSC rendering step** — it executes all Server Components and
produces the wire-format output that can be consumed by `createFromReadableStream`.

### How Server Components Are Handled

When the serializer encounters a function component:

1. Calls `renderFunctionComponent`, which **directly invokes** `Component(props)`
2. If the return is a Promise (async component):
   - Already fulfilled? Use the resolved value immediately
   - Still pending? Create a **new task**, wire `.then()` to
     `task.model = resolvedValue; pingTask(request, task)`
3. If `use(promise)` is called inside a component, React throws
   `SuspenseException`. The catch block keeps the task PENDING, saves
   `thenableState`, and wires `promise.then(task.ping)`. On re-render,
   `thenableState` lets `use()` return the resolved value.

### How Client Components Are Handled

Client components (with `"use client"`) are **NOT executed on the server**.
The bundler replaces the function with a module reference at build time.

When the serializer encounters a client reference:

1. Checks `request.writtenClientReferences` (deduplication)
2. Calls `resolveClientReferenceMetadata(bundlerConfig, clientReference)`
3. Emits an `I` (import) row:
   `3:I["./src/Counter.js",["chunk-abc"],"Counter"]`
4. Returns `$L<id>` (lazy, for element types) or `$<id>` (direct, for props)

### How Abort Works in Flight

When `abort(reason)` is called on a Flight stream:

- For **normal requests** (streaming SSR): pending tasks are aborted, error
  chunks (`E` rows) are emitted for each unresolved reference
- For **prerender requests** (static generation): pending tasks are **halted**
  (not errored) — the chunk ID is left unfulfilled, no data emitted. The
  client sees these as permanently pending (stays in Suspense fallback)

The `request.cacheController.abort(reason)` call (which settles `cacheSignal()`)
happens as part of this abort flow.

---

## 5. `prerender` (Flight) — RSC Static Prerender

**Import:** `import { prerender } from 'react-server-dom-webpack/static'`
(also `prerenderToNodeStream` for Node.js)
**Source:** Same Flight server, but uses `createPrerenderRequest`

### What It Does

Renders the RSC tree and waits for ALL async work to complete before returning.
Returns `Promise<{ prelude }>` — a single stream containing the complete
Flight payload.

### Why It Returns Only `{ prelude }` — NO Postponed State

This is a critical architectural difference from the Fizz layer:

```js
// Fizz (HTML):
prerenderToNodeStream(<App />) → { prelude, postponed }  // CAN resume

// Flight (RSC):
prerender(<App />)             → { prelude }              // CANNOT resume
```

The Flight protocol has **no concept of postpone/resume**:

- **No HTML segments or boundaries** to coordinate (Flight is flat chunks)
- **No `resumeRequest` function** in the Flight server
- **Completion is all-or-nothing** — when aborted, pending references are
  simply left unfulfilled (halted), not "postponed for later"

This is why `"use cache"` is essential for PPR: since the RSC layer
re-renders from scratch on every request, caching is the only way to avoid
re-executing expensive components.

### Halt Semantics (Different from Streaming Abort)

For prerender requests, abort uses **halt** instead of error:

```js
if (request.type === PRERENDER) {
  abortableTasks.forEach((task) => haltTask(task, request)); // silent
} else {
  abortableTasks.forEach((task) => abortTask(task, request)); // emits error chunks
}
```

`haltTask` marks the task ABORTED and decrements `pendingChunks` **without
emitting any data**. The chunk ID is intentionally left unfulfilled. After
halting, `onAllReady()` fires, **resolving** (not rejecting) the Promise.

On the client, halted chunks transition to HALTED status — their `.then()` is
a no-op (never resolves or rejects). Components referencing halted chunks stay
in Suspense fallback forever, without triggering error boundaries.

### Weak Thenables (`$w` references)

Weak promises (behind `enableFlightWeakThenables`) do NOT create tasks in
`abortableTasks` and therefore do NOT block `onAllReady`. On stream close,
PENDING_WEAK chunks transition to HALTED (not ERRORED). This enables
"optional" data that should not block static generation.

---

## 6. `createFromReadableStream` / `createFromNodeStream`

**Import:** `import { createFromReadableStream } from 'react-server-dom-webpack/client'`
**Source:** `packages/react-client/src/ReactFlightClient.js` (~5,500 lines)

### What It Does

Takes a Flight byte stream and converts it back into React elements that can
be rendered (by Fizz for SSR, or by the client for hydration/CSR).

### The Processing Pipeline

```
createResponse(moduleMap, ...)          → Initialize _chunks: Map<number, Chunk>
  ↓
createStreamState(response)             → Create parser state machine
  ↓
processBinaryChunk()/processStringChunk() → Feed incoming bytes
  ↓
resolveModel/resolveModule/resolveError   → Populate chunks
  ↓
close(response)                          → End of stream
  ↓
getRoot(response)                        → Return thenable for chunk 0
```

### Chunk Lifecycle

Each chunk extends `Promise.prototype` (making it a thenable):

```
PENDING → RESOLVED_MODEL → initializeModelChunk() → INITIALIZED
                                                   → BLOCKED (waiting on dependencies) → INITIALIZED
PENDING → RESOLVED_MODULE → initializeModuleChunk() → INITIALIZED
PENDING → ERRORED
PENDING → HALTED (from prerender halt or weak thenables)
```

### The Parser State Machine

`processBinaryChunk` walks bytes through 5 states:

| State | Name                   | What it does                                                                                                       |
| ----- | ---------------------- | ------------------------------------------------------------------------------------------------------------------ |
| 0     | `ROW_ID`               | Accumulates hex digits until `:`. ID = `(rowID << 4) \| hexDigitValue`                                             |
| 1     | `ROW_TAG`              | One byte after `:`. Dispatch: binary tag → ROW_LENGTH, text tag → ROW_CHUNK_BY_NEWLINE, JSON char → untagged model |
| 2     | `ROW_LENGTH`           | Hex length digits until `,` (binary rows only)                                                                     |
| 3     | `ROW_CHUNK_BY_NEWLINE` | Scan for `\n` (text rows)                                                                                          |
| 4     | `ROW_CHUNK_BY_LENGTH`  | Read exactly `rowLength` bytes (binary rows)                                                                       |

### How Lazy References Enable Progressive Rendering

When `parseModelString` encounters `$L<hex_id>`:

```js
const chunk = getChunk(response, id);
return {
  $$typeof: REACT_LAZY_TYPE,
  _payload: chunk,
  _init: readChunk,
};
```

When React encounters this lazy wrapper during rendering, it calls
`_init(_payload)`:

- **INITIALIZED?** Return `chunk.value` synchronously — no suspension
- **PENDING or BLOCKED?** **Throw the chunk as a thenable.** React Suspense
  catches this, subscribes via `.then()`, shows fallback. When the chunk
  resolves later (via `wakeChunk`), React re-renders.

This is the mechanism that enables progressive rendering: the initial Flight
payload can reference chunks that haven't arrived yet, and React shows
fallbacks until they do.

### Client Reference Resolution

When an `I` (module import) row arrives:

1. Parse metadata: `[moduleId, [chunkId, chunkFilename, ...], exportName]`
2. `resolveClientReference(bundlerConfig, metadata)` maps to webpack module
3. `preloadModule(clientReference)` triggers
   `__webpack_require__.e(chunkId)` for unloaded chunks
4. `requireModule(metadata)` calls `__webpack_require__(metadata[ID])` and
   extracts the named export

### Error and Close Handling

- **Stream-level errors** (`reportGlobalError`): All PENDING chunks → ERRORED,
  PENDING_WEAK → HALTED
- **Row-level errors** (`E` tag): Error object created, corresponding chunk
  errored individually
- **Partial stream** (`_allowPartialStream`): On close, unresolved chunks →
  HALTED instead of ERRORED. A HALTED chunk's `.then()` is a no-op —
  components stay in Suspense without triggering error boundaries

### Performance Note

Model resolution uses `JSON.parse()` followed by a recursive walk (not a JSON
reviver), because benchmarks showed `JSON.parse` with a reviver is ~4x slower
than bare `JSON.parse` followed by a manual walk.

### The `tee()` Pattern — Why It Matters

In streaming SSR, the Flight stream is `tee()`'d into two branches:

```
                 RSC Server Render
                        │
                 renderToReadableStream()
                        │
                  Flight ReadableStream
                        │
                      .tee()
                    /        \
            branch1            branch2
               │                  │
   createFromReadableStream   injectRSCPayload
               │              (TransformStream)
        React VDOM                │
               │           Embeds Flight data
   renderToPipeableStream   as <script> tags
      (Fizz → HTML SSR)    into HTML stream
               │                  │
                \               /
             Combined HTML Response
```

**Branch 1 (SSR):** Fed to `createFromReadableStream` to produce React
elements for Fizz to render into HTML.

**Branch 2 (Hydration):** Embedded as `<script>` tags in the HTML so the
client can reconstruct the same Flight stream for hydration:

```js
(self.__next = self.__next || []).push([2, 0, '...flight chunk data...']);
```

### Why Single Exit Point Through `createFromReadableStream` Matters

Both cache HIT and MISS must return through `createFromReadableStream`
because:

1. It handles progressive chunk resolution, Suspense integration, error
   propagation, and client reference resolution
2. The thenable it returns integrates with `use()` — `pending` suspends,
   `fulfilled` returns, `rejected` triggers error boundaries
3. Both SSR and client hydration need identical deserialization to avoid
   hydration mismatches

---

## 7. The Fizz Renderer — HTML Generation Internals

**Source:** `packages/react-server/src/ReactFizzServer.js` (~6,600 lines)
**HTML output:** `packages/react-dom-bindings/src/server/ReactFizzConfigDOM.js`

### Core Data Structures

Understanding these is key to understanding how PPR works:

**Request** — the central rendering session:

```
Request = {
  pingedTasks: Array<Task>,           // tasks ready to execute
  abortableTasks: Set<Task>,          // all cancellable tasks
  pendingRootTasks: number,           // tracks shell completion (0 = shell done)
  allPendingTasks: number,            // tracks total completion
  completedRootSegment: Segment|null, // the finished shell
  completedBoundaries: Array,         // boundaries ready to flush
  clientRenderedBoundaries: Array,    // boundaries that errored
  partialBoundaries: Array,           // partially completed boundaries
  trackedPostpones: TrackedPostpones|null,  // non-null only for prerender
  status: OPENING(10) → OPEN(11) → CLOSING(12) → CLOSED(13)
}
```

**RenderTask** — a unit of rendering work:

```
RenderTask = {
  node: ReactElement,                 // what to render
  blockedBoundary: SuspenseBoundary|null, // null = root/shell
  blockedSegment: Segment,            // where output goes
  abortSet: Set<Task>,                // for cancellation
  ping: Function,                     // attached to thenables on suspension
}
```

(Source comment: "DON'T ADD ANY MORE FIELDS. We're at 16 in prod already.")

**Segment** — a chunk of HTML output:

```
Segment = {
  status: PENDING(0) → COMPLETED(1) → FLUSHED(2), or ABORTED(3), ERRORED(4), POSTPONED(5)
  chunks: Array<Chunk>,               // HTML strings
  children: Array<Segment>,           // child segments
  id: number,                         // lazily assigned, used in $RC/$RS scripts
}
```

**SuspenseBoundary** — tracks a Suspense boundary:

```
SuspenseBoundary = {
  pendingTasks: number,               // when 0, boundary is complete
  completedSegments: Array<Segment>,
  fallbackAbortableTasks: Set<Task>,
  status: PENDING(0), COMPLETED(1), CLIENT_RENDERED(4), POSTPONED(5)
}
```

### The Shell Concept

The **shell** is everything rendered at the root level, outside any
`<Suspense>` boundary. It is tracked by `request.pendingRootTasks`. Every
task with `blockedBoundary === null` increments this counter.

```jsx
<Layout>
  {' '}
  {/* shell */}
  <Header /> {/* shell */}
  <Suspense fallback={<Spinner />}>
    <Content /> {/* NOT shell — inside Suspense */}
  </Suspense>
</Layout>
```

The shell HTML: `<Layout><Header /><Spinner /></Layout>` — note that the
**fallback IS shell** because it occupies the root-level output while the
boundary is PENDING.

`onShellReady` fires when `pendingRootTasks` reaches 0.

### How Suspense Boundaries Work

When Fizz encounters `<Suspense fallback={...}>`:

1. Creates a new `SuspenseBoundary` and two segments (fallback + content)
2. **Attempts content rendering synchronously first**
3. If content completes synchronously AND is small (< ~500 bytes), it's
   **inlined directly** — the fallback task is never created
4. If content suspends (throws a Promise) or errors, the boundary transitions:
   - Suspension: boundary stays PENDING, fallback renders, content re-tried
     when promise resolves
   - Error: boundary → CLIENT_RENDERED, `$RX` script tells client to retry

### HTML Boundary Markers

```html
<!--$-->
...
<!--/$-->
→ completed boundary (content in place)
<!--$?-->
...
<!--/$-->
→ pending boundary (showing fallback)
<!--$!-->
...
<!--/$-->
→ client-rendered boundary (errored, client retries)
```

A pending boundary looks like:

```html
<!--$?--><template id="B:3"></template>
<div class="skeleton">Loading...</div>
<!--/$-->
```

The `<template id="B:3">` is the marker that `$RC` uses to find the boundary.

### How Content Replaces Fallbacks ($RC)

When a suspended boundary resolves, Fizz streams:

```html
<div hidden id="S:5">
  <div>Actual resolved content here</div>
</div>
<script>
  $RC('B:3', 'S:5');
</script>
```

The `$RC` (completeBoundary) function:

1. Finds the template node `B:3` and the content node `S:5`
2. Pushes `[templateNode, contentNode]` into `window['$RB']` (batch queue)
3. Schedules `$RV` (revealCompletedBoundaries) via `requestAnimationFrame`

The `$RV` function:

1. Removes fallback children after the template
2. Inserts resolved content
3. Updates marker from `$?` to `$` (complete)
4. Triggers selective hydration via `_reactRetry`

**Batching:** Reveals are throttled to at most once every **300ms**. There's
a `TARGET_VANITY_METRIC = 2300` constant (targeting 2.5s LCP) that stops
batching if total page load approaches this threshold.

### All Fizz Client-Side Scripts

| Global | Function Name               | Purpose                                                             |
| ------ | --------------------------- | ------------------------------------------------------------------- |
| `$RS`  | `completeSegment`           | Move streaming segment content from hidden container to placeholder |
| `$RC`  | `completeBoundary`          | Schedule swap of Suspense fallback with resolved content            |
| `$RX`  | `clientRenderBoundary`      | Mark boundary for client-side re-rendering                          |
| `$RV`  | `revealCompletedBoundaries` | Batch-reveal all queued completed boundaries                        |
| `$RB`  | _(array)_                   | Current batch queue of `[template, content]` pairs                  |
| `$RT`  | _(timestamp)_               | Last reveal time from `performance.now()`                           |
| `$RM`  | _(Map)_                     | Stylesheet href → DOM element mapping                               |

### Work Loop

`performWork` iterates `request.pingedTasks`, calling `retryTask` on each:

- **Success:** Segment → COMPLETED, finishedTask decrements counters
- **SuspenseException:** Extract thenable, attach `task.ping` as `.then()`
  listener — when it resolves, `pingTask` re-adds to `pingedTasks`
- **Other errors:** Segment → ERRORED, boundary → CLIENT_RENDERED

### Streaming and Backpressure

Progressive chunk size defaults to **12,800 bytes** (derived from targeting
new content every ~500ms on low-end 3G).

`flushCompletedQueues` writes in strict priority:

1. **Root/Shell**: `completedRootSegment` (preamble, `<html>`, `<head>`, etc.)
2. **Completed Boundaries**: `$RC` scripts
3. **Partial Boundaries**: `$RS` scripts for segments within still-pending
   boundaries
4. **Postamble**: `</body></html>`, stream close

**Backpressure**: 4096-byte internal buffer. `writeChunkAndReturn` returns
whether `destination.write()` indicated backpressure. On backpressure, React
stops flowing; on `drain` event, `startFlowing` resumes.

---

## 8. `renderToPipeableStream` (Fizz) — Streaming SSR

**Import:** `import { renderToPipeableStream } from 'react-dom/server'`
**Source:** `packages/react-dom/src/server/ReactDOMFizzServerNode.js`

### Signature

```ts
function renderToPipeableStream(
  children: ReactNode,
  options?: {
    identifierPrefix?: string,
    namespaceURI?: string,
    nonce?: string,
    bootstrapScriptContent?: string,
    bootstrapScripts?: string[],
    bootstrapModules?: string[],
    progressiveChunkSize?: number,
    signal?: AbortSignal,
    onError?: (error: mixed, errorInfo: ErrorInfo) => ?string,
    onShellReady?: () => void,
    onShellError?: (error: mixed) => void,
    onAllReady?: () => void,
    onHeaders?: (headers: Headers) => void,
    onPostpone?: (reason: string) => void,
    formState?: ReactFormState,
  }
): PipeableStream;

type PipeableStream = {
  pipe<T: Writable>(destination: T): T,
  abort(reason?: mixed): void,
};
```

### How the Callbacks Fire

| Scenario           | `onError`                        | `onShellError` | `onShellReady` | `onAllReady`                     |
| ------------------ | -------------------------------- | -------------- | -------------- | -------------------------------- |
| Normal completion  | Only if errors inside boundaries | No             | ✅ Yes         | ✅ Yes                           |
| Abort before shell | ✅ Yes                           | ✅ Yes         | ❌ No          | ❌ No                            |
| Abort after shell  | ✅ Yes (per boundary)            | No             | Already fired  | ✅ Fires after fallbacks flushed |

**Ordering guarantees:**

- `onError` fires before `onShellError`
- `onShellReady` fires before `onAllReady`
- Shell error means neither `onShellReady` nor `onAllReady` fires

### How `abort()` Works

1. Sets `request.aborted = true`
2. Iterates all `abortableTasks`: marks each segment ABORTED, calls
   `finishedTask`
3. Each pending Suspense boundary → CLIENT_RENDERED (fallback HTML stays,
   `$RX` script tells client to take over)
4. `onAllReady()` fires when all tasks accounted for

If no reason is provided: `new Error("The render was aborted by the server
without a reason.")`

### Shell vs. Content Abort

**Abort during shell rendering:**

- `onShellError` fires
- **No bytes have been emitted** (HTTP status code not yet committed)
- You can send an error page or redirect

**Abort after shell (during content streaming):**

- `onShellReady` has already fired, `pipe()` called
- Remaining Suspense boundaries get fallback HTML flushed
- Stream completes normally with fallback content
- Client retries rendering the deferred content

### Typical Usage Pattern

```ts
const { pipe, abort } = renderToPipeableStream(<App />, {
  bootstrapScripts: ['/main.js'],

  onShellReady() {
    // Shell is ready — headers not yet sent
    response.statusCode = didError ? 500 : 200;
    response.setHeader('Content-Type', 'text/html');
    pipe(response);
    // Content streams progressively from here
  },

  onShellError(error) {
    // Shell failed — send a fallback
    response.statusCode = 500;
    response.end('<h1>Server Error</h1>');
  },

  onError(error) {
    didError = true;
    console.error(error);
  },
});

// Timeout: abort after 10 seconds
setTimeout(() => abort(), 10000);
```

---

## 9. `prerenderToNodeStream` (Fizz) — Static HTML with PPR

**Import:** `import { prerenderToNodeStream } from 'react-dom/static.node'`
**Source:** `packages/react-dom/src/server/ReactDOMFizzStaticNode.js`

### What It Does

Renders a React tree into static HTML, waiting for ALL content to complete.
Unlike `renderToPipeableStream`, it does **not** stream progressively — it
collects everything and returns it as a single Readable.

Returns `Promise<{ prelude: Readable, postponed: PostponedState | null }>`.

### How It Differs from `renderToPipeableStream`

| Aspect             | `renderToPipeableStream`           | `prerenderToNodeStream`                  |
| ------------------ | ---------------------------------- | ---------------------------------------- |
| Return type        | Synchronous `{ pipe, abort }`      | `Promise<{ prelude, postponed }>`        |
| When content flows | Progressively from `onShellReady`  | Only after ALL content is ready          |
| Resolution trigger | `onShellReady` for streaming start | `onAllReady` — waits for everything      |
| Suspense strategy  | Content first, fallback if needed  | Fallback first, content deferred         |
| Postponed state    | N/A                                | Returned for PPR resume                  |
| Output             | Streaming HTML with `$RC` scripts  | Complete static HTML (no scripts needed) |
| Use case           | Dynamic per-request SSR            | Static generation / build-time PPR       |

### The Postpone Tracking Mechanism

Internally, `createPrerenderRequest` sets:

```js
request.trackedPostpones = {
  workingMap: new Map(), // KeyNode → ReplayNode
  rootNodes: [],
  rootSlots: null,
};
```

This non-null `trackedPostpones` field changes the **entire Fizz pipeline**:

- Suspense boundaries render **fallback FIRST**, then schedule content as a
  separate task (reversed from normal render)
- `pingTask` uses `scheduleMicrotask` instead of `scheduleWork`
- `finishedTask` tracks postponed holes in `workingMap` instead of queuing
  for flush

### The `{ prelude, postponed }` Return Value

**`prelude`**: A Node.js Readable stream containing complete HTML. Since it
resolves at `onAllReady`, all non-postponed Suspense boundaries are resolved —
no streaming scripts, no fallback swapping needed.

**`postponed`** (`PostponedState | null`): When non-null:

```ts
PostponedState = {
  nextSegmentId: number, // So resume allocates IDs above shell's range
  rootFormatContext: FormatContext, // HTML/SVG/MathML context
  progressiveChunkSize: number,
  resumableState: ResumableState, // Serialized render state
  replayNodes: Array<ReplayNode>, // Tree of postponed component paths
  replaySlots: ResumeSlots, // Root-level slots to fill
};
```

Where `ReplayNode` is:

- 4-tuple `[name, key, children, slots]` for regular nodes
- 6-tuple `[name, key, children, slots, fallbackNode, rootSegmentID]` for
  Suspense boundaries

**Critical:** `nextSegmentId` is snapshotted during `flushCompletedQueues`
(not before), because flushing advances segment IDs. Without this, resumed
renders would allocate colliding IDs.

### How Abort Creates Postponed Holes

When the `AbortSignal` fires during prerender, unresolved Suspense boundaries
are captured:

```js
function trackPostpone(request, trackedPostpones, task, segment) {
  segment.status = POSTPONED;
  const boundary = task.blockedBoundary;
  if (boundary === null) {
    // Root-level postpone
    segment.id = request.nextSegmentId++;
    trackedPostpones.rootSlots = segment.id;
    return;
  }
  if (boundary.status === PENDING) {
    // Build 6-tuple ReplaySuspenseBoundary
    // [name, key, children, slots, fallbackNode, rootSegmentID]
    trackPostponedBoundary(request, trackedPostpones, boundary);
  }
}
```

The Promise **resolves** (not rejects) with `postponed` containing this data.

### `postponed === null`

If everything completed before the abort signal fired (or no abort signal was
provided), `postponed` is `null`. The prelude contains the complete page.

---

## 10. `resumeToPipeableStream` — Resume Postponed Rendering

**Import:** `import { resumeToPipeableStream } from 'react-dom/server'`
**Source:** `packages/react-server/src/ReactFizzServer.js` (`resumeRequest`)

### What It Does

Takes a React element tree and a `PostponedState` from a prior
`prerenderToNodeStream`, and renders **only the postponed parts**. The output
is streaming HTML that replaces Suspense fallbacks in the already-sent shell.

### Signature

```ts
function resumeToPipeableStream(
  children: ReactNodeList,
  postponedState: PostponedState,
  options?: {
    nonce?: string;
    onShellReady?: () => void;
    onShellError?: (error: mixed) => void;
    onAllReady?: () => void;
    onError?: (error: mixed, errorInfo: ErrorInfo) => ?string;
  },
): PipeableStream;
```

**Note:** Does NOT accept `bootstrapScripts`, `bootstrapModules`,
`identifierPrefix`, or `formState` — those are baked into the postponed state.

### How It Picks Up From Postponed State

`resumeRequest()` reconstructs a Request from PostponedState fields:

```js
request.resumableState = postponedState.resumableState;
request.rootFormatContext = postponedState.rootFormatContext;
request.progressiveChunkSize = postponedState.progressiveChunkSize;
request.nextSegmentId = postponedState.nextSegmentId; // prevent ID collisions
```

Then it branches on `postponedState.replaySlots`:

**Case A — Root-level postpone** (`typeof replaySlots === 'number'`):
The entire root was postponed. Creates a fresh root segment and a `RenderTask`.
Effectively a full server render.

**Case B — Granular replay** (default):
Creates a `ReplaySet` from `replayNodes`/`replaySlots`, then creates a
`ReplayTask`:

```js
const replay = {
  nodes: postponedState.replayNodes,
  slots: postponedState.replaySlots,
  pendingTasks: 0,
};
const rootTask = createReplayTask(request, null, replay, children, ...);
```

### Two Task Types: RenderTask vs. ReplayTask

|                        | RenderTask                 | ReplayTask                                          |
| ---------------------- | -------------------------- | --------------------------------------------------- |
| `replay` field         | `null`                     | `ReplaySet`                                         |
| `blockedSegment` field | `Segment`                  | `null`                                              |
| **Produces HTML?**     | ✅ Yes — writes to segment | ❌ No — walks tree matching against replay nodes    |
| **Purpose**            | Render real content        | Navigate the component tree to find postponed slots |

### How ReplayTask Finds What to Render

The `replayElement` function walks the component tree, matching against
`ReplayNode` entries by key and index:

```js
function replayElement(request, task, keyPath, name, keyOrIndex, childIndex, type, props, ref, replay) {
  const replayNodes = replay.nodes;
  for (let i = 0; i < replayNodes.length; i++) {
    const node = replayNodes[i];
    if (keyOrIndex !== node[1]) continue;  // match by key/index

    if (node.length === 4) {
      // Regular replay node — recurse into children
      task.replay = { nodes: node[2], slots: node[3], pendingTasks: 1 };
      renderElement(request, task, keyPath, type, props, ref);
    } else {
      // Length 6 = ReplaySuspenseBoundary — this needs real rendering
      replaySuspenseBoundary(request, task, keyPath, props, node[5]/*rootSegmentID*/, ...);
    }
    replayNodes.splice(i, 1);  // consume this slot
    return;
  }
  // Not found in replay nodes = fully rendered in prelude → SKIP
}
```

**If a component does not appear in the replay nodes, it is skipped entirely.**

### How Replay Converts to Real Rendering

When a ReplayTask finds a slot needing real HTML, it temporarily converts:

```js
function resumeNode(request, task, segmentId, node, childIndex) {
  const resumedSegment = createPendingSegment(request, 0, null, ...);
  resumedSegment.id = segmentId;      // Reuse ID from prerender!
  resumedSegment.parentFlushed = true;
  task.replay = null;                 // Switch to RenderTask mode
  task.blockedSegment = resumedSegment;
  renderNode(request, task, node, childIndex);
  resumedSegment.status = COMPLETED;
}
```

### How Output Integrates With the Static Shell

The resume stream is appended after the prelude in the same HTTP response:

1. **Prelude** (from prerender): Full HTML shell. Postponed boundaries have
   fallbacks: `<!--$?-->...fallback...<!--/$-->`. Each gets a unique
   `rootSegmentID`.

2. **Resume stream**: Emits content in hidden containers plus swap scripts:

```html
<div hidden id="S:5">
  <div>Dynamic content rendered at request time</div>
</div>
<script>
  $RC('B:3', 'S:5');
</script>
```

The **shared segment IDs** are the glue — `resumedSegment.id = segmentId`
reuses the ID from the prerender, so `$RC` knows which boundary to fill.

---

## 11. `React.unstable_postpone()` — Creating Dynamic Holes

### Critical Update: `unstable_postpone` No Longer Exists as a Direct API

Searching the current React source at HEAD: there is **no
`unstable_postpone` function**, no `REACT_POSTPONE_TYPE` symbol, and no
`ReactPostpone.js` file. The mechanism has been refactored.

### Historical Behavior (React canary 2023-2024)

`React.unstable_postpone(reason)` threw an object with
`$$typeof: REACT_POSTPONE_TYPE` (`Symbol.for('react.postpone')`). Fizz catch
blocks checked for this symbol to distinguish postpone from errors and
Suspense.

### Current Mechanism — Abort-Based Postponing

Instead of an explicit `postpone()` call, postponing now works through the
**abort mechanism** combined with `trackedPostpones`:

1. You pass an `AbortSignal` to `prerenderToNodeStream`
2. Components that access dynamic data (cookies, headers, etc.) return
   **hanging promises** — promises that never resolve until the abort signal
   fires
3. These components suspend via Suspense
4. When the abort signal fires, Fizz checks `request.trackedPostpones`
   (non-null for prerender requests)
5. Pending tasks are captured via `trackPostpone()` instead of being errored
6. The boundary gets status `POSTPONED = 5`

```js
function trackPostpone(request, trackedPostpones, task, segment) {
  segment.status = POSTPONED;
  // ... record position in replayNodes/replaySlots tree
}
```

### POSTPONED vs CLIENT_RENDERED

| Status            | Value | What it means                                           |
| ----------------- | ----- | ------------------------------------------------------- |
| `POSTPONED`       | 5     | Expects server-side resume via `resumeToPipeableStream` |
| `CLIENT_RENDERED` | 4     | Tells the client to re-render this boundary             |

If resume fails for a POSTPONED boundary, it degrades to CLIENT_RENDERED.

### How Frameworks Create Dynamic Holes (Hanging Promises)

Frameworks create dynamic boundaries by returning promises that never resolve
until abort:

```ts
function makeHangingPromise<T>(signal: AbortSignal): Promise<T> {
  return new Promise<T>((_, reject) => {
    signal.addEventListener('abort', () => {
      reject(new Error('Dynamic boundary: rejects when prerender completes.'));
    });
  });
}
```

During prerender:

1. `cookies()` / `headers()` / `searchParams` return `makeHangingPromise(signal)`
2. The awaiting component suspends indefinitely
3. When all caches are warm, the framework aborts the render
4. Hanging promises reject → boundaries become POSTPONED (not ERRORED)
5. The static shell includes Suspense fallbacks for these boundaries

At request time, the same APIs return **real values**, so
`resumeToPipeableStream` can render the actual content.

---

## 12. `encodeReply` / `decodeReply` — Argument Serialization

**Import:**

```ts
import { encodeReply } from 'react-server-dom-webpack/client';
import { decodeReply } from 'react-server-dom-webpack/server';
```

**Source:**

- `packages/react-client/src/ReactFlightReplyClient.js` (serialization)
- `packages/react-server/src/ReactFlightReplyServer.js` (deserialization)

### What It Does

Serializes complex JavaScript values into a wire format that can cross the
client-server boundary. Originally designed for Server Action arguments, but
also used as the basis for deterministic cache key generation.

### Wire Format — Adaptive

The format adapts based on content:

**Simple path (JSON string):** When the entire value tree is synchronous and
contains no binary data, Blobs, or streams → `JSON.stringify(model,
resolveToJSON)` → returns a raw JSON string.

**Complex path (FormData):** When the serializer encounters Promises,
ReadableStreams, TypedArrays, Blobs, or Files → upgrades to a FormData object.
Root JSON goes in field `"0"`, each outlined part gets field `"1"`, `"2"`, etc.
Binary data becomes actual FormData file entries.

Return type: `Promise<string | URLSearchParams | FormData>`

### Type Serialization Catalog

**Primitives:**

| Value                                   | Wire representation            |
| --------------------------------------- | ------------------------------ |
| `null`, `true`, `false`, finite numbers | Native JSON                    |
| `-0`                                    | `"$-0"`                        |
| `Infinity` / `-Infinity`                | `"$Infinity"` / `"$-Infinity"` |
| `NaN`                                   | `"$NaN"`                       |
| `undefined`                             | `"$undefined"`                 |
| BigInt                                  | `"$n"` + decimal digits        |
| String starting with `$`                | `"$$..."` (escaped)            |
| Date                                    | `"$D"` + ISO string            |

**Collections:**

| Type                  | Wire prefix     | How it's serialized           |
| --------------------- | --------------- | ----------------------------- |
| Plain objects, arrays | Native JSON     | Direct                        |
| Map                   | `"$Q"` + hex ID | Outlined as `Array.from(map)` |
| Set                   | `"$W"` + hex ID | Outlined as `Array.from(set)` |
| FormData              | `"$K"` + hex ID | Outlined with entries         |
| Iterator              | `"$i"` + hex ID | Outlined                      |

**Binary types (all upgrade to FormData):**

| Type                           | Prefix      |
| ------------------------------ | ----------- |
| ArrayBuffer                    | `$A`        |
| Int8Array / Uint8Array         | `$O` / `$o` |
| Uint8ClampedArray              | `$U`        |
| Int16Array / Uint16Array       | `$S` / `$s` |
| Int32Array / Uint32Array       | `$L` / `$l` |
| Float32Array / Float64Array    | `$G` / `$g` |
| BigInt64Array / BigUint64Array | `$M` / `$m` |
| DataView                       | `$V`        |
| Blob                           | `$B`        |

**Async types:**

| Type                         | Prefix                   |
| ---------------------------- | ------------------------ |
| Promise/Thenable             | `"$@"` + hex ID          |
| ReadableStream (text/binary) | `"$R"` / `"$r"` + hex ID |
| AsyncIterable/Iterator       | `"$X"` / `"$x"` + hex ID |

**References:**

| Type                      | Prefix                                   |
| ------------------------- | ---------------------------------------- |
| Server reference (action) | `"$h"` + hex ID (contains `{id, bound}`) |
| Temporary reference       | `"$T"`                                   |
| Dedup reference           | `"$"` + hex ID with colon paths          |

### Deduplication

The `writtenObjects` WeakMap tracks every serialized object. If the same
object is encountered again, a reference string is emitted instead of
re-serializing:

```
First encounter of obj → serialized at position 3
Second encounter of obj → "$3"
Nested path → "$3:foo:bar"
```

### Cannot Serialize (without temporary references)

- React elements
- Symbols
- Arbitrary functions (only known server references)
- Class instances
- Context providers

### Security Limits

- `MAX_BIGINT_DIGITS = 300`
- `MAX_BOUND_ARGS = 1000`
- `DEFAULT_MAX_ARRAY_NESTING = 1000000`
- `__proto__` keys deleted during deserialization

### Relationship to Flight Protocol

The Reply protocol is a **"reverse Flight"** (Sebastian Markbåge, PR #26360).
Both share the same `$`-prefix type tag scheme for primitives, but Reply
cannot carry React elements or component references — only data and server
function handles. Flight is server→client (component trees), Reply is
client→server (action arguments).

### Why It's Used for Cache Keys in the PPR Plan

Our PPR implementation plan specifies `encodeReply(args)` as part of the
cache key recipe `(buildId, id, encodeReply(args))` because:

1. **Deterministic serialization** of complex types (Map, Set, Date, BigInt,
   typed arrays)
2. **Object identity tracking** via `writtenObjects` WeakMap
3. **Injective** — different inputs produce different outputs
4. **Handles server references** (`{id, bound}` pairs)
5. **Standard** — it is the canonical serialization for what crosses the
   client-server boundary, so cache keys and action arguments use the same
   format

Note: our current `buildCacheKey.ts` uses a **hand-rolled serializer** instead
of `encodeReply`. The PPR validity review identified this as a divergence that
should be resolved.

---

## 13. How These APIs Compose for PPR

Here is how every API in this document fits together in the PPR lifecycle:

### Build Time — Pass 1 (Prospective Render, Cache Warming)

```
                    ┌─ cache() deduplicates calls within this render
                    │  cacheSignal() → AbortSignal (fires when render aborts)
                    │
        ┌───────────┴───────────────────────────────────────────────┐
        │  RSC Layer: renderToReadableStream (Flight)               │
        │  • Executes ALL server components                         │
        │  • "use cache" wrappers call CacheHandler.set() on MISS   │
        │  • Dynamic APIs return hanging promises                   │
        │  • Framework CacheSignal tracks in-flight cache reads     │
        └───────────────────────────────────────────────────────────┘
                    │
                    ▼  All caches warm → Framework CacheSignal fires
                    │  → AbortController.abort() → render aborted
                    │  → cacheSignal() fires → in-flight fetches cancelled
                    │
                    ▼  OUTPUT DISCARDED (this pass only warmed caches)
```

### Build Time — Pass 2 (Final Render, Shell Carving)

```
        ┌───────────────────────────────────────────────────────────┐
        │  RSC Layer: prerender (Flight static)                     │
        │  • cache() hits for all "use cache" components (instant)  │
        │  • Dynamic APIs return hanging promises                   │
        │  • Aborted after one task (setImmediate)                  │
        │  • Returns { prelude } — complete Flight payload          │
        │  • Halted chunks = permanently pending on client          │
        └─────────────────────┬─────────────────────────────────────┘
                              │
                    createFromReadableStream (deserialize Flight → React elements)
                              │
        ┌─────────────────────▼─────────────────────────────────────┐
        │  Fizz Layer: prerenderToNodeStream                        │
        │  • Renders React elements to HTML                         │
        │  • Cached components resolve instantly (in-memory RDC)    │
        │  • Dynamic boundaries → POSTPONED (via abort + tracking)  │
        │  • Returns { prelude, postponed }                         │
        │    - prelude: static HTML shell with Suspense fallbacks   │
        │    - postponed: opaque PostponedState blob                │
        └─────────────────────┬─────────────────────────────────────┘
                              │
                    STORED: Shell HTML + PostponedState (paired, atomic)
```

### Request Time — Serve Shell + Resume Dynamic Content

```
        Client Request
              │
              ├──── Shell HTML served instantly (from cache/CDN)
              │     (contains <!--$?-->...fallback...<!--/$--> boundaries)
              │
              │     IN PARALLEL:
              │
        ┌─────▼─────────────────────────────────────────────────────┐
        │  RSC Layer: renderToReadableStream (Flight, fresh)        │
        │  • Re-executes all components from scratch                │
        │  • "use cache" HIT → instant (from CacheHandler)          │
        │  • Dynamic APIs return REAL values (cookies, headers)     │
        │  • cache() deduplicates within this request               │
        │  • cacheSignal() → cleanup on disconnect/completion       │
        └─────────────────────┬─────────────────────────────────────┘
                              │
                    createFromReadableStream → React elements
                              │
        ┌─────────────────────▼─────────────────────────────────────┐
        │  Fizz Layer: resumeToPipeableStream(element, postponed)   │
        │  • ReplayTask walks tree, matches against replayNodes     │
        │  • Skips fully prerendered components                     │
        │  • Renders ONLY postponed boundaries with real data       │
        │  • Output: <div hidden id="S:5">...</div>                 │
        │           <script>$RC("B:3","S:5")</script>               │
        └─────────────────────┬─────────────────────────────────────┘
                              │
              ├──── Dynamic content streamed into same HTTP response
              │     ($RC scripts swap fallbacks → real content)
              │
              ▼
        Client sees: instant shell → progressive dynamic content
```

### encodeReply in the Cache Key Flow

```
"use cache" component called with (arg1, arg2)
              │
    encodeReply([arg1, arg2])  →  deterministic bytes
              │
    sha256(buildId + functionId + encodedArgs)  →  cache key
              │
    CacheHandler.get(key)
              │
    HIT → createFromReadableStream(cachedRSCBytes) → instant
    MISS → execute component → renderToReadableStream → tee()
              │                                           │
    createFromReadableStream (return)      CacheHandler.set(key, bytes)
```

---

## Appendix A: API Availability Matrix

| API                               | Package                                | React Version | Server/Client                | RSC/Fizz   |
| --------------------------------- | -------------------------------------- | ------------- | ---------------------------- | ---------- |
| `cache()`                         | `react`                                | 19.0+         | Server only                  | RSC        |
| `cacheSignal()`                   | `react`                                | **19.2+**     | Server only (null elsewhere) | RSC        |
| `renderToPipeableStream`          | `react-dom/server`                     | 18+           | Server                       | Fizz       |
| `prerenderToNodeStream`           | `react-dom/static.node`                | 19.0+         | Server                       | Fizz       |
| `resumeToPipeableStream`          | `react-dom/server`                     | **19.2+**     | Server                       | Fizz       |
| `renderToReadableStream` (Flight) | `react-server-dom-webpack/server`      | 19.0+         | Server                       | RSC        |
| `prerender` (Flight)              | `react-server-dom-webpack/static`      | 19.0+         | Server                       | RSC        |
| `createFromReadableStream`        | `react-server-dom-webpack/client`      | 19.0+         | Both                         | RSC client |
| `createFromNodeStream`            | `react-server-dom-webpack/client.node` | 19.0+         | Server (SSR)                 | RSC client |
| `encodeReply`                     | `react-server-dom-webpack/client`      | 19.0+         | Client                       | RSC client |
| `decodeReply`                     | `react-server-dom-webpack/server`      | 19.0+         | Server                       | RSC        |

## Appendix B: Source File Map

| File                                                           | What it contains                                   |
| -------------------------------------------------------------- | -------------------------------------------------- |
| `packages/react/src/ReactCacheImpl.js`                         | `cache()` and `cacheSignal()`                      |
| `packages/react-server/src/ReactFlightServer.js`               | Flight server (RSC serialization), ~6,800 lines    |
| `packages/react-client/src/ReactFlightClient.js`               | Flight client (RSC deserialization), ~5,500 lines  |
| `packages/react-server/src/ReactFizzServer.js`                 | Fizz server (HTML rendering), ~6,600 lines         |
| `packages/react-dom/src/server/ReactDOMFizzServerNode.js`      | `renderToPipeableStream`, `resumeToPipeableStream` |
| `packages/react-dom/src/server/ReactDOMFizzStaticNode.js`      | `prerenderToNodeStream`                            |
| `packages/react-dom-bindings/src/server/ReactFizzConfigDOM.js` | HTML output, $RC/$RS/$RX scripts                   |
| `packages/react-client/src/ReactFlightReplyClient.js`          | `encodeReply`                                      |
| `packages/react-server/src/ReactFlightReplyServer.js`          | `decodeReply`                                      |
| `packages/react-server-dom-webpack/`                           | Webpack-specific bindings                          |

---

_This document is a point-in-time reference based on the React source at HEAD
as of August 2026. React internals may change between versions._
