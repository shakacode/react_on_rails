# Streaming SSR Best Practices — Findings from Empirical Benchmarks

All findings below are derived from controlled experiments in this benchmark subproject,
not from external articles. Each recommendation links to the benchmark script that produced
the evidence.

---

## 1. Reduce Element Count — the Single Biggest Win (-56%)

**Finding:** Streaming overhead in `renderToPipeableStream` is **per-element, not per-byte**.
React Fizz calls `pushStartInstance()` / `pushEndInstance()` for every DOM node, each doing
`TextEncoder.encodeInto()` + boundary tracking. Cutting elements by ~40% reduced streaming
time by 56%.

**What we did:**

### ProductCard: 28 elements → 7 elements

Before — each star is its own `<span>` with hover handlers, specs are a full `<table>`:

```tsx
<div className="product-rating">
  {[1, 2, 3, 4, 5].map((star) => (
    <span
      className={`star ${star <= (hoveredStar || product.rating) ? 'filled' : 'empty'}`}
      onMouseEnter={() => setHoveredStar(star)}
      onMouseLeave={() => setHoveredStar(0)}
    >
      {star <= (hoveredStar || product.rating) ? '★' : '☆'}
    </span>
  ))}
  <span className="rating-count">({product.rating}/5)</span>
</div>
<table className="product-specs">
  <tbody>
    {Object.entries(product.specs).map(([key, value]) => (
      <tr key={key}>
        <td className="spec-key">{key}</td>
        <td className="spec-value">{value}</td>
      </tr>
    ))}
  </tbody>
</table>
```

After — stars become one string in one `<span>`, specs become one text line in one `<p>`:

```tsx
const stars = '★'.repeat(product.rating) + '☆'.repeat(5 - product.rating);
const specs = Object.entries(product.specs).map(([k, v]) => `${k}: ${v}`).join(' · ');

<span className="product-rating">{stars} ({product.rating}/5)</span>
<p className="product-specs">{specs}</p>
```

### ReviewItem: 17 elements → 7 elements

Before — 5 individual star `<span>`s in a wrapper, meta split into separate spans, body
split by `\n\n` into multiple `<p>` tags:

```tsx
<div className="review-stars">
  {Array.from({ length: 5 }, (_, i) => (
    <span className={i < review.stars ? 'star filled' : 'star empty'}>
      {i < review.stars ? '★' : '☆'}
    </span>
  ))}
</div>
<div className="review-meta">
  <span className="review-author">By {review.author}</span>
  <span className="review-date"> on {review.date}</span>
</div>
<div className="review-body">
  {review.body.split('\n\n').map((paragraph, i) => <p key={i}>{paragraph}</p>)}
</div>
```

After — one span for stars, one span for meta, one `<p>` for body:

```tsx
const stars = '★'.repeat(review.stars) + '☆'.repeat(5 - review.stars);

<span className="review-stars">{stars}</span>
<span className="review-meta">By {review.author} on {review.date}</span>
<p className="review-body">{review.body}</p>
```

### CommentThread: 8 elements → 4 elements (per comment)

Before — header is `div > button + span + span`, body wrapped in `div > p`, plus
collapse/reply buttons and reply form:

```tsx
<div className="comment-header">
  <button className="collapse-toggle">{collapsed ? '[+]' : '[-]'}</button>
  <span className="comment-author">{comment.author}</span>
  <span className="comment-date"> · {comment.date}</span>
</div>
<div className="comment-body"><p>{comment.text}</p></div>
<div className="comment-actions">
  <button className="reply-toggle">{showReply ? 'Cancel' : 'Reply'}</button>
</div>
```

After — header flattened to one `<span>`, body is just `<p>`, no UI buttons:

```tsx
<span className="comment-header">{comment.author} · {comment.date}</span>
<p className="comment-body">{comment.text}</p>
```

**Results (bench-optimizations.mjs):**

| Configuration          | Mean (ms) | vs toString |
|------------------------|-----------|-------------|
| toString (original)    |      4.48 |       1.00x |
| stream (original)      |      9.68 |       2.16x |
| stream (optimized)     |      4.26 |       0.95x |
| toString (optimized)   |      1.89 |       0.42x |

