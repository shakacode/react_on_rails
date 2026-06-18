# 03 — The `react-on-rails-rsc` npm Package, React 19 Coupling, and webpack vs rspack

> 🧒 ELI5 boxes for the ideas, 🛠️ real‑thing sections for exact versions, exports, and file paths.
> This is the doc that answers your three sub‑questions: **why a separate npm package?**, **how does
> it correlate to React 19 versions?**, and **webpack vs rspack — what actually differs?**

---

## 1. 🧒 ELI5: Why is there a separate `react-on-rails-rsc` package at all?

React Server Components need a special engine that does two bundler‑specific things:

1. **Serialize** the server tree into the "order ticket" (the Flight payload).
2. **Resolve** the "you already have kit #47" references — i.e. at runtime, _go fetch the right
   browser chunk for a client component._ "Go fetch chunk #47" is written **differently for each
   bundler** (`__webpack_require__` vs `__turbopack_require__` vs Parcel's loader).

That engine is React's own internal package, **`react-server-dom-webpack`**. But — and this is the
crux — **React does not publish a normal, stable, standalone version of it that you can just depend
on.** It's built _inside React's monorepo_, locked to one exact React version, reaching into React's
private guts. So `react-on-rails-rsc` is a thin **wrapper that vendors (bundles in) a specific,
tested build of `react-server-dom-webpack`** plus the webpack plugin/loader React on Rails needs, and
publishes it under a name React on Rails controls and can patch on its own schedule.

🧒 **The simplest analogy:** React's RSC engine is like an engine part that only fits one exact car
model‑year and is sold welded inside the car. `react-on-rails-rsc` is the shop that extracts the
right engine part for model‑year "19.0.4," tests it, bolts on the Rails‑specific brackets (the
webpack plugin/loader), and sells it as a labeled box you can install.

---

## 2. 🛠️ Why it _must_ be separate — the three real reasons

### Reason A — `react-server-dom-webpack` is version‑welded to React's private internals

From reading React's own monorepo (`facebook/react`, `packages/react-server-dom-webpack`,
`packages/react-server`, `packages/react-client`):

- The generic Flight algorithm lives once in **`react-server`** (encoder) and **`react-client`**
  (decoder). These are marked `"private": true` — **never published**. The published
  `react-server-dom-*` packages are _builds_ of that code with a per‑bundler config forked in at
  compile time (`scripts/rollup/forks.js` + `scripts/shared/inlinedHostConfigs.js`).
- The runtime reaches into **version‑locked private internals**. e.g.
  `react-server/src/ReactSharedInternalsServer.js` reads
  `React.__SERVER_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE` — the export name literally
  says _users cannot upgrade_. The Flight server mutates `ReactSharedInternals.A/.H/.getCurrentStack`.
  This object's shape changes between React versions with **no compatibility shim**.
- The React **version is baked into the build** (`packages/shared/ReactVersion.js` hard‑codes e.g.
  `19.3.0`), and DevTools/version checks compare it. The Flight **wire format** and the import‑row
  **metadata shape** are coordinated across `react`, `react-dom`, `react-server`, `react-client`, and
  `react-server-dom-webpack` — _all built from one commit._

🧒 **Translation:** if you mix the RSC engine from one React version with `react`/`react-dom` from a
slightly different version, it either throws at import (`The "react-server" condition must be
enabled…`) or silently corrupts the order ticket. So the engine **must** be pinned to an exact React
build — which is exactly the kind of fiddly version coupling a wrapper package exists to manage.

### Reason B — React on Rails needs build tooling that isn't in React core

`react-on-rails-rsc` also ships the **webpack integration** that turns your app's `'use client'`
files into references and emits the manifests:

