# The RSC Payload in PPR — By Example

**How the data flows from your React components to the HTML the user sees.**

Every example was tested on React 19.2.8. No Next.js framework code — just
vanilla React APIs (`react-dom/static`, `react-dom/server`) to show the
mechanics that PPR builds on.

---

## Chapter 1: What PPR Actually Produces

PPR splits your page into two pieces at build time:

```
┌─────────────────────────────────────────────────┐
│              YOUR REACT TREE                     │
│                                                  │
│  <App>                                           │
│    <Header />           ← static                 │
│    <Nav />              ← static                 │
│    <Suspense fallback={<Skeleton />}>             │
│      <UserGreeting />   ← dynamic (needs cookies)│
│    </Suspense>                                    │
│    <Footer />           ← static                 │
│  </App>                                          │
│                                                  │
└─────────────────────────────────────────────────┘
                    │
          PPR splits it into:
                    │
         ┌──────────┴──────────┐
         ▼                     ▼
┌─────────────────┐   ┌─────────────────┐
│  STATIC SHELL   │   │  RESUME STREAM  │
│  (cached)       │   │  (per-request)  │
│                 │   │                 │
│  <h1>My App</h1>│   │  Hello, Abanoub!│
│  <nav>...</nav> │   │  + swap script  │
│  👤 Loading...  │   │                 │
│  <footer>...</  │   │                 │
└─────────────────┘   └─────────────────┘
   Served instantly       Streamed in
```

The user sees the shell immediately (instant TTFB), then the dynamic content
streams in and replaces the fallback.

### Real output from experiment 15

**Build time** — `prerender()` produces the static shell:

```html
<!DOCTYPE html>
<html>
  <head></head>
  <body>
    <div>
      <h1>My App</h1>
      <nav>Home | About | Contact</nav>
      <!--$?--><template id="B:0"></template>
      <p>👤 Loading user...</p>
      <!--/$-->
      <footer>© 2024 MyApp</footer>
    </div>
  </body>
</html>
```

**Request time** — `resumeToPipeableStream()` fills the hole:

```html
<div hidden id="S:0">
  <p>Hello, Abanoub!</p>
</div>
<script>$RC("B:0","S:0")</script>
</body></html>
```

The `$RC` script finds the `<template id="B:0">` marker in the shell, finds
the hidden `<div id="S:0">`, and swaps the fallback for the real content.

---

## Chapter 2: The HTML Markers — A Field Guide

React uses HTML comments and template elements to mark up Suspense boundaries.
Here's what each one means:

### Resolved boundary (content is ready)

```html
<!--$-->
<div>This content resolved successfully</div>
<!--/$-->
```

The `<!--$-->` comment means "this Suspense boundary resolved — the content
below is the actual component output." The `<!--/$-->` marks the end.

### Pending boundary (content not ready — showing fallback)

```html
<!--$?-->
<template id="B:0"></template>
<p>Loading...</p>
<!--/$-->
```

The `<!--$?-->` means "this Suspense boundary is still pending." The
`<template id="B:0">` is an invisible marker that the resume script uses to
find this spot later. The `<p>Loading...</p>` is the fallback the user sees.

### What it looks like with real components

If you write this:

```jsx
function App() {
  return (
    <div>
      <h1>Static Header</h1>
      <Suspense fallback={<p>Loading...</p>}>
        <DynamicComponent /> {/* hangs during prerender */}
      </Suspense>
      <footer>Static Footer</footer>
    </div>
  );
}
```

`prerender()` produces:

```html
<div>
  <h1>Static Header</h1>
  <!--$?--><template id="B:0"></template>
  <p>Loading...</p>
  <!--/$-->
  <footer>Static Footer</footer>
</div>
```

Static content renders normally. The dynamic component becomes a pending
boundary with its fallback.

---

## Chapter 3: Resolved vs Pending — Side by Side

Same component, two scenarios:

```jsx
<Suspense fallback={<p>Loading...</p>}>
  <AsyncContent />
</Suspense>
```

**Scenario A**: `AsyncContent` resolves before abort (e.g., cache hit):

```html
<!--$-->
<div>Async Content</div>
<!--/$-->
```

