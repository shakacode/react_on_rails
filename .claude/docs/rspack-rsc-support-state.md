# State of React Server Components (RSC) Support in Rspack

**Research date:** 2026-04-14
**Researcher:** Claude (Anthropic) for ShakaCode / React on Rails
**Scope:** Rspack itself, independent of React on Rails. What the Rspack team ships, documents, and recommends for RSC as of April 2026.

---

## 1. Executive Summary

As of April 2026, Rspack has **landed a first-class, built-in RSC implementation** on the v2 branch. The core was merged in [PR #12012 "feat: builtin react server component"](https://github.com/web-infra-dev/rspack/pull/12012) on 2026-01-23, shipped in [`v2.0.0-alpha.1`](https://github.com/web-infra-dev/rspack/releases/tag/v2.0.0-alpha.1) (2026-01-27), and has been iteratively improved across the subsequent 2.0 alpha, beta, and RC releases up to [`v2.0.0-rc.1`](https://github.com/web-infra-dev/rspack/releases/tag/v2.0.0-rc.1) (2026-04-08). A dedicated runtime package — [`react-server-dom-rspack`](https://www.npmjs.com/package/react-server-dom-rspack) — is published on npm by Rspack team member Cong-Cong Pan (`SyMind`, ByteDance), separate from `react-server-dom-webpack`. Official documentation lives at [`/guide/tech/rsc`](https://github.com/web-infra-dev/rspack/blob/main/website/docs/en/guide/tech/rsc.mdx) (added via [PR #12919](https://github.com/web-infra-dev/rspack/pull/12919), 2026-02-06). A wrapper plugin for Rsbuild, [`rsbuild-plugin-rsc`](https://github.com/rstackjs/rsbuild-plugin-rsc), provides the ergonomic path.

**Is it production-ready?** No. The feature is shipped behind `rspackExperiments.reactServerComponents`, only in Rspack v2 pre-releases (RC at time of writing, no stable v2 yet), and the wrapper plugin is at `v0.0.3` with a `react-server-dom-rspack` runtime at `v0.0.2`. The Rspack docs explicitly position this as requiring a custom dev server (the built-in dev server cannot host it). No stable Rspack 2.0 release exists as of 2026-04-14 — the first Rspack 2.0 "preview" was targeted at February 2026 per the roadmap, and the project is currently at `v2.0.0-rc.1`.

## 2. Official Rspack Statement on RSC

### 2.1 Roadmap

The Rspack roadmap page lists built-in RSC among the stated goals of Rspack 2.0:

> "Built-in RSC support: Inspired by tools like Parcel, offering built-in support for React Server Components."
> — [`rspack.rs/misc/planning/roadmap`](https://rspack.rs/misc/planning/roadmap)

Accompanying statement about timing:

> "The first preview release is planned for February 2026. We will carefully review every breaking change to ensure a smooth upgrade path."
> — same page

### 2.2 Pre-v2 position (earlier statements, now superseded)

Prior to the 2.0 work, Rspack's earlier public stance was framed as partial/experimental. From Rspack blog text that still surfaces in search results:

> "At ByteDance, they have experimentally supported RSC based on Rspack and validated it in a large web application. In the future, Rspack will provide first-class support for RSC, with more core features to make RSC easier to implement. For example, Rspack now supports the layer feature, which allows to build for multiple environments in a single run."
> — paraphrased from Rspack blog/FAQ surface; [`rspack.rs/blog/`](https://rspack.rs/blog/)

### 2.3 Current confirmation (core PR)

The merged core PR description is the clearest official statement of the current shape. From [PR #12012](https://github.com/web-infra-dev/rspack/pull/12012) (SyMind, merged 2026-01-23):

> "This PR adds built-in RSC plugins to Rspack. We recommend using them via the Rsbuild plugin wrapper available at https://github.com/rstackjs/rsbuild-plugin-rsc."
>
> "The `builtin:swc-loader` has been enhanced to identify `"use client"` and `"use server"` directives. Within the RSC layer, it utilizes the `react-server-dom-rspack` package to transform these modules into the appropriate client and server references required by React."
>
> "Note: This feature must be enabled via rspackExperiments.reactServerComponents."
>
> "RSC requires separate compilation for Server and Client bundles. This PR introduces `ServerPlugin` and `ClientPlugin` (created via `rsc.createPlugins()`), which orchestrate the two compilers."

From Rspack member `chenjiahan` on the predecessor PR [#5824](https://github.com/web-infra-dev/rspack/pull/5824) when it was closed in October 2025:

> "@SyMind is currently designing the built-in RSC support for Rspack. We'll share more details soon."

### 2.4 Relation to Next.js / Vercel partnership

From the [Rspack joins the Next.js ecosystem](https://rspack.rs/blog/rspack-next-partner) blog post (2025-04-10):

> "Rspack will deliver a similar API to bring first-class, high-performance RSC support to the ecosystem."

Important caveat from the same post, re: Next.js App Router (which is where RSC lives in Next):

> "The App Router implementation with next-rspack is slower than Turbopack, and may even be slower than webpack, due to JavaScript plugins that cause heavy Rust–JavaScript communication overhead. The Rspack team has experimentally ported these plugins to Rust, which dramatically improved performance — almost on par with Turbopack."

The Next.js docs themselves flag Rspack as experimental:

> "This feature is currently experimental and subject to change, it is not recommended for production."
> — [Next.js community docs, Rspack integration](https://nextjs.org/docs/community/rspack), lastUpdated 2026-04-10

## 3. The `react-server-dom-rspack` Question

### 3.1 Does the package exist? Yes.

The package `react-server-dom-rspack` exists and is published on npm:

- **Package:** [`react-server-dom-rspack`](https://www.npmjs.com/package/react-server-dom-rspack)
- **Latest version:** `0.0.2` (published 2026-03-14)
- **First publish:** `0.0.1-alpha.1` on 2025-12-17
- **Maintainer:** `symind <dacongsama@live.com>` (Cong-Cong Pan, ByteDance — same person who authored the core Rspack RSC PR)
- **License:** MIT
- **Description (verbatim from npm):** "React Server Components bindings for DOM using Rspack. This is intended to be integrated into meta-frameworks. It is not intended to be imported directly."
- **Weekly downloads:** minimal — the package is not widely used outside Rspack-team example apps
- **Peer dependencies:** `react ^19.1.0`, `react-dom ^19.1.0`, `@rspack/core ^2.0.0-0`

Release timeline (from `npm view react-server-dom-rspack time`):

| Version | Published |
|---|---|
| 0.0.1-alpha.1 | 2025-12-17 |
| 0.0.1-alpha.2 | 2025-12-23 |
| 0.0.1-alpha.3 | 2025-12-23 |
| 0.0.1-alpha.4 | 2025-12-30 |
| 0.0.1-alpha.5 | 2025-12-31 |
| 0.0.1-alpha.6–0.0.1-alpha.8 | 2026-01-04 |
| 0.0.1-alpha.9 | 2026-01-26 |
| 0.0.1-alpha.10 | 2026-01-27 |
| 0.0.1-beta.0 | 2026-02-03 |
| 0.0.1-beta.1 | 2026-02-26 |
| 0.0.2 | 2026-03-14 |

### 3.2 Relationship to `react-server-dom-webpack`

`react-server-dom-rspack` is **not** part of the [`facebook/react`](https://github.com/facebook/react) monorepo. The React team's monorepo ships `react-server-dom-webpack`, `react-server-dom-parcel`, `react-server-dom-turbopack`, `react-server-dom-esm`, `react-server-dom-fb`, and `react-server-dom-unbundled`, but **no `react-server-dom-rspack`** folder exists there (confirmed by [GitHub tree at facebook/react/packages](https://github.com/facebook/react/tree/main/packages), April 2026).

The `react-server-dom-rspack` npm package is maintained independently by the Rspack team member SyMind. Its export map mirrors `react-server-dom-webpack` structurally — `./client`, `./server`, `./static` with `workerd`/`deno`/`worker`/`node`/`edge-light`/`browser` conditional subpaths — so from an API-surface perspective it is designed as a drop-in analog, but it is a separate publish under ByteDance/Rspack stewardship, not an upstream Meta-published package.

### 3.3 Earlier community workaround (pre-package)

Before `react-server-dom-rspack` existed, the only working path was patching `react-server-dom-webpack`. The demo repo [hyf0/server-components-demo-on-rspack](https://github.com/hyf0/server-components-demo-on-rspack) (created 2023-05, last touched 2024) is explicit:

> "I patched the `react-server-dom-webpack` package, you need pnpm to make the patch works."

The patch lives in `/patches/` and requires `npm install --legacy-peer-deps`. That repo pre-dates the Rspack built-in work and should be considered a historical reference, not a current recommendation.

### 3.4 React team position

No public statement from the React team (Sebastian Markbåge, Dan Abramov, Andrew Clark, etc.) blessing or vetoing `react-server-dom-rspack` surfaced in this research. The package is unilateral ByteDance/Rspack work published to npm by a non-`react-bot` maintainer. The React team accepted `react-server-dom-parcel` into the monorepo via [PR #31725 by devongovett](https://github.com/facebook/react/pull/31725) but has not made a similar move for Rspack — at least not publicly and not as of 2026-04-14.

## 4. Rspack v1 vs v2 for RSC

### 4.1 Rspack 1.x capabilities and limits

Rspack 1.x does **not** ship built-in RSC support. The relevant 1.x milestones are supportive primitives rather than the feature itself:

- **1.6 (2025-10-30):** Layer feature stabilized. Per [Announcing Rspack 1.6](https://rspack.rs/blog/announcing-1-6): "Layer is a feature for organizing modules into different layers, which can be useful in advanced scenarios such as React Server Components." The experimental flag `experiments.layers` was deprecated.
- **1.7 (2025-12-31):** Final minor in the 1.x series; focused on stabilizing existing features. [Announcing Rspack 1.7](https://rspack.rs/blog/announcing-1-7) explicitly: "This marks the final minor release in the Rspack 1.x series and focuses on stabilizing existing features. Next, we'll be moving toward Rspack 2.0." No RSC-specific features.
- **Tracking issue [#5318](https://github.com/web-infra-dev/rspack/issues/5318)** ("Blockers for React Server Components") was closed 2024-08-13 with an explicit punt to a full rewrite rather than API-compat fixes: "parser hook is not likely to be supported in near future for performance reason (we'll find a better way to support rsc), we're working [on] full rsc implementation in https://github.com/ScriptedAlchemy/rsnext".
- **Issue [#8469](https://github.com/web-infra-dev/rspack/issues/8469)** (Modern.js team asking for `compilation.addInclude`, `moduleGraph.getExportsInfo`, `AsyncDependenciesBlock`, `chunkGraph.getModuleId`, etc.) was closed 2025-03-26 with "the API provided by Rspack can meet the support of RSC."

So on v1, RSC is only possible by:
- framework-level orchestration using webpack-ish compat APIs plus patches to `react-server-dom-webpack` (the hyf0 demo approach), or
- reaching into the `dy-rsc` experimental branch referenced by `hardfist` in 2024, which never landed as a stable surface.

There is no officially supported path to RSC on Rspack 1.x.

### 4.2 Rspack 2.0 for RSC

RSC is a flagship 2.0 feature. Release timeline of the 2.x pre-releases relevant to RSC:

| Release | Date | RSC-relevant content |
|---|---|---|
| [v2.0.0-alpha.0](https://github.com/web-infra-dev/rspack/releases/tag/v2.0.0-alpha.0) | 2026-01-22 | Scaffolding |
| [v2.0.0-alpha.1](https://github.com/web-infra-dev/rspack/releases/tag/v2.0.0-alpha.1) | 2026-01-27 | **PR #12012 lands** — `rspack_plugin_rsc` crate, `ServerPlugin`, `ClientPlugin`, `rspackExperiments.reactServerComponents`, `react-server-dom-rspack` integration |
| v2.0.0-beta.0 | 2026-02-03 | — |
| beta.1/2 | 2026-02-10/11 | |
| beta.3/4 | 2026-02-25/27 | `feat: making RSC compatible with lazy compilation` (PR #13136) |
| beta.5 | 2026-03-03 | |
| beta.6 | 2026-03-10 | `feat: rsc support disable client api checks` (PR #13263) |
| beta.7 | 2026-03-17 | `feat: support rsc manifest callback` (PR #13277) |
| beta.8 | 2026-03-24 | `fix(rsc): should compile css without use server-entry` (PR #13402) |
| beta.9 | 2026-03-27 | `fix(rsc): tree shaking client barrel` (PR #13472) |
| v2.0.0-rc.0 | 2026-03-31 | |
| [v2.0.0-rc.1](https://github.com/web-infra-dev/rspack/releases/tag/v2.0.0-rc.1) | 2026-04-08 | Latest available at time of writing; no stable 2.0 yet |

As of 2026-04-14 there is **no stable Rspack 2.0 release** — the project is at RC. The `npm view` data confirms `v2.0.0-rc.1` is the newest tag.

Still-open RSC-adjacent work (not yet merged as of research date):

- [#12977](https://github.com/web-infra-dev/rspack/pull/12977) — `feat(mf): layer-aware sharing and runtime scope-array support`
- [#12978](https://github.com/web-infra-dev/rspack/pull/12978) — `feat: add first-class module federation support for RSC`
- [#13203](https://github.com/web-infra-dev/rspack/pull/13203) — `feat(rsbuild): add RSC federation host/remote example`
- [#13204](https://github.com/web-infra-dev/rspack/pull/13204) — `feat(rsbuild): add RSC federation module patterns`
- [#13208](https://github.com/web-infra-dev/rspack/pull/13208), [#13215](https://github.com/web-infra-dev/rspack/pull/13215) — RSC + Module Federation integration

### 4.3 Which version to target

If you intend to build an RSC app with Rspack directly today:

- **Use Rspack 2.x pre-release** (`v2.0.0-rc.1` or later). Rspack 1.x has no supported path.
- Accept the flag `rspackExperiments.reactServerComponents: true` in SWC loader options — it is explicitly experimental.
- Accept the peer dep `react-server-dom-rspack@0.0.2` — described by its own README as "Experimental React Flight bindings for DOM using Rspack. Use it at your own risk."

## 5. Building an RSC App with Rspack — What Works Today

### 5.1 Required dependencies

Taken from the [rsbuild-plugin-rsc react-router example](https://github.com/rstackjs/rsbuild-plugin-rsc/blob/main/examples/react-router/package.json):

```json
{
  "dependencies": {
    "react": "^19.2.4",
    "react-dom": "^19.2.4",
    "react-router": "^7.13.1",
    "react-server-dom-rspack": "0.0.2"
  },
  "devDependencies": {
    "@rsbuild/core": "^2.0.0-rc.0",
    "@rsbuild/plugin-react": "^1.4.6",
    "rsbuild-plugin-rsc": "workspace:*"
  }
}
```

The Rspack docs require React 19.1.0+; the examples are actually pinned to 19.2.x. Rspack must be 2.x (via `@rsbuild/core ^2.0.0-0`).

### 5.2 Minimal plugin setup (from official docs)

From [`website/docs/en/guide/tech/rsc.mdx`](https://github.com/web-infra-dev/rspack/blob/main/website/docs/en/guide/tech/rsc.mdx):

```js
import { experiments } from '@rspack/core';

const { createPlugins, Layers } = experiments.rsc;
const { ServerPlugin, ClientPlugin } = createPlugins();
```

One call to `createPlugins()` returns a paired `(ServerPlugin, ClientPlugin)` that share coordination state.

### 5.3 Dual-compiler config

Rspack's RSC architecture uses **two Compiler instances**, mirroring the webpack pattern but orchestrated by a shared coordinator:

```js
export default [
  {
    target: 'web',
    entry: { main: { import: './src/entry.client.tsx' } },
    plugins: [new ClientPlugin()],
    module: { rules: [rscRule] }
  },
  {
    target: 'node',
    entry: { main: { import: './src/entry.rsc.tsx' } },
    plugins: [new ServerPlugin()],
    module: { rules: [rscRule] }
  }
];
```

Key doc-quoted constraint: "There must be an entry in the Client Compiler with the exact same name as the one in the Server Compiler." This is how manifests line up client references against server-emitted ids.

### 5.4 SWC loader rule

```js
const rscRule = {
  test: /\.(?:js|mjs|jsx|ts|tsx)$/,
  use: {
    loader: 'builtin:swc-loader',
    options: { detectSyntax: 'auto' },
    rspackExperiments: { reactServerComponents: true }
  },
  type: 'javascript/auto'
};
```

The `builtin:swc-loader` detects `"use client"` and `"use server"` directives and, inside the RSC layer, rewrites modules into client-reference and server-reference stubs via `react-server-dom-rspack`.

### 5.5 Layer rules on the server compiler

The server compiler must separate the RSC layer from the SSR layer because they resolve `react` to different builds (the `react-server` export condition yields React's server-only runtime). From the docs:

```js
{
  target: 'node',
  module: {
    rules: [
      { resource: ssrEntry, layer: Layers.ssr },
      {
        resource: rscEntry,
        layer: Layers.rsc,
        resolve: { conditionNames: ['react-server', '...'] }
      },
      {
        issuerLayer: Layers.rsc,
        exclude: ssrEntry,
        resolve: { conditionNames: ['react-server', '...'] }
      }
    ]
  }
}
```

Layer name constants (from [`crates/rspack_plugin_rsc/src/constants.rs`](https://github.com/web-infra-dev/rspack/blob/main/crates/rspack_plugin_rsc/src/constants.rs)):

- `Layers.rsc` → `"react-server-components"`
- `Layers.ssr` → `"server-side-rendering"`

### 5.6 Directives

- **`"use client"`** — transformed to a client reference when imported from a module in the `react-server-components` layer.
- **`"use server"`** — marks server actions; becomes a server reference when imported from the client layer.
- **`"use server-entry"`** — Rspack-specific extension (not React-standard). Marks a Server Component as a "logical page entry point." The built plugin attaches `entryJsFiles` and `entryCssFiles` static properties to the exported component, for frameworks that need to hoist `<script>` / `<link>` tags into the SSR shell.

### 5.7 Dev server

The Rspack docs explicitly state:

> "Rspack's built-in dev server cannot support these requirements."

A custom dev server is required to (a) intercept RSC requests and stream renders, (b) manage per-request server runtime isolation, and (c) relay HMR via `ServerPlugin`'s `onServerComponentChanges` hook:

```js
new ServerPlugin({
  onServerComponentChanges() {
    // Notify client via WebSocket or similar
  }
})
```

### 5.8 The Rsbuild wrapper (recommended path)

The direct Rspack RSC surface is low-level. The Rspack team explicitly recommends [`rsbuild-plugin-rsc`](https://github.com/rstackjs/rsbuild-plugin-rsc):

```bash
npm install rsbuild-plugin-rsc react-server-dom-rspack
```

```js
import { pluginRSC, Layers } from 'rsbuild-plugin-rsc';

export default {
  plugins: [
    pluginRSC({
      layers: {
        ssr: path.join(import.meta.dirname, './src/framework/entry.ssr.tsx'),
      },
    }),
  ],
};
```

Four example apps live in [`examples/`](https://github.com/rstackjs/rsbuild-plugin-rsc/tree/main/examples):

- `client/` — client-driven RSC
- `server/` — full server-rendered app with routing + Server Actions
- `react-router/` — React Router 7 RSC Data Mode
- `static/` — static site generation

Repo stats (as of 2026-04-13): 12 stars, no license file at repo root (plugin is MIT per `package.json`), created 2025-12-23 (same week as `react-server-dom-rspack@0.0.1-alpha.1`).

Plugin dependency versions (from [`packages/plugin-rsc/package.json`](https://github.com/rstackjs/rsbuild-plugin-rsc/blob/main/package.json)):

- Plugin version: `0.0.3`
- Peer deps: `@rsbuild/core ^2.0.0-0`, `react-server-dom-rspack *`
- Declared: `react-server-dom-rspack 0.0.2`, `@rsbuild/core ^2.0.0-rc.2`, `@rslib/core 0.21.0`

### 5.9 Three-bundle architecture equivalent

The "three bundles" framing (RSC bundle / SSR bundle / client bundle) maps to Rspack like this:

| Bundle | Rspack compiler | Layer | Entry example |
|---|---|---|---|
| RSC bundle (React.server runtime) | Server Compiler (`target: 'node'`) | `Layers.rsc` | `./src/entry.rsc.tsx` |
| SSR bundle (React DOM server) | Same Server Compiler, different layer | `Layers.ssr` | `./src/entry.ssr.tsx` |
| Client bundle (hydration) | Client Compiler (`target: 'web'`) | *(no layer needed)* | `./src/entry.client.tsx` |

This is structurally the same as the webpack three-bundle layout Next.js and Waku historically used, but it runs as **two Compiler instances** (not three), with the server compiler internally bifurcated via the `layer` feature.

## 6. Known Issues and Limitations

Drawn from the PR history and docs:

1. **No stable release.** Only available in `v2.0.0-alpha`/`beta`/`rc` pre-releases. Stable 2.0 has not shipped as of 2026-04-14.
2. **Experiments flag required.** `rspackExperiments.reactServerComponents: true` — the feature is explicitly opt-in-experimental.
3. **Built-in dev server does not work.** You must implement your own HTTP server that handles RSC request interception, runtime isolation, and HMR relays.
4. **Module Federation integration is WIP.** Several RSC + MF PRs (#12977, #12978, #13203, #13204, #13208, #13215) remain open; first-class MF + RSC is not yet in RC.
5. **Windows path bugs have existed.** [PR #12969](https://github.com/web-infra-dev/rspack/pull/12969) "fix: RSC fails to properly handle Windows paths" (2026-02-06) indicates path-handling regressions.
6. **Lazy compilation compatibility was fixed only recently.** [PR #13136](https://github.com/web-infra-dev/rspack/pull/13136), 2026-02-27.
7. **CSS handling in RSC layer had bugs.** [PR #13402](https://github.com/web-infra-dev/rspack/pull/13402) "should compile css without use server-entry" (2026-03-19).
8. **Tree-shaking regressions on client barrels.** [PR #13472](https://github.com/web-infra-dev/rspack/pull/13472), 2026-03-26.
9. **`react-server-dom-rspack` is pinned to `0.0.2`** with its README self-describing as experimental ("Use it at your own risk").
10. **`rsbuild-plugin-rsc` is pinned to `0.0.3`** with only 12 GitHub stars — almost no external adoption yet.
11. **Next.js App Router on Rspack is slow.** Per the Rspack+Vercel partnership blog, "App Router implementation with next-rspack is slower than Turbopack, and may even be slower than webpack." That means for Next.js users the RSC pipeline that *ships in production* today (Next App Router) is measurably degraded on Rspack unless the Rspack team's Rust port of the Next plugins is activated.
12. **Documentation is thin.** The `rsc.mdx` guide is a single file (~287 lines for the English version, landed 2026-02-06); docs were being iterated as recently as [PR #13289](https://github.com/web-infra-dev/rspack/pull/13289) on 2026-03-11. Breadth and cookbook coverage do not approach Next.js or Parcel's RSC docs.
13. **No React team blessing.** `react-server-dom-rspack` is not in `facebook/react`, unlike `react-server-dom-webpack`/`-parcel`/`-turbopack`. There is no upstream commitment to API stability paralleling the canary React renderers.

## 7. Community Resources

### 7.1 Official / Rspack-team

- [rsbuild-plugin-rsc](https://github.com/rstackjs/rsbuild-plugin-rsc) — official wrapper, 4 examples
- [Rspack 2.0 RSC guide (English)](https://github.com/web-infra-dev/rspack/blob/main/website/docs/en/guide/tech/rsc.mdx)
- [Core PR #12012 `feat: builtin react server component`](https://github.com/web-infra-dev/rspack/pull/12012)
- [`react-server-dom-rspack` on npm](https://www.npmjs.com/package/react-server-dom-rspack)
- [`crates/rspack_plugin_rsc`](https://github.com/web-infra-dev/rspack/tree/main/crates/rspack_plugin_rsc) — Rust source

### 7.2 Historical / pre-built-in

- [hyf0/server-components-demo-on-rspack](https://github.com/hyf0/server-components-demo-on-rspack) — 2023 patch-based demo. No SSR. Explicitly not production-ready. Fork of `reactjs/server-components-demo`.
- [JiangWeixian/rspack-rsc-playground](https://github.com/JiangWeixian/rspack-rsc-playground) — referenced in 2024 by the author of the closed [PR #5824](https://github.com/web-infra-dev/rspack/pull/5824). That original PR proposal was closed on 2025-10-21 in favor of SyMind's redesign.
- [ScriptedAlchemy/rsnext](https://github.com/ScriptedAlchemy/rsnext) — referenced by Rspack member `hardfist` in 2024 as "full rsc implementation" experiment. Pre-dates 2.0 built-in support.

### 7.3 Frameworks that use Rspack for RSC (or could)

- **Modern.js** (ByteDance, built on Rspack/Rsbuild) — was the original driver of the missing-APIs issue [#8469](https://github.com/web-infra-dev/rspack/issues/8469); confirmed "the API provided by Rspack can meet the support of RSC" at close (2025-03-26). Modern.js ships its own Rspack-based RSC integration, though public documentation of it is sparse.
- **Next.js** — via the experimental [`next-rspack`](https://nextjs.org/docs/community/rspack) plugin. App Router RSC works functionally (≈96% integration test pass rate per [arewerspackyet.com](https://arewerspackyet.com)), but slower than both Turbopack and webpack on App Router today per the Rspack team's own admission.
- **Waku** — uses Vite/Rolldown, not Rspack. [Waku blog: Introducing Waku](https://waku.gg/blog/introducing-waku).
- **React Router 7 RSC Data Mode** — supported via `rsbuild-plugin-rsc` example; React Router's own canonical path remains Vite (`@vitejs/plugin-rsc`).

### 7.4 ShakaCode / React on Rails context

- [shakacode/gumroad-rsc](https://github.com/shakacode/gumroad-rsc) — public comparison repo Justin Gordon references in [react_on_rails#3128](https://github.com/shakacode/react_on_rails/issues/3128). Stack: Rails + React 19 + Shakapacker + Rspack + React on Rails Pro + RSC on one dashboard slice, Inertia control on another. Findings (per issue body, April 2026):
  - Cold production build: `25.19s → 11.25s` (webpack → Rspack)
  - Cold dev build: `16.24s → 5.28s`
  - RSC route vs Inertia route: `-12.6%` navigation duration, `-8.9%` LCP, `-80%` client JS request count; but `+7.6%` `responseEnd` — RSC is winning user-visible metrics but still paying a server renderer/streaming cost.

### 7.5 Noteworthy discussions and newsletters

- [vercel/next.js discussion #77716 — "RSC and Build Tools: Should I Use Rspack or Wait for Turbopack?"](https://github.com/vercel/next.js/discussions/77716) — Next.js maintainer `icyJoseph`: "support for Rspack in Next.js is still an ongoing development."
- [vercel/next.js discussion #77800 — "Rspack plugin feedback"](https://github.com/vercel/next.js/discussions/77800) — the official feedback thread for `next-rspack`.
- [This Week In React #266](https://dev.to/sebastienlorber/this-week-in-react-266-dos-shadcn-skills-rspack-expo-55-beta-hermes-expo-router-tc39-2h0p) — contemporary coverage.

## 8. Comparison with Webpack's RSC Support

### 8.1 What webpack has that Rspack still doesn't

1. **Upstream React-team-maintained runtime.** `react-server-dom-webpack` ships from `facebook/react` under Meta maintainership, with matched canaries pinned to React versions via `next`/`canary`/`experimental` dist-tags. `react-server-dom-rspack` is maintained by a single ByteDance engineer, with a `0.0.2` "stable" tag and 13 total published versions as of this writing.
2. **Longer production track record.** Webpack's RSC plugin (`ReactFlightWebpackPlugin`) has been powering Next.js App Router in production since late 2022. Rspack's built-in RSC plugin is ~3 months old at this writing (merged January 2026).
3. **Broader framework adoption.** Next.js (millions of prod apps), Remix's RSC experiments, and others historically targeted webpack. Rspack RSC has essentially zero public production deployments.
4. **`ContextModuleFactory` and `NormalModuleFactory` parser hooks** — webpack's hooks used by `ReactFlightWebpackPlugin`. Per tracking issue [#5318](https://github.com/web-infra-dev/rspack/issues/5318): "parser hook is not likely to be supported in near future for performance reason." Rspack works around this with its own Rust-native implementation rather than exposing webpack-parity hooks.

### 8.2 Where Rspack is already ahead

1. **Native Rust implementation.** `rspack_plugin_rsc` is written in Rust (`ServerPlugin`, `ClientPlugin`, coordinator, manifest runtime, SWC-native directive detection). This sidesteps the JS-plugin RPC overhead that has hurt `next-rspack` App Router perf — once the plugin is Rust-native, it benefits from Rspack's parallelism.
2. **Built-in coordination.** The paired-plugin model with a shared coordinator crate (see [`crates/rspack_plugin_rsc/src/coordinator.rs`](https://github.com/web-infra-dev/rspack/blob/main/crates/rspack_plugin_rsc/src/coordinator.rs)) means server/client manifest alignment is handled by Rspack itself, whereas webpack leaves it to the framework.
3. **Inherits Rspack's cold-build speed.** Per the Gumroad comparison ([#3128](https://github.com/shakacode/react_on_rails/issues/3128)), cold production builds went from ~25s to ~11s on a real Rails app just by swapping webpack → Rspack. RSC-specific throughput numbers are not yet published by the Rspack team.
4. **`"use server-entry"` directive.** Rspack invented a third directive for entry-point metadata emission (attaching `entryJsFiles` / `entryCssFiles` to exported components). Not a React standard, but useful for framework authors. Webpack has no equivalent built-in.
5. **Layer-aware chunking by default.** Rspack's stable `layer` feature (since 1.6) gives RSC a first-class primitive; webpack has layers via `experiments.layers` but with less ergonomic stability guarantees.

### 8.3 Neither is ahead — both share

- Dependence on the directive model (`"use client"`, `"use server"`).
- Dependence on `react ^19.1.0` and compatible `react-dom` for RSC.
- Need for a framework layer to produce a usable app; the bundler alone does not ship a dev server, router, streaming renderer, or server-action router.

## 9. Outlook / Roadmap

### 9.1 Immediate (Q2 2026)

- Ship **Rspack 2.0 stable.** Currently at `v2.0.0-rc.1` (2026-04-08). [PR #13697 "chore(release): release 2.0.0-rc.2"](https://github.com/web-infra-dev/rspack/pull/13697) is open as of 2026-04-14.
- Continue stabilizing `react-server-dom-rspack` (currently `0.0.2`). No public roadmap for hitting `1.0.0`; trajectory is about 1 version per 2–6 weeks since December 2025.
- Iterate on documentation. The [rsc.mdx guide](https://github.com/web-infra-dev/rspack/blob/main/website/docs/en/guide/tech/rsc.mdx) has been rewritten multiple times (PRs #12919, #13289, ongoing).

### 9.2 Near-term (H2 2026, inferred from open PRs)

- **First-class Module Federation + RSC.** Merge of PRs #12977, #12978, #13203, #13204, #13208, #13215. ByteDance's Module Federation team (`ScriptedAlchemy` et al.) is actively pushing this.
- **Additional hooks for framework authors** — `onServerComponentChanges` is one; more will likely follow as framework consumers report gaps.

### 9.3 Longer-term (unclear timeline)

- **Upstream acceptance of `react-server-dom-rspack` into `facebook/react`.** No public signal this is planned or agreed. Compare with `react-server-dom-parcel` (upstreamed via devongovett's [PR #31725](https://github.com/facebook/react/pull/31725)) and `react-server-dom-turbopack` (in Vercel/React coordination).
- **Production-grade adoption by a shipping framework.** Modern.js is the obvious candidate, but its public RSC positioning is quiet. Next.js's path forward is Turbopack, not Rspack, for RSC. Without a big framework shipping Rspack RSC in production, it will stay `experimental`.

### 9.4 External dependencies

- **React team direction.** If React's RSC API surface shifts (e.g., removing `"use server-entry"` extensions, changing reference IDs), `react-server-dom-rspack` must follow. Being out-of-tree in `facebook/react` is a structural risk.
- **React 19 / 20 cadence.** `react-server-dom-rspack` has `peerDependencies.react ^19.1.0`. Any React 20 RSC changes will require a new major.
- **Next.js's Turbopack-vs-Rspack balance.** Vercel's preferred RSC path is Turbopack. Rspack + Next App Router is degraded today per the Rspack team's own post. This caps "how much Next work it's worth Rspack doing" until/unless the Rust-plugin port lands stably.

## 10. References

All URLs consulted, grouped by type. Dates show the content's "as of" when known; accessed 2026-04-14 unless otherwise stated.

### 10.1 Rspack official

- [rspack.rs — homepage](https://rspack.rs/)
- [rspack.rs/misc/planning/roadmap — Roadmap](https://rspack.rs/misc/planning/roadmap)
- [rspack.rs/guide/tech/react — React guide](https://rspack.rs/guide/tech/react)
- [rspack.rs/guide/features/layer — Layer guide](https://rspack.rs/guide/features/layer)
- [rspack.rs/config/experiments — Experiments config](https://rspack.rs/config/experiments)
- [rspack.rs/blog/ — Blog index](https://rspack.rs/blog/)
- [rspack.rs/blog/announcing-1-6 — Rspack 1.6 announcement, 2025-10-30](https://rspack.rs/blog/announcing-1-6)
- [rspack.rs/blog/announcing-1-7 — Rspack 1.7 announcement, 2025-12-31](https://rspack.rs/blog/announcing-1-7)
- [rspack.rs/blog/rspack-next-partner — Rspack joins Next.js ecosystem, 2025-04-10](https://rspack.rs/blog/rspack-next-partner)
- [v2.rspack.rs/ — Rspack 2 docs](https://v2.rspack.rs/)
- [github.com/web-infra-dev/rspack — main repo](https://github.com/web-infra-dev/rspack)
- [github.com/web-infra-dev/rspack/releases — all releases](https://github.com/web-infra-dev/rspack/releases)
- [github.com/web-infra-dev/rspack/blob/main/website/docs/en/guide/tech/rsc.mdx — RSC guide source](https://github.com/web-infra-dev/rspack/blob/main/website/docs/en/guide/tech/rsc.mdx)
- [github.com/web-infra-dev/rspack/tree/main/crates/rspack_plugin_rsc — Rust plugin source](https://github.com/web-infra-dev/rspack/tree/main/crates/rspack_plugin_rsc)

### 10.2 Rspack PRs and Issues

- [PR #5824 — feat: rsc plugin (closed 2025-10-21)](https://github.com/web-infra-dev/rspack/pull/5824)
- [PR #12012 — feat: builtin react server component (merged 2026-01-23)](https://github.com/web-infra-dev/rspack/pull/12012)
- [PR #12919 — docs: add guide for React Server Components (merged 2026-02-06)](https://github.com/web-infra-dev/rspack/pull/12919)
- [PR #13136 — feat: making RSC compatible with lazy compilation (merged 2026-02-27)](https://github.com/web-infra-dev/rspack/pull/13136)
- [PR #13263 — feat: rsc support disable client api checks (merged 2026-03-09)](https://github.com/web-infra-dev/rspack/pull/13263)
- [PR #13277 — feat: support rsc manifest callback (merged 2026-03-11)](https://github.com/web-infra-dev/rspack/pull/13277)
- [PR #13289 — chore: docs for config rsc build entries (merged 2026-03-11)](https://github.com/web-infra-dev/rspack/pull/13289)
- [PR #13402 — fix(rsc): should compile css without use server-entry (merged 2026-03-19)](https://github.com/web-infra-dev/rspack/pull/13402)
- [PR #13472 — fix(rsc): tree shaking client barrel (merged 2026-03-26)](https://github.com/web-infra-dev/rspack/pull/13472)
- [Issue #5318 — [Tracking] Blockers for React Server Components (closed 2024-08-13)](https://github.com/web-infra-dev/rspack/issues/5318)
- [Issue #8469 — missing APIs for RSC framework support (closed 2025-03-26)](https://github.com/web-infra-dev/rspack/issues/8469)
- [Discussion #9270 — Planned breaking changes for Rspack 2.0](https://github.com/web-infra-dev/rspack/discussions/9270)

### 10.3 npm packages

- [react-server-dom-rspack on npm](https://www.npmjs.com/package/react-server-dom-rspack) — maintainer: `symind`, latest `0.0.2` (2026-03-14)
- [react-server-dom-webpack on npm](https://www.npmjs.com/package/react-server-dom-webpack) — maintainer: `react-bot@meta.com`, latest `19.2.5` (2026-04-08)
- [@rspack/core on npm](https://www.npmjs.com/package/@rspack/core)

### 10.4 Related projects

- [rstackjs/rsbuild-plugin-rsc — official Rsbuild wrapper](https://github.com/rstackjs/rsbuild-plugin-rsc), stars: 12, created 2025-12-23
- [rstackjs/rsbuild-plugin-rsc/tree/main/examples — 4 examples](https://github.com/rstackjs/rsbuild-plugin-rsc/tree/main/examples)
- [hyf0/server-components-demo-on-rspack — 2023 patch-based demo](https://github.com/hyf0/server-components-demo-on-rspack)
- [JiangWeixian/rspack-rsc-playground — 2024 playground](https://github.com/JiangWeixian/rspack-rsc-playground)
- [ScriptedAlchemy/rsnext — 2024 full RSC experiment](https://github.com/ScriptedAlchemy/rsnext)

### 10.5 Next.js / Vercel

- [Next.js community docs on Rspack](https://nextjs.org/docs/community/rspack) — lastUpdated 2026-04-10
- [Discussion #77716 — RSC and Build Tools: Should I Use Rspack or Wait for Turbopack?](https://github.com/vercel/next.js/discussions/77716)
- [Discussion #77800 — Rspack plugin feedback](https://github.com/vercel/next.js/discussions/77800)
- [arewerspackyet.com — next-rspack test progress (99.3% as of access)](https://arewerspackyet.com)

### 10.6 Competitor bundler RSC approaches

- [Parcel RSC recipe](https://parceljs.org/recipes/rsc/)
- [Parcel v2.14.0 blog — beta RSC](https://parceljs.org/blog/v2-14-0/)
- [PR #31725 — Implement react-server-dom-parcel (facebook/react)](https://github.com/facebook/react/pull/31725)
- [@vitejs/plugin-rsc on npm](https://www.npmjs.com/package/@vitejs/plugin-rsc)
- [vitejs/vite-plugin-react/tree/main/packages/plugin-rsc](https://github.com/vitejs/vite-plugin-react/tree/main/packages/plugin-rsc)
- [facebook/react packages dir — no react-server-dom-rspack](https://github.com/facebook/react/tree/main/packages)

### 10.7 ShakaCode / React on Rails context

- [shakacode/react_on_rails issue #3128 — Gumroad comparison](https://github.com/shakacode/react_on_rails/issues/3128)
- [shakacode/gumroad-rsc — public comparison repo](https://github.com/shakacode/gumroad-rsc)

### 10.8 People cited

- **SyMind / Cong-Cong Pan** (ByteDance) — author of Rspack's built-in RSC and of `react-server-dom-rspack`. [GitHub profile](https://github.com/SyMind).
- **chenjiahan** — Rspack team member, confirmed RSC design direction on PR #5824.
- **hardfist** — Rspack team member, originally triaged blocker issue #5318.
- **yimingjfe (Ming)** — Modern.js / ByteDance, opened missing-APIs issue #8469.

---

**Flagged uncertainties (as of 2026-04-14):**

- It is not clear from public documentation whether the Rspack team intends to upstream `react-server-dom-rspack` into `facebook/react`. No PR or public proposal has been observed.
- No benchmark data has been published by the Rspack team specifically comparing their built-in RSC vs webpack's `ReactFlightWebpackPlugin` on RSC-specific workloads (manifest generation, streaming, HMR). Performance claims so far are general Rspack-vs-webpack, not RSC-specific.
- The stable Rspack 2.0 release date is not locked — February 2026 was the "first preview" target per the roadmap, and the project is at RC as of April 2026. A firm GA date has not been publicly committed.
- `react-server-dom-rspack`'s API stability guarantees are undocumented; the README is ~1 line of "Use it at your own risk."