- `react-on-rails-rsc/WebpackPlugin` — scans for `'use client'` directives, emits
  `react-client-manifest.json` (and `react-server-client-manifest.json`) mapping client modules →
  chunk IDs. (React's own `ReactFlightWebpackPlugin`, repackaged/extended.)
- `react-on-rails-rsc/WebpackLoader` — strips `'use client'` modules out of the **RSC bundle** and
  replaces them with `registerClientReference` proxies, so the RSC bundle never executes client code.

### Reason C — independent, fast patch cadence (security + bug fixes)

Because RSC is young, the runtime needs patches **faster than the Ruby gem ships**. A separate npm
package lets ShakaCode cut RSC‑runtime releases on React's cadence, decoupled from gem versions. The
project's docs explicitly call out that **early builds (19.0.0–19.0.3) vendored older
`react-server-dom-webpack` builds** that were fixed in **19.0.4**, and that several security fixes
landed across that range — see `CHANGELOG.md` and `docs/oss/migrating/rsc-preparing-app.md` for the
authoritative list and the exact CVE references.

> Repo of record: **`shakacode/react_on_rails_rsc`** (separate from the main monorepo). npm name
> `react-on-rails-rsc` (the published `name` field is unscoped — `react-on-rails-rsc`).

---

## 3. 🛠️ What the package exposes (exports map)

From `node_modules/react-on-rails-rsc/package.json` (**v19.0.5‑rc.6** in the tree today;
simplified — the real targets also carry `types`/`default` sub‑keys):

```jsonc
{
  "./client": { "node": "./dist/client.node.js", "browser": "./dist/client.browser.js" },
  "./client.browser": "./dist/client.browser.js",
  "./client.node": "./dist/client.node.js",
  "./server.node": "./dist/server.node.js",
  "./WebpackPlugin": "./dist/WebpackPlugin.js",
  "./WebpackLoader": "./dist/WebpackLoader.js",
  "./RSCReferenceDiscoveryPlugin": "./dist/RSCReferenceDiscoveryPlugin.js",
  // NEW in 19.0.5‑rc.x: a native Rspack plugin/loader backed by a vendored
  // react-server-dom-rspack build (see §6.1) — additive; the Webpack* paths still work.
  "./RspackPlugin": "./dist/react-server-dom-rspack/plugin.js",
  "./RspackLoader": "./dist/react-server-dom-rspack/loader.js",
  "./server": {
    "react-server": {
      // gated behind the react-server condition
      "workerd": "./dist/react-server-dom-webpack/server.edge.js",
      "deno": "./dist/react-server-dom-webpack/server.browser.js",
      "node": {
        "webpack": "./dist/react-server-dom-webpack/server.node.js",
        "default": "./dist/react-server-dom-webpack/server.node.unbundled.js",
      },
      "edge-light": "./dist/react-server-dom-webpack/server.edge.js",
      "browser": "./dist/react-server-dom-webpack/server.browser.js",
    },
    "default": "./dist/react-server-dom-webpack/server.js",
  },
}
```

Who imports what in the Pro runtime (`packages/react-on-rails-pro/src/`):

| Import                                                          | Used by                                  | Purpose                                                    |
| --------------------------------------------------------------- | ---------------------------------------- | ---------------------------------------------------------- |
| `buildClientRenderer` from `react-on-rails-rsc/client.node`     | `getReactServerComponent.server.ts`      | server‑side: deserialize Flight via `createFromNodeStream` |
| `buildServerRenderer` from `react-on-rails-rsc/server.node`     | `ReactOnRailsRSC.ts`                     | generate the Flight payload in the RSC bundle              |
| `renderToPipeableStream` from `react-on-rails-rsc/server.node`  | `handleErrorRSC.ts`                      | error payloads                                             |
| `import 'react-on-rails-rsc/client.browser'` (side‑effect)      | `wrapServerComponentRenderer/client.tsx` | ensure the client RSC runtime is in the client bundle      |
| `require('react-on-rails-rsc/WebpackPlugin' / 'WebpackLoader')` | webpack configs                          | manifests + `'use client'` stripping                       |

Note: `dist/react-server-dom-webpack/…` is the **vendored React runtime** with node/browser/edge
variants — i.e. exactly the per‑environment builds React produces, repackaged here. As of
19.0.5‑rc.x the package **also** vendors a `dist/react-server-dom-rspack/` build (consumed by
the new `RspackPlugin`/`RspackLoader`); see §6.1 — this is a recent change that the older
"there is no `react-server-dom-rspack`" framing predates.

---

## 4. 🛠️ How the package version correlates to React 19 versions

🧒 **ELI5:** the package's version number tracks the React version it's built _for_ — the
major.minor is the same family as `react`/`react-dom`. But they are **not required to be the
exact same string**: during a release‑candidate window the RSC package can ride ahead on a
patch/RC while `react`/`react-dom` stay on the matching stable line.

Concrete pins found in the repo **today** (note the RC drift — these change as the RC train moves):

| Location                                                                      | react / react-dom                     | react-on-rails-rsc                        |
| ----------------------------------------------------------------------------- | ------------------------------------- | ----------------------------------------- |
| root `package.json` (dev)                                                     | `~19.0.4`                             | `19.0.5-rc.6`                             |
| `packages/react-on-rails-pro/package.json` (peer, optional)                   | `>= 16`                               | `*` (optional peer)                       |
| `react_on_rails_pro/spec/dummy/package.json`                                  | `~19.0.4`                             | `19.0.5-rc.6`                             |
| generator pins (`react_on_rails/lib/generators/.../js_dependency_manager.rb`) | `RSC_REACT_VERSION_RANGE = "~19.0.4"` | `RSC_PACKAGE_VERSION_PIN = "19.0.5-rc.6"` |

The package's own `peerDependencies`: `react ^19.0.4`, `react-dom ^19.0.4`, `webpack ^5.59.0`.

Important nuances:

- **The gem version and the RSC package version are decoupled.** The RSC package tracks **React**,
  not the gem.
- **react/react-dom and react-on-rails-rsc are also decoupled during the RC window.** The generator
  comment (`js_dependency_manager.rb`) is explicit: react/react-dom stay on stable `~19.0.4` while
  `react-on-rails-rsc` rides an RC (`19.0.5-rc.6`). `RSC_REACT_VERSION_RANGE` is intentionally
  distinct from `RSC_PACKAGE_VERSION_PIN`. There's a TODO (#3642) to re‑converge on a stable
  `react-on-rails-rsc` after 19.0.5 stable ships.
- The Pro package declares `react-on-rails-rsc` as an **optional peer with range `*`** (it doesn't
  pin a window); the **generator** is what pins the one known‑good version for an install.
- Per the migration docs, **19.0.0–19.0.3 are effectively buggy** (stale vendored
  `react-server-dom-webpack`); **use the generator's pinned version or newer**. Symptoms of a
  wrong/old version: "cryptic rendering errors or RSC payloads that fail to deserialize on the
  client."

How to manage it in practice:

- Install the generator‑pinned set, e.g. `yarn add react@~19.0.4 react-dom@~19.0.4 react-on-rails-rsc@19.0.5-rc.6`
  (let `js_dependency_manager.rb` be the source of truth for the exact pins, since they move with the RC train).
- Verify a single resolved copy: `yarn why react-on-rails-rsc` / `npm ls react-on-rails-rsc`.
- The `rails generate react_on_rails:rsc` generator adds the dep and wires the webpack
  plugin/loader (`react_on_rails/lib/generators/react_on_rails/rsc_setup.rb`).
- Follow your project policy of **strict version constraints** (`~> x.y.z`) — RSC is exactly the case
  where a loose range will eventually pair mismatched React + runtime and break.

---

## 5. 🧒 ELI5: webpack vs rspack — what's the difference?

- **webpack** = the original lunchbox‑packing machine, written in JavaScript. Extremely flexible,
  huge ecosystem of plugins, but **slow** because it's JS doing a lot of work.
- **rspack** = the _same machine rebuilt in Rust_ (a fast language), designed to accept the **same
  plugins and loaders** webpack uses. So you get webpack's behavior, much faster. (ShakaCode reports
  ~20× faster builds with rspack + SWC.)

