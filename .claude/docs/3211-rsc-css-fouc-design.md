# Design: Fix CSS FOUC behind `'use client'` boundaries (issue #3211)

Status: approved 2026-06-03. Single PR (patch + renderer + tests).

## Problem

When a true React Server Component renders a `'use client'` boundary, any CSS
imported by that boundary (or its descendants) is **not** preloaded. It loads
only as a side-effect of the JS chunk evaluating — several hundred ms to several
seconds after first paint — producing a visible flash of unstyled content
(FOUC). On slow networks the gap is large enough to be jarring.

Two independent gaps cause this, and **both** must be closed:

1. **Manifest gap.** The patched `react-server-dom-webpack-plugin.js` shipped by
   `react-on-rails-rsc@19.0.4` records only `.js` files for each client
   reference. The `mini-css-extract-plugin` CSS sibling of the same chunk group
   is dropped, so nothing downstream even _knows_ the CSS exists.
2. **Renderer gap.** The Pro RSC renderer never emits any CSS metadata — no
   `<link rel="stylesheet">`, no `preloadStyle`/`preinitStyle`, no `precedence`.
   The only path by which CSS reaches the page is the mini-css-extract runtime
   appending a `<link>` when each JS chunk evaluates — which is exactly the
   too-late path that causes the flicker.

The bug is invisible in `react_on_rails_pro/spec/dummy` historically because its
RSC components used inline `style={{…}}`. PR #3527 (merged) added a real CSS
module behind a `'use client'` boundary (`UseClientCssProbe`) plus a _pending_
manifest spec that traps gap #1.

## Why the fix is entirely in this repo

The upstream package fix (`shakacode/react_on_rails_rsc#35`) is still open and
unpublished. There is no fixed release to depend on. So the manifest half ships
here as a `pnpm patch` against `19.0.4`, mirroring what rsc#35 will eventually
publish; when a fixed release lands we drop the patch.

## The mechanism we rely on: React 19 `<link precedence>`

All RSC frameworks (Next App Router, Vite RSC/Waku, TanStack Start) converge on
one React 19 primitive: render `<link rel="stylesheet" href precedence>` into
the React tree. React 19 then:

- hoists each `<link>` into `<head>`,
- dedupes by `href`, and
- **blocks tree commit until the stylesheet's `load` fires**.

That last property is what makes FOUC structurally impossible. Because we emit
the links _inside the RSC Flight payload_, the same elements re-materialize on
client navigation (`createFromReadableStream`) and React hoists/dedupes/suspends
identically — so SSR and CSR are both covered with no CSR-specific code.

## Design

### Part A — Manifest plugin patch (record CSS)

`patches/react-on-rails-rsc@19.0.4.patch`, applied via pnpm
`patchedDependencies`, rewrites the chunk-collection loop in
`dist/react-server-dom-webpack/cjs/react-server-dom-webpack-plugin.js`.

Current (buggy) inner loop records at most the first `.js` per chunk and `break`s
on the first non-`.js` file, dropping CSS:

```js
chunkGroup.chunks.forEach(function (c) {
  for (const file of c.files) {
    if (!file.endsWith('.js')) break; // drops css
    if (file.endsWith('.hot-update.js')) break;
    chunks.push(c.id, file);
    break; // one js per chunk
  }
});
```

Patched loop keeps JS behavior **byte-identical** (still one `.js` per chunk) and
additionally collects every `.css` file into a sibling `cssChunks` array:

```js
chunkGroup.chunks.forEach(function (c) {
  let jsRecorded = false;
  for (const file of c.files) {
    if (file.endsWith('.hot-update.js')) continue;
    if (!jsRecorded && file.endsWith('.js')) {
      chunks.push(c.id, file);
      jsRecorded = true;
    } else if (file.endsWith('.css')) {
      cssChunks.push(file);
    }
  }
});
```

`recordModule` writes `{ id, chunks, css: cssChunks, name: "*" }`. The manifest
type `ImportManifestEntry` gains an optional `css?: string[]` — backward
compatible; the Flight client runtime ignores it.

Decisions:

- Keep the existing per-chunkGroup overwrite semantics for both `chunks` and
  `css` (no chunk-merge change). Minimal, parity with current JS handling. If a
  test later proves CSS needs cross-chunk-group merge, that is a separate change.
- `css` filenames are bare emitted names (e.g. `css/2696-bb8356be.css`); the
  `moduleLoading.prefix` from the manifest is prepended at render time to form a
  usable href (handles CDN / non-default `publicPath`).

### Part B — Renderer emits `<link rel="stylesheet" precedence>` (SSR)

Injection point: `streamRenderRSCComponent` in
`packages/react-on-rails-pro/src/capabilities/proRSC.ts`, immediately before
`renderToPipeableStream(await reactRenderingResult, …)`.