No `<template>`, no fallback. The content is directly in the shell. The
`<!--$-->` marker (without `?`) tells React "this was a Suspense boundary
and it resolved." This is purely for hydration — the user just sees the content.

**Scenario B**: `AsyncContent` is still pending at abort time:

```html
<!--$?--><template id="B:0"></template>
<p>Loading...</p>
<!--/$-->
```

The fallback renders. The `<template>` marker waits for the resume stream.

**The difference is entirely determined by timing** — did the component resolve
before the abort signal fired?

---

## Chapter 4: Multiple Dynamic Holes

A page can have multiple independent dynamic holes:

```jsx
function Dashboard() {
  return (
    <div>
      <Suspense fallback={<p>Loading notifications...</p>}>
        <Notifications /> {/* dynamic — reads user session */}
      </Suspense>
      <p>Dashboard overview (static)</p>
      <Suspense fallback={<p>Loading activity...</p>}>
        <RecentActivity /> {/* dynamic — reads user session */}
      </Suspense>
    </div>
  );
}
```

`prerender()` output:

```html
<div>
  <!--$?--><template id="B:0"></template>
  <p>Loading notifications...</p>
  <!--/$-->
  <p>Dashboard overview (static)</p>
  <!--$?--><template id="B:1"></template>
  <p>Loading activity...</p>
  <!--/$-->
</div>
```

Each hole gets its own boundary ID (`B:0`, `B:1`). At request time, the resume
stream fills each one independently:

```html
<div hidden id="S:0">
  <ul>
    <li>3 new messages</li>
  </ul>
</div>
<script>
  $RC('B:0', 'S:0');
</script>
<div hidden id="S:1">
  <ul>
    <li>Deployed v2.1</li>
  </ul>
</div>
<script>
  $RC('B:1', 'S:1');
</script>
```

Static content between holes renders normally in the shell.

---

## Chapter 5: prerender() vs renderToPipeableStream()

React offers two server rendering APIs. Understanding the difference is
crucial for PPR:

### `prerender()` (from `react-dom/static`)

```js
const { prelude, postponed } = await prerender(<App />, { signal });
```

Returns:

- **`prelude`** — a `ReadableStream` of the static HTML shell
- **`postponed`** — an opaque object describing the holes (or `null` if
  everything resolved)

The prelude contains the _final_ HTML for everything that resolved. Pending
boundaries show their fallbacks. Nothing more will come from this API —
the prelude is complete and cacheable.

**What you get**: a snapshot at the moment of abort.

### `renderToPipeableStream()` (from `react-dom/server`)

```js
const { pipe } = renderToPipeableStream(<App />, {
  onShellReady() {
    pipe(response);
  },
});
```

Streams HTML in real-time:

1. First: the shell (with fallbacks for pending boundaries)
2. Then: resolved content in hidden `<div>`s + `$RC` replacement scripts

**What you get**: a continuous stream that progressively fills in content.

### The key difference

With the same component tree (an async component that resolves after 50ms +
a hanging component):

**`prerender()` output** (aborted at 100ms):

```html
<div>
  <h1>Shell</h1>
  <!--$-->
  <p>[Slow content resolved after 50ms]</p>
  <!--/$-->
  <!--$?--><template id="B:0"></template>
  <p>Loading dynamic...</p>
  <!--/$-->
</div>
```

The slow content (50ms) had time to resolve, so it's **inlined directly** in
the prelude — no fallback, no replacement script. The hanging component is a
pending boundary.

**`renderToPipeableStream()` output** (shell + stream):

```html
<!-- SHELL (sent immediately): -->
<div>
  <h1>Shell</h1>
  <!--$?--><template id="B:0"></template>
  <p>Loading slow...</p>
  <!--/$-->
  <!--$?--><template id="B:1"></template>
  <p>Loading dynamic...</p>
  <!--/$-->
</div>

<!-- STREAMED LATER (after 50ms): -->
<div hidden id="S:0">
  <p>[Slow content resolved after 50ms]</p>
</div>
<script>
  $RC('B:0', 'S:0');
</script>
```

With streaming, the shell ships immediately with **both** fallbacks visible.
Then the slow content arrives later as a hidden div + replacement script.