The headline for React on Rails: **rspack is "webpack, but in Rust."** You keep your webpack config,
plugins, and loaders; you just tell Shakapacker to use the rspack engine.

---

## 6. 🛠️ webpack vs rspack in React on Rails — the real differences (there are surprisingly few)

### 6.1 rspack can reuse the webpack runtime — and `react-on-rails-rsc` now _also_ ships a native Rspack path

> ⚠️ **Updated.** Earlier drafts of these docs asserted "there is **no** `RSCRspackPlugin` and **no**
> `react-server-dom-rspack` anywhere." That is no longer accurate for `react-on-rails-rsc` itself.
> The narrowly‑scoped claims remain true (React's monorepo publishes no `-rspack` build, and
> **Next.js** has none — it reuses `react-server-dom-webpack` under rspack), but ShakaCode has since
> added a native Rspack path to its own package.

Two facts, both true today:

1. **rspack _can_ reuse the webpack RSC tooling/runtime** (the "free" path). The
   **`react-on-rails-rsc/WebpackPlugin`** (`RSCWebpackPlugin`) and **`WebpackLoader`** run under
   rspack too, because rspack implements enough of webpack's plugin API (`thisCompilation` /
   `processAssets` / `make`) and the `react-server-dom-webpack` runtime's `__webpack_require__` /
   `__webpack_chunk_load__` calls + webpack‑shaped chunk metadata work as‑is. This is the path the
   **Pro dummy app uses today** (it wires `WebpackPlugin` + `WebpackLoader` + `RSCReferenceDiscoveryPlugin`,
   with `javascript_transpiler: babel`). It's also what Next.js does under rspack.

