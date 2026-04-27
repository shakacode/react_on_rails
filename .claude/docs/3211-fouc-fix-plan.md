# Plan: Fix CSS FOUC on `'use client'` boundaries (issue #3211)

## Problem

When a client component imports a CSS Module (e.g. `import s from './x.module.scss'`), the rendered SSR HTML contains `<div class="hashed-class-name">` but no stylesheet for it. The CSS only loads as a side effect of the JS chunk evaluating (mini-css-extract runtime), producing a flash of unstyled content. In production with our current pipeline the symptom escalates to a hydration error because the React Flight client manifest doesn't fully record the JS chunks either.

## Why the existing chunk-skip patch (already shipped here) only half-fixes it

Our patched plugin now records `{ id, chunks: [chunkId, jsFile] }` correctly, so webpack's chunk runtime pulls in `chunkId.css` alongside `chunkId.js`. That removes FOUC on fast networks because both finish loading together and React 19's chunk-load gate keeps the client component from committing until the JS arrives. On slow networks (or when the SSR'd hidden subtree is revealed via `$RC()` before the CSS link finishes downloading), the flicker is still observable. The deeper fix has to put the stylesheets into `<head>` from the SSR HTML itself, not via post-load chunk fetching.

## How leading frameworks do it (research summary)

All RSC frameworks converge on the same React 19 primitive:

- **`<link rel="stylesheet" href={...} precedence="...">`** rendered into the React tree.
- React 19 hoists these into `<head>`, dedupes by `href`, and **blocks tree commit until the stylesheet's `load` event fires**.
- That single mechanism kills FOUC on both SSR and CSR paths because the same `<link>` elements re-execute when the RSC payload is decoded on the client.

What differs is _how each framework discovers which CSS to emit_:

- **Next.js App Router** (`flight-manifest-plugin.ts`): manifest stores `entryCSSFiles[entryName] = [{ path, ... }]`. SSR walks the rendered tree, looks up CSS for each client reference encountered, emits `<link rel="stylesheet" precedence="next">` via `render-css-resource.tsx`. Plus `preloadStyle()` for early discovery.
- **Vite RSC plugin (Waku)**: virtual modules emit `React.createElement('link', { rel:'stylesheet', precedence:'vite-rsc/client-reference', href, 'data-rsc-css-href': href })`.
- **TanStack Start**: post-decodes the RSC tree on the client, harvests `data-rsc-css-href` markers, then calls `ReactDOM.preinit(href, { as:'style', precedence:'high' })`.
- **Upstream `react-server-dom-webpack`**: deliberately does **not** handle CSS — it's framework responsibility. The reference fixture (`fixtures/flight/config/webpack.config.js`) post-processes webpack stats to attach a parallel `css` array per entry.

The de-facto standard is: extend the manifest with CSS hrefs + emit `<link precedence>` from the server tree. Everything else is variation.

## The minimal, ROR-Pro-shaped fix (3 parts)

### Part A — Plugin: record CSS filenames in the manifest

Extend our existing `patches/react-on-rails-rsc@19.0.4.patch` to also collect bare `.css` filenames. Sibling field, JS chunks unchanged so React's flight client runtime keeps working:

```js
// In the chunkGroup.chunks loop, in addition to the existing .js collection:
const cssFiles = [];
chunkGroup.chunks.forEach((c) => {
  for (const file of c.files) {
    if (file.endsWith('.css')) cssFiles.push(file);
  }
});

// In recordModule, MERGE css across chunk groups (same dedup logic as `chunks`):
const existing = filePathToModuleMetadata[href];
if (existing) {
  for (const cssFile of cssFiles) {
    if (!existing.css.includes(cssFile)) existing.css.push(cssFile);
  }
  // ...existing chunks merge logic...
} else {
  filePathToModuleMetadata[href] = {
    id,
    chunks: [chunkId, jsFile], // unchanged
    css: cssFiles.slice(), // NEW
    name: '*',
  };
}
```

The manifest type becomes `{ id, chunks, css?, name }` — `css` is optional so older readers ignore it safely. **Note**: these are bare emitted filenames (e.g. `css/2696-bb8356be.css`); the `moduleLoading.prefix` from the manifest must be prepended to form a usable href.

### Part B — RSC payload: emit `<link rel="stylesheet" precedence>` from a server-component wrapper

The injection point is **`packages/react-on-rails-pro/src/capabilities/proRSC.ts`** (NOT `streamServerRenderedReactComponent.ts`). We need the `<link>`s to be encoded _inside_ the RSC payload so that:

- on initial SSR, when the RSC payload is decoded into the outer React DOM tree, React DOM hoists/suspends them in `<head>`;
- on CSR navigation, the same payload arrives via fetch, decodes, and React again hoists them.

`proRSC.ts` already has the manifest in scope before it builds the RSC renderer. The change:

1. Build a deterministic, sorted CSS-href list from the manifest:

   ```ts
   import { resolveCssHrefs } from './resolveCssHrefs';
   const cssHrefs = resolveCssHrefs(manifest); // returns string[] of public-path-prefixed, deduped, sorted hrefs
   ```

   `resolveCssHrefs` walks `filePathToModuleMetadata`, collects every `css` filename, dedupes via `Set`, prepends `manifest.moduleLoading.prefix`, and returns a sorted array (sort = build/test stability, not cascade semantics).

2. Wrap the user's component before `renderToPipeableStream`:

   ```jsx
   import RscCssLinks from '../RscCssLinks';
   const wrapped = (
     <>
       <RscCssLinks hrefs={cssHrefs} />
       {userComponent}
     </>
   );
   const stream = renderToPipeableStream(wrapped, manifest);
   ```

3. `RscCssLinks` (new file `packages/react-on-rails-pro/src/RscCssLinks.tsx`) is a tiny server-only component:

   ```jsx
   const RscCssLinks = ({ hrefs }) => (
     <>
       {hrefs.map((href) => (
         <link key={href} rel="stylesheet" href={href} precedence="ror-rsc" />
       ))}
     </>
   );
   export default RscCssLinks;
   ```

React 19 hoists each `<link>` into `<head>`, dedupes by `href`, and blocks commit until each stylesheet loads. FOUC eliminated.

**v1 tradeoff (eager emission)**: this loads every client-reference CSS chunk on every page, in chunkGroup-traversal order rather than route-encounter order. For the Pro dummy app with ~15 small CSS Modules, total CSS overhead is a few KB. Acceptable assuming CSS Modules are properly scoped (no global selectors leaking from one module into another's specificity battle). If global CSS lives in a `'use client'` boundary, an unrelated route loading it could cause cascade order surprises — call this out in PR review and document.

**Deferred optimizations** (not required for v1, listed so we know the upgrade path):

- Tree-walked emission: hook a custom `prepareDestinationForModule` (in the React Flight server config) so each client reference encountered during render calls `ReactDOM.preinitStyle(href, { precedence: 'ror-rsc' })`. This avoids over-emission. Requires patching `react-on-rails-rsc/dist/.../ReactFlightServerConfigDOM.js`.
- CSR-side `ReactDOM.preinit(href, { as: 'style', precedence: 'ror-rsc' })` after `createFromReadableStream` decodes the payload. Earlier fetch-start during router navigation; not a correctness fix.

### Part C — CSR: nothing extra

The same `<link>` elements live in the RSC payload. When `transformRSCStreamAndReplayConsoleLogs.ts` feeds the payload to `createFromReadableStream`, React decodes them and re-renders them client-side. React 19 hoists/dedupes/suspends commit identically. `RSCRoute.tsx`/`getReactServerComponent.client.ts` need zero changes.

This is the property of `<link precedence>` that makes our pipeline simpler than Next's: no `_N_E_STYLE_LOAD`, no mini-css-extract `insert` override, no `ReactDOM.preinit` after-decode call. Server-emitted links work for both SSR hydration and post-mount router navigation.

## What we explicitly do _not_ do (anti-over-engineering list)

- **No** mini-css-extract `insert` override (Next's `_N_E_STYLE_LOAD`). The eager `<link precedence>` already covers what the CSS chunk loader would have done.
- **No** `data-rsc-css-href` markers + post-decode harvest (TanStack pattern). Simpler to emit the link directly server-side.
- **No** per-route entry CSS map (Next's `entryCSSFiles[chunkEntryName]`). Our auto-load packs are 1-component-per-pack, so a flat per-module css array is sufficient.
- **No** `ReactDOM.preinitStyle` from CSR-side decode (deferred — useful as a perf optimization to start CSS fetch earlier during router navigation, but not needed for correctness).
- **No** support for non-CSS asset types (fonts inlined, images) — out of scope.
- **No** dev-mode HMR cleanup like vite-rsc's `RemoveDuplicateServerCss`. Dev uses mini-css-extract style runtime which already injects inline `<style>`; the new `<link>`s harmlessly add a second copy that React dedupes.

## Touch points

| File                                                                                                                                      | Change                                                                                                                                   |
| ----------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `patches/react-on-rails-rsc@19.0.4.patch`                                                                                                 | extend to also collect `.css` filenames into a sibling `css` array, with the same multi-chunk-group merge logic                          |
| `packages/react-on-rails-pro/src/resolveCssHrefs.ts` _(new)_                                                                              | walk manifest, dedupe, prepend `moduleLoading.prefix`, sort, return `string[]`                                                           |
| `packages/react-on-rails-pro/src/RscCssLinks.tsx` _(new, server-only)_                                                                    | tiny server component emitting `<link rel="stylesheet" precedence="ror-rsc" href={…}/>` per href                                         |
| `packages/react-on-rails-pro/src/capabilities/proRSC.ts` (~line 67-78)                                                                    | call `resolveCssHrefs(manifest)`, wrap `userComponent` with `<RscCssLinks hrefs={…}>{userComponent}</…>` before `renderToPipeableStream` |
| `streamServerRenderedReactComponent.ts`, `RSCRoute.tsx`, `getReactServerComponent.client.ts`, `transformRSCStreamAndReplayConsoleLogs.ts` | **no change**                                                                                                                            |

## Test plan

- Existing Playwright `e2e-tests/rsc_fouc_demo.spec.ts` already asserts:
  1. `head link[rel="stylesheet"][data-precedence][href*="StyledClientCard"]` (post-fix expected), and
  2. computed `background-color: rgb(255, 0, 128)` after page load.
     Pre-fix: assertion 1 fails. Post-fix: both pass.
- Add a **"Slow 3G" throttled variant** that asserts the card never paints with the default background — that's the FOUC regression test.
- Add a **public-path test**: build the dummy with a non-default `output.publicPath` (e.g. `/cdn/assets/`) and assert the emitted `<link>` href is fully qualified, not bare. This catches the most likely production break (CDN/asset-host configurations) flagged by codex review.

## Migration / compatibility

- Manifest extension is backward-compatible (`css` is optional, JS chunks list is unchanged).
- Existing apps without `'use client'` boundaries behave identically.
- React Flight client doesn't read the `css` field — we only consume it on the SSR side.

## Estimated effort

- Plugin patch extension: ~30 lines, half a day
- `RscCssLinks` + wiring: ~50 lines, half a day
- Updating existing Playwright test + adding throttled variant: ~20 lines, 1 hour
- Plugin-side upstream PR to react-on-rails-rsc: separate workstream, can be follow-up

Total: ~1 day of implementation, ship-ready.