**Why PPR uses `prerender()`**: Because the prelude is a complete, static HTML
document that can be cached and served from a CDN. The only dynamic parts are
the postponed boundaries, which are filled by a separate resume stream at
request time.

---

## Chapter 6: The Complete PPR Pipeline

Here's the full lifecycle, step by step:

### Step 1: Build time — Prospective prerender (fill caches)

```
React tree → Flight renderer → RSC payload stream
                                      ↓
                              CacheSignal tracks all
                              cache reads (beginRead/endRead)
                                      ↓
                              All caches filled → abort
                                      ↓
                              RSC stream is DISCARDED
                              (only side-effect: warm caches)
```

The entire purpose of this step is to populate caches. The output is thrown away.

### Step 2: Build time — Final prerender (produce the shell)

```
React tree → Flight renderer → RSC payload stream
             (warm caches →       ↓
              resolves fast)  Collected as chunks
                                  ↓
                              RSC stream → fed into Fizz
                                  ↓
                              prerender(<App />, { signal })
                                  ↓
                              { prelude, postponed }
                                  ↓
                        prelude = static HTML shell
                        postponed = hole descriptions
```

Caches are warm, so cacheable components resolve within a microtask. The
Flight renderer produces an RSC stream. That stream is fed into React DOM's
`prerender()`, which converts it to HTML + postponed state.

### Step 3: Build time — Package the output

```
prelude HTML  ──→  Saved as static file (e.g., /page.html)
postponed     ──→  Serialized to metadata
RSC chunks    ──→  Inlined as <script> tags in the HTML
                   (framework-specific embedding mechanism)
```

The RSC payload is embedded in the HTML as `<script>` tags, so the client
can hydrate without a separate data fetch. The exact embedding format is a
framework concern — Next.js uses `self.__next_f.push(...)`, React on Rails
will need its own equivalent.

### Step 4: Request time — Serve the shell

```
Browser requests /page
    ↓
CDN/server serves the cached static HTML instantly
    ↓
Browser renders: Header, Nav, Fallbacks, Footer
    ↓
User sees the page structure immediately (fast LCP)
```

### Step 5: Request time — Resume the dynamic holes

```
Server renders the app again with real user data
    ↓
resumeToPipeableStream(<App />, postponed)
    ↓
Produces: hidden <div>s with resolved content
        + $RC scripts to swap fallbacks
    ↓
Streamed to the browser alongside the static shell
    ↓
Browser swaps fallbacks → real content
```

### The complete picture

```
BUILD TIME:
                                    ┌──────────────┐
  App tree ──→ Flight render ──→   │ RSC stream   │
                                    └──────┬───────┘
                                           │
                                    ┌──────▼───────┐
                                    │ Fizz prerender│
                                    └──────┬───────┘
                                           │
                              ┌────────────┼────────────┐
                              ▼            ▼            ▼
                        ┌──────────┐ ┌──────────┐ ┌──────────┐
                        │ Static   │ │Postponed │ │ RSC data │
                        │ HTML     │ │ state    │ │ (scripts)│
                        └──────────┘ └──────────┘ └──────────┘
                              │            │            │
                              └────────────┼────────────┘
                                           ▼
                                    ┌──────────────┐
                                    │  page.html   │
                                    │  (cached)    │
                                    └──────────────┘

REQUEST TIME:

  Browser ──→ CDN serves page.html (instant)
                    │
                    │   Meanwhile:
                    │
  Server ──→ resumeToPipeableStream() ──→ dynamic content stream
                                                │
                                                ▼
                                          Browser swaps
                                          fallbacks → content
```

---

## Chapter 7: The Unclosing Stream Trick

There's a subtle but critical detail in how the RSC stream feeds into the
HTML renderer.

During the final prerender, the RSC stream is collected into memory (an array
of byte chunks). When it's time to feed those bytes into `prerender()` for
HTML generation, they're replayed as an **unclosing stream**:

```js
// Normal stream: delivers all chunks, then CLOSES
new ReadableStream({
  pull(controller) {
    if (i < chunks.length) controller.enqueue(chunks[i++]);
    else controller.close(); // ← stream ends
  },
});

// Unclosing stream: delivers all chunks, then HANGS
new ReadableStream({
  pull(controller) {
    if (i < chunks.length) controller.enqueue(chunks[i++]);
    // ← no close() call — stream stays "open" forever
  },
});
```