2. **`react-on-rails-rsc@19.0.5-rc.x` _additionally_ ships a native Rspack path** — exports
   **`./RspackPlugin`** and **`./RspackLoader`**, backed by a vendored **`dist/react-server-dom-rspack/`**
   build. This is the GA direction for rspack RSC (tracked in the project's rspack‑RSC issues); the
   RC "keeps `WebpackPlugin` compatible while adding `RspackPlugin`" (per the generator's own install
   messaging). So a `react-server-dom-rspack` build now **does** exist — inside `react-on-rails-rsc`.

> Cross‑check from Next.js's own repo (see doc 04/05): Next supports webpack, rspack, AND Turbopack,
> and under rspack **Next reuses `react-server-dom-webpack`** (no `react-server-dom-rspack` in the
> Next tree). That validates path (1) above; path (2) is React on Rails going a step further with a
> bundler‑native plugin/loader of its own.

### 6.2 How Shakapacker picks the bundler

- `config/shakapacker.yml` → `assets_bundler: webpack` | `rspack` (per‑env or default).
- The rspack config simply delegates to the webpack config:

  ```js
  // config/rspack/rspack.config.js
  process.env.SHAKAPACKER_ASSETS_BUNDLER ||= 'rspack';
  module.exports = require('../webpack/webpack.config');
  ```

- `bin/switch-bundler` flips the YAML across sections. The **same** `ServerClientOrBoth.js` and the
  three bundle configs are used either way.

### 6.3 The RSC bundle config (the one genuinely special build)

`config/webpack/rscWebpackConfig.js` — the bits that make the RSC bundle different from a normal
server bundle (identical under webpack and rspack):

```js
resolve: {
  conditionNames: ['react-server', '...'],     // pick React's react-server builds
  alias: {
    react:                  '.../react/react.react-server.js',
    'react/jsx-runtime':    '.../react/jsx-runtime.react-server.js',
    'react/jsx-dev-runtime':'.../react/jsx-dev-runtime.react-server.js',
  },
},
// add the RSC loader to the JS rule (strips 'use client' → client references):
rule.use.push({ loader: 'react-on-rails-rsc/WebpackLoader' });
// filter out react-dom/server (must not be in the RSC bundle):
// output:
rscConfig.output.filename = 'rsc-bundle.js';
```

🧒 **Why the `react-server` condition?** React ships _two_ versions of itself: a normal one and a
"server" one (`react.react-server.js`) that **omits client hooks** (`useState`, effects) and exposes
the server internals the Flight encoder needs. The `react-server` resolve condition tells the bundler
"in this bundle, when someone imports `react`, give them the _server_ React." That's what makes the
RSC bundle able to render Server Components — and why a missing condition throws at import.

### 6.4 The manifests (same format both bundlers)

- `react-client-manifest.json` — client module (`file:///…Component.jsx`) → `{ id, chunks, name:'*' }`.
  Used by the **server** RSC render to encode client references in the payload.
- `react-server-client-manifest.json` — SSR consumer map, used to **load** client modules during the
  SSR/hydration resolution.
- `rsc-client-references.json` (discovery) — the list of `'use client'` file locations, cached so
  watch rebuilds don't re‑scan; produced by the precompile hook's discovery build.

### 6.5 Where webpack and rspack genuinely diverge (small)

- **Speed / transpiler:** rspack pairs with **SWC** (Rust) for transforms; webpack typically uses
  Babel. rspack builds are dramatically faster. (`javascript_transpiler: swc|babel` in
  `shakapacker.yml`.)
- **Minor plugin filtering quirks** can differ (e.g. CSS‑module SSR handling under rspack had its own
  fixes — see CHANGELOG). But the RSC plugin/loader/runtime are shared.
- **Maturity:** rspack‑RSC has two paths (see §6.1). The **native** path — `react-on-rails-rsc`'s
  `RspackPlugin`/`RspackLoader` + vendored `react-server-dom-rspack` — now **ships** in
  `19.0.5-rc.x` (the GA direction), while the webpack‑compatible path keeps working. The Pro dummy
  still wires the Webpack\* plugins. Treat rspack‑RSC as "supported and stabilizing; native plugin
  landing via the RC train."

---

## 7. The one‑screen summary

```
WHY A SEPARATE PACKAGE
  react-server-dom-webpack is (a) built inside React's monorepo, (b) welded to exact React
  internals + version, (c) never published standalone in a stable form.
  → react-on-rails-rsc VENDORS a tested build + adds the WebpackPlugin/WebpackLoader,
    and ships on React's cadence (fast security patches), independent of the gem version.

REACT 19 CORRELATION
  package tracks React's major.minor, but the strings can differ during an RC window:
  react/react-dom on ~19.0.4 while react-on-rails-rsc rides 19.0.5-rc.6 (intentional;
  TODO #3642 re-converges on stable). Use ≥ the generator's pin (19.0.0–19.0.3 are buggy).
  Let js_dependency_manager.rb be the source of truth for pins. Gem version is decoupled.

WEBPACK vs RSPACK
  rspack = "webpack in Rust," webpack-API-compatible.
  PATH 1 (what the Pro dummy uses): SAME react-on-rails-rsc/WebpackPlugin + WebpackLoader +
    react-server-dom-webpack runtime + manifests + rscWebpackConfig (react-server condition),
    because rspack speaks the webpack plugin API. Next.js does this too.
  PATH 2 (new, GA direction): react-on-rails-rsc@19.0.5-rc.x ALSO ships native RspackPlugin +
    RspackLoader backed by a vendored react-server-dom-rspack build.
  So "no react-server-dom-rspack exists anywhere" is now FALSE — it exists inside
    react-on-rails-rsc (just not in React's monorepo or Next.js, which reuse the webpack runtime).
  Differences: speed (SWC vs babel), a few plugin quirks, maturity.
```

---

## 8. File / artifact index

- `node_modules/react-on-rails-rsc/package.json` — exports map, peer deps
- `node_modules/react-on-rails-rsc/dist/WebpackPlugin.js` / `WebpackLoader.js` — the tooling
- `node_modules/react-on-rails-rsc/dist/react-server-dom-webpack/…` — vendored React runtime
- `packages/react-on-rails-pro/src/ReactOnRailsRSC.ts`, `getReactServerComponent.server.ts` — consumers
- `config/webpack/rscWebpackConfig.js` — the `react-server` condition + loader
- `react_on_rails/spec/dummy/config/rspack/rspack.config.js` — delegates to webpack config (OSS dummy only; the Pro dummy has no `config/rspack/`)
- `config/shakapacker.yml` — `assets_bundler`, `javascript_transpiler`
- `react_on_rails/lib/generators/react_on_rails/js_dependency_manager.rb` — `RSC_*` version pins
- `react_on_rails/lib/generators/react_on_rails/rsc_setup.rb` — generator wiring
- `docs/oss/migrating/rsc-preparing-app.md`, `docs/pro/installation.md`, `CHANGELOG.md` — official guidance
- **Upstream reference:** `facebook/react` `packages/{react-server,react-client,react-server-dom-webpack}`
  (why bundler‑specific; see doc 05 for the deep comparison)

**Next:** `04-nextjs-and-turbopack-deep-dive.md` and `05-compare-and-contrast.md`.