New pure helper `resolveCssHrefs(manifest): string[]` walks
`filePathToModuleMetadata`, collects every entry's `css`, dedupes via `Set`,
prepends `moduleLoading.prefix`, and returns a **sorted** array (sort = build/test
stability, not cascade semantics). The client manifest is loaded through a small
cached accessor added next to the existing loaders in `cache/` so the renderer
can read it without re-reading the file per request.

Wrap the user tree:

```jsx
const tree = await reactRenderingResult;
const wrapped = React.createElement(
  React.Fragment,
  null,
  ...cssHrefs.map((href) =>
    React.createElement('link', { key: href, rel: 'stylesheet', href, precedence: 'ror-rsc' }),
  ),
  tree,
);
renderToPipeableStream(wrapped, { onError });
```

`precedence` value: `ror-rsc`.

v1 = **eager emission**: emit every client-reference CSS chunk on every RSC
render, in manifest-traversal order. A few KB for the dummy app. Acceptable when
CSS Modules are properly scoped. Tree-walked emission (emit only references
encountered during render, via `prepareDestinationForModule` /
`preinitStyle`) is the documented future optimization, not v1.

### Part C — CSR (`prerender: false`)

No code change. The `<link>`s live inside the RSC Flight payload; on client
navigation they decode and React hoists/dedupes/suspends commit identically.

### Part D — Tests

1. **Manifest (Part A).** Flip the merged `rsc_use_client_css_manifest_spec.rb`
   from `pending` to asserting `metadata.fetch("css")` includes a `.css` href.
2. **Render (Part B/C).** Reuse the existing `UseClientCssProbe`, already
   rendered by `RSCPostsPage/Main.jsx` on the live streaming-RSC route
   `/rsc_posts_page_over_http`. Assert:
   - `<head>` contains `link[rel="stylesheet"][data-precedence]` whose `href`
     resolves to the probe's CSS, and
   - the probe element's computed `background-color` is the styled value
     (`rgb(212, 250, 236)`) after load.

   This is a deterministic, structural assertion of the anti-FOUC mechanism — no
   network-timing race.

## Explicitly out of scope (YAGNI)

- No `mini-css-extract` `insert` override (Next's `_N_E_STYLE_LOAD`).
- No `data-rsc-css-href` markers + post-decode harvest (TanStack pattern).
- No per-route entry-CSS map (Next's `entryCSSFiles`).
- No CSR-side `preinitStyle` (deferred perf optimization, not correctness).
- No throttled "Slow 3G" e2e variant (flaky; the structural assertion above
  covers the regression deterministically). Optional manual follow-up only.
- No non-CSS asset types (fonts, images).
- No separate `RSCFOUCDemo` fixture — the merged `UseClientCssProbe` is the
  single canonical probe.

## Touch points

| File                                                             | Change                                                             |
| ---------------------------------------------------------------- | ------------------------------------------------------------------ |
| `package.json` (`pnpm.patchedDependencies`)                      | register the patch                                                 |
| `patches/react-on-rails-rsc@19.0.4.patch` _(new)_                | collect `.css` into `css[]`                                        |
| `packages/react-on-rails-pro/src/resolveCssHrefs.ts` _(new)_     | manifest → sorted deduped hrefs                                    |
| `cache/` client-manifest accessor                                | cached read of client manifest for the renderer                    |
| `packages/react-on-rails-pro/src/capabilities/proRSC.ts`         | wrap tree with `<link precedence>` before `renderToPipeableStream` |
| `…/spec/dummy/spec/requests/rsc_use_client_css_manifest_spec.rb` | unpend; assert `css`                                               |
| `…/spec/dummy/e2e-tests/`                                        | assert `<link precedence>` in `<head>` + computed bg color         |
| `react_on_rails_rsc` types (consumed)                            | `ImportManifestEntry.css?: string[]` (via patch + local type)      |

## Migration / compatibility

- Manifest extension is backward compatible (`css` optional, JS chunks
  unchanged).
- Apps without `'use client'` boundaries behave identically.
- React Flight client never reads `css`; only the SSR renderer consumes it.

## Test plan (commands)

- `pnpm install` (applies the patch)
- `cd react_on_rails_pro/spec/dummy && bundle exec rake react_on_rails:generate_packs`
- `cd react_on_rails_pro/spec/dummy && pnpm run build:test`
- `bundle exec rspec spec/requests/rsc_use_client_css_manifest_spec.rb` → green (no pending)
- Playwright e2e for `/rsc_posts_page_over_http` → link-in-head + bg-color assertions pass
- `bundle exec rubocop` on changed Ruby; lint changed JS/TS