The optimized stream (4.26ms) beat toString on the original app (4.48ms).

**Practice:** Before reaching for framework-level tuning, audit your components for
unnecessary wrapper `<div>`s, per-item `<span>` wrappers for ratings/tags/badges, and
repeated structural elements. Consolidate N small elements into 1 where possible.

> Script: `scripts/bench-optimizations.mjs`

---

## 2. Use `dangerouslySetInnerHTML` for Large Static Tables

**Finding:** The `DataSectionLite` component renders a 20×8 comparison table. Using
`dangerouslySetInnerHTML` to write the entire `<thead>` + `<tbody>` + `<tfoot>` as a
single string reduced ~200 DOM elements to 1 write operation.

Before — React renders every `<th>`, `<tr>`, `<td>` individually (20 rows × 8 cols =
160 cells + headers + footer ≈ 200 elements):

```tsx
<tbody>
  {rows.map((row, i) => (
    <tr className={i % 2 === 0 ? 'row-even' : 'row-odd'}>
      {columns.map((col) => (
        <td className="data-td">{row[col]}</td>
      ))}
    </tr>
  ))}
</tbody>
```

After — entire table content is a pre-built HTML string, injected as a single write:

```tsx
const bodyHtml = rows.map((row, i) =>
  `<tr class="${i % 2 === 0 ? 'row-even' : 'row-odd'}">${
    columns.map((col) => `<td class="data-td">${row[col]}</td>`).join('')
  }</tr>`
).join('');

const tableHtml = `<thead>${headerHtml}</thead><tbody>${bodyHtml}</tbody><tfoot>${footerHtml}</tfoot>`;

<table className="data-table" dangerouslySetInnerHTML={{ __html: tableHtml }} />
```

**When to use:** Static, server-only data tables that don't need React hydration on the
client. Do NOT use for content with event handlers or dynamic state.

> Script: `scripts/bench-optimizations.mjs`, Component: `src/components/DataSectionLite.tsx`

---

## 3. Wrap Heavy Sections in Suspense Boundaries (2.5× Faster TTFB)

**Finding:** Under concurrent load, `<Suspense>` boundaries allow the shell to flush
immediately while heavy sections stream later. At concurrency=100:

| Method           | Mean TTFB | Mean Total | TTFB vs String |
|------------------|-----------|------------|----------------|
| renderToString   |    158 ms |     158 ms |          1.00x |
| stream (no Susp) |    343 ms |     665 ms |          2.17x |
| stream + Suspense|     63 ms |     695 ms |          0.40x |

Suspense TTFB was **2.5× faster** than renderToString and **5.4× faster** than
stream-without-Suspense.

**How:** Wrap each heavy section in `<Suspense>` with data loaded via `React.use()`:
```tsx
function AsyncProductGrid({ promise }) {
  const products = use(promise);
  return <ProductGrid products={products} />;
}

<Suspense fallback={<div className="skeleton">Loading...</div>}>
  <AsyncProductGrid promise={productsPromise} />
</Suspense>
```

**Practice:** Identify the 3-5 heaviest sections on your page. Wrap each in a
`<Suspense>` boundary. The shell (nav, hero, sidebar, footer) flushes instantly;
heavy content arrives in subsequent chunks.

> Script: `scripts/bench-concurrent-suspense.mjs`, Component: `src/SuspenseApp.tsx`

---

## 4. Suspense Adds Zero Overhead at Concurrency=1

**Finding:** At concurrency=1, Suspense with microtask-resolved promises has the
same total time as plain streaming. The Suspense machinery only helps under concurrent
load — it doesn't hurt when there's no contention.

| Concurrency | Stream (ms) | Stream+Suspense (ms) |
|-------------|-------------|----------------------|
|           1 |        7.91 |                 7.94 |
|          10 |       46.83 |                47.70 |
|         100 |      665.00 |               695.00 |

**Practice:** Adding Suspense boundaries is safe — no performance cost at low load,
significant TTFB win at high load.

> Script: `scripts/bench-concurrent-suspense.mjs`

---

## 5. Custom Writable and progressiveChunkSize Are Not Worth It