**Why?** Because the RSC stream may contain references to components that are
still pending (dynamic holes). If the stream closed, React would error on those
unresolved references — "stream ended but chunk X was never received." By
keeping the stream open, React treats those references as "still loading" and
shows their Suspense fallbacks in the HTML output.

This is the mechanism that makes PPR possible at the React API level: the RSC
stream delivers the static data, keeps hanging references alive, and the HTML
renderer produces a prelude with fallbacks for the hanging parts.

---

## Chapter 8: What the Browser Sees

> **Note:** Chapters 1–7 use vanilla React APIs (`react-dom/static`,
> `react-dom/server`) — no framework code. This chapter shows the
> **framework-level** integration that Next.js adds on top: specifically, how
> the Flight data is inlined into the HTML as `<script>` tags. The
> `self.__next_f` naming convention, the `$RC` replacement script, and the
> `[0]`/`[1]`/`[3]` type codes are all **Next.js-specific implementation
> details**, not React built-ins. React on Rails will need its own equivalent
> inlining mechanism — the wire protocol (Flight rows) is the same, but the
> HTML embedding is a framework concern.

Let's trace what a user's browser receives for a PPR page:

### Initial HTML (from cache, instant):

```html
<!DOCTYPE html>
<html>
  <head>
    ...
  </head>
  <body>
    <div>
      <h1>My App</h1>
      <nav>Home | About | Contact</nav>
      <!--$?--><template id="B:0"></template>
      <p>👤 Loading user...</p>
      <!--/$-->
      <footer>© 2024 MyApp</footer>
    </div>

    <!-- RSC data for hydration: -->
    <script>
      (self.__next_f = self.__next_f || []).push([0]);
    </script>
    <script>
      self.__next_f.push([1, '0:...']);
    </script>
    <script>
      self.__next_f.push([1, '1:...']);
    </script>
  </body>
</html>
```

The browser renders immediately:

- Header ✓
- Navigation ✓
- "👤 Loading user..." (fallback) ✓
- Footer ✓

### Resume stream (arrives slightly later):

```html
<div hidden id="S:0">
  <p>Hello, Abanoub!</p>
</div>
<script>
  $RC('B:0', 'S:0');
</script>
```

The `$RC` script:

1. Finds `<template id="B:0">` in the DOM
2. Finds `<div hidden id="S:0">`
3. Removes the fallback ("👤 Loading user...")
4. Inserts the real content ("Hello, Abanoub!")
5. Changes `<!--$?-->` to `<!--$-->` (marks boundary as resolved)

The user sees the transition: Loading → Hello, Abanoub!

### The `self.__next_f` scripts

These embed the RSC (Flight) data inline in the HTML. Each push is a chunk
of the Flight protocol:

```html
<!-- Initialize the buffer -->
<script>
  (self.__next_f = self.__next_f || []).push([0]);
</script>

<!-- Flight data chunks (the serialized component tree) -->
<script>
  self.__next_f.push([1, '0:{"key":"value"}\n']);
</script>
<script>
  self.__next_f.push([1, '1:["$","div",null,{...}]\n']);
</script>
```

The client-side React code reads these chunks, reconstructs the component
tree, and hydrates the HTML — attaching event handlers and making it
interactive.

---

## Chapter 9: Summary — The Three Outputs

A PPR prerender produces three things:

| Output              | What it is                                                              | When it's used                                       |
| ------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------- |
| **Prelude HTML**    | Complete HTML document with fallbacks for dynamic holes                 | Served instantly from cache                          |
| **Postponed state** | Opaque object describing which boundaries need to be filled             | Passed to `resumeToPipeableStream()` at request time |
| **RSC data**        | Serialized component tree (Flight protocol) embedded as `<script>` tags | Used by the client for hydration                     |

The **prelude** is what the user sees immediately.
The **postponed state** is what the server needs to fill in the gaps.
The **RSC data** is what React needs to make the page interactive.

---

_All examples verified on React 19.2.8, Node.js, macOS._
_Source experiments: 13, 14, 15 in the settle-criterion directory._