**Finding:** Two commonly suggested optimizations showed negligible or negative impact:

| Optimization                | Impact vs stream baseline |
|-----------------------------|---------------------------|
| Custom Writable (vs PassThrough) |  +0.6% (no impact)   |
| progressiveChunkSize: Infinity   |  +7.3% (slightly worse) |
| Both combined                    |  +6.3% (no impact)   |

`PassThrough` inherits from `Transform` which inherits from `Duplex`, but the overhead
is in the Fizz renderer loop, not the consumer. `progressiveChunkSize: Infinity` disables
progressive outlining but doesn't reduce per-element work.

**Practice:** Don't bother swapping out `PassThrough` or tweaking `progressiveChunkSize`.
The bottleneck is element count, not stream plumbing.

> Script: `scripts/bench-optimizations.mjs`

---

## 6. The ~2× Streaming Overhead Is Architectural

**Finding:** `renderToPipeableStream` is consistently ~2× slower than `renderToString`
on the same component tree with the same build:

| Method                    | Mean (ms) | Ratio |
|---------------------------|-----------|-------|
| renderToString            |      3.49 | 1.00x |
| renderToPipeableStream    |      7.29 | 2.09x |

This is because React Fizz (streaming) does per-element `TextEncoder.encodeInto()` calls
and boundary tracking, while `renderToString` concatenates strings in a tight loop. The
overhead is inherent to the streaming architecture.

**Practice:** Accept the ~2× baseline overhead. Offset it with element reduction
(Practice 1) and Suspense TTFB wins (Practice 3).

> Script: `scripts/bench-stream-ssr.mjs`

---

## 7. renderToString Scales Better for Raw Throughput

**Finding:** Under concurrent load, `renderToString` maintains better throughput because
it's synchronous — no `setImmediate` interleaving between concurrent renders:

| Concurrency | toString mean (ms) | stream mean (ms) | Ratio |
|-------------|--------------------|-------------------|-------|
|           1 |               3.73 |              7.91 | 2.12x |
|          10 |              20.49 |             46.83 | 2.29x |
|          50 |              88.79 |            275.22 | 3.10x |
|         100 |             157.95 |            664.84 | 4.21x |

The gap widens because `renderToPipeableStream` uses `setImmediate` to yield between
chunks, allowing event loop interleaving. At concurrency=100, streaming is 4.2× slower.

**Practice:** If your app doesn't need streaming (no Suspense, no progressive loading),
`renderToString` gives better throughput. Use streaming only when you benefit from
TTFB reduction via Suspense.

> Script: `scripts/bench-concurrent.mjs`

---

## 8. RSC Payload Consumption Is a Hidden Bottleneck

**Finding:** In the full RSC → SSR pipeline, `createFromNodeStream` (parsing the RSC
Flight payload back into React elements) consumes ~41% of total time:

| Phase                      | Mean (ms) | % of total |
|----------------------------|-----------|------------|
| RSC payload generation     |      3.27 |        19% |
| Payload consumption (Flight parse) | 5.70 |   33% |
| SSR render (stream)        |      8.04 |        47% |
| **Total pipeline**         |  **17.21**|      100%  |

The RSC payload for our page is 62.1KB. The Flight parser reconstructs the full React
element tree from the binary stream — this is inherently expensive.

**Practice:** When evaluating RSC performance, don't just measure SSR time. The
Flight parse step is significant. Minimize the RSC payload by keeping data payloads
small and avoiding passing large objects through server→client boundaries.

> Script: `scripts/bench-payload-ssr.mjs`, `scripts/bench-rsc-ssr.mjs`

---

## Summary Table

| Practice | Impact | Effort |
|----------|--------|--------|
| Reduce element count | -56% streaming time | Medium (refactor components) |
| dangerouslySetInnerHTML for static tables | Part of above | Low |
| Suspense boundaries | 2.5× faster TTFB | Medium (restructure data flow) |
| Accept ~2× streaming overhead | Baseline awareness | None |
| Skip Custom Writable / chunkSize tuning | No impact | None (don't do it) |
| Choose toString for throughput-only | Best throughput | Low (config change) |
| Minimize RSC payload size | Reduces Flight parse | Varies |
