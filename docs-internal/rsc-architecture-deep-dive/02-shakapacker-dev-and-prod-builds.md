# 02 — Shakapacker: Development (HMR) vs Production Builds (with RSC)

> 🧒 **ELI5 boxes** explain the idea simply. 🛠️ **The real thing** gives exact files, processes,
> and config keys. This doc assumes you read `01-ror-pro-rsc-request-flow.md` and know there are
> **three bundles** (client, server, RSC).

---

## 1. 🧒 ELI5: What is a "bundler" and what are the two modes?

Your app is written in lots of little files (`.tsx`, `.ts`, `.css`). The browser can't eat them like
that — it wants a few neat lunchboxes. A **bundler** (webpack or rspack, driven by **Shakapacker**)
packs all the little files into a few lunchboxes (called **bundles** or **chunks**).

There are two times you pack lunchboxes:

- **Development mode** = you're cooking at home and keep tasting. When you change a recipe, you want
  the change to appear **instantly** without re-cooking the whole kitchen. That's **HMR (Hot Module
  Replacement)** — swap just the one dish, keep everything else (and your place) exactly as it was.
- **Production mode** = you're packing 10,000 lunchboxes for a stadium. Now you care about **small,
  sealed, labeled** boxes (minified, hashed filenames, cached forever). You pack once, very carefully,
  and ship.

🛠️ **Shakapacker** is the Ruby gem that wires Rails to a JS bundler (webpack or rspack). It gives
you `bin/shakapacker` (one‑shot/watch build), `bin/shakapacker-dev-server` (the HMR server), a
`config/shakapacker.yml` (the knobs), and Rails view helpers (`javascript_pack_tag`) that read the
build's `manifest.json` to emit the right `<script>`/`<link>` tags.

---

## 2. The mental model: dev = many live processes; prod = one careful compile

```
DEVELOPMENT (Pro + RSC) — 5 long-running processes (Procfile.dev)
┌──────────────────────────────────────────────────────────────────────────────┐
│ rails               rails s -p 3000                  ← serves pages            │
│ webpack-dev-server  HMR=true bin/shakapacker-dev-server  ← CLIENT bundle, :3035│
│ rails-server-assets HMR=true SERVER_BUNDLE_ONLY=true  bin/shakapacker --watch  │
│ rails-rsc-assets    HMR=true RSC_BUNDLE_ONLY=true     bin/shakapacker --watch  │
│ node-renderer       node renderer/node-renderer.js   ← SSR/RSC VM, :3800       │
└──────────────────────────────────────────────────────────────────────────────┘

PRODUCTION — one precompile that emits all three bundles + manifests, then exits
┌──────────────────────────────────────────────────────────────────────────────┐
│ rake assets:precompile                                                         │
│   → bin/shakapacker-precompile-hook (RSC discovery, packs, rescript)           │
│   → bin/shakapacker  → ServerClientOrBoth.js → [client, server, rsc] configs   │
│   → hashed assets in public/webpack/production/ + ssr-generated/               │
│   → (Pro) pre-seed node-renderer cache, publish bundles to deploy adapter      │
└──────────────────────────────────────────────────────────────────────────────┘
```

The key difference for RSC: **the client bundle is served in‑memory with HMR by the dev server, but
the server and RSC bundles are written to disk by separate `--watch` processes** (the node‑renderer
loads them from disk). You can't HMR a bundle that runs inside a Node VM the same way you hot‑swap
modules in a browser — so server/RSC use file‑watch rebuilds instead.

---

## 3. Development mode in detail

### 3.1 The three flavors of "reload"

🧒 **ELI5:**

- **HMR (hot swap):** change one dish on the table, keep everyone seated. _Your React component's
  state survives._
- **Live reload:** the waiter says "everyone out, come back in" — full page refresh. State lost.
- **React Refresh (Fast Refresh):** a special hot‑swap _just for React_ that's smart enough to keep
  component state when it can.

🛠️ **The real thing** (`config/shakapacker.yml`, development section):

```yaml
development:
  compile: false # don't let Rails compile on demand; the dev server owns compilation
  extract_css: false # keep CSS inside JS so it can hot-swap (needed for React Refresh path)
  dev_server:
    host: localhost
    port: 3035
    hmr: true # Hot Module Replacement over a WebSocket
    inline: true # inject the HMR client into the bundle (required with HMR)
    client:
      overlay: true # full-screen error overlay in the browser
    # live_reload defaults to the inverse of hmr
```

- `hmr: true` → webpack‑dev‑server watches files, recompiles changed modules, and pushes updates over
  a WebSocket; the in‑browser HMR runtime applies them without a full reload.
- **React Refresh** is added in `config/webpack/development.js` _only when `inliningCss` is true_:
  it pushes `@pmmmwh/react-refresh-webpack-plugin` onto the **client** config and relies on the
  `react-refresh/babel` plugin. (This is why `extract_css: false` matters in dev — inlined CSS keeps
  the Refresh path intact.)

```js
// config/webpack/development.js (paraphrased)
if (inliningCss) {
  const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
  clientWebpackConfig.plugins.push(
    new ReactRefreshWebpackPlugin({
      overlay: { sockPort: parseInt(devServer.port, 10) || 3035 },
    }),
  );
}
```

### 3.2 Who builds what in dev (the crucial RSC bit)

```
                       ┌───────────── browser (HMR over ws://localhost:3035) ─────────────┐
   webpack-dev-server  │  CLIENT bundle, in-memory, React Refresh, hot-swaps components    │
   (HMR=true)          └──────────────────────────────────────────────────────────────────┘

   rails-server-assets  SERVER_BUNDLE_ONLY=true bin/shakapacker --watch
       → writes ssr-generated/server-bundle.js on every change (to DISK)

   rails-rsc-assets     RSC_BUNDLE_ONLY=true    bin/shakapacker --watch
       → writes ssr-generated/rsc-bundle.js  (or runs RSC client-reference discovery)

   node-renderer        watches those on-disk bundles; next render uses the fresh bundle
```

- The **client** bundle is served by `bin/shakapacker-dev-server` (`Shakapacker::DevServerRunner`)
  from memory on port 3035, with HMR + React Refresh.
- The **server** and **RSC** bundles are _not_ in the dev server. Two separate
  `bin/shakapacker --watch` processes rebuild them **to disk** (`ssr-generated/`). The
  **node‑renderer** picks up the new file on the next request (its hot‑reload watches the bundle
  path/hash). So a change to a Server Component re‑emits `rsc-bundle.js`, and the next page render
  uses it — close to instant, but it's a _file rebuild_, not an in‑VM hot‑swap.
- The env vars `CLIENT_BUNDLE_ONLY` / `SERVER_BUNDLE_ONLY` / `RSC_BUNDLE_ONLY` are read in
  `config/webpack/ServerClientOrBoth.js` to pick which of the three configs to build in each process.
  `WEBPACK_SERVE` (set by the dev server) implies client‑only.

### 3.3 Process orchestration

- `bin/dev` → `ReactOnRails::Dev::ServerManager.run_from_command_line(argv)` runs `Procfile.dev`
  (Foreman/Overmind‑style). Conductor‑friendly: `REACT_ON_RAILS_BASE_PORT` / `CONDUCTOR_PORT` shifts
  all ports together (e.g. base 4000 → rails 4000, dev‑server 4035, renderer 4800).
- `Procfile.static` is the no‑HMR variant: it swaps the dev server for `pnpm run build:dev:watch`
  (a `bin/shakapacker --watch` of the client bundle to disk) — useful when HMR misbehaves.
- ⚠️ Known dev gotcha (documented in `Procfile.dev`): the node‑renderer's `tsc --watch` build can
  delete `lib/` before its first compile finishes, so the `node-renderer` process may throw
  module‑not‑found until the initial build completes. Restart it once the build settles.

### 3.4 OSS vs Pro in dev

|               | OSS (no RSC)                                | Pro (with RSC)                                 |
| ------------- | ------------------------------------------- | ---------------------------------------------- |
| dev processes | ~3 (rails, dev‑server, server‑bundle watch) | 5 (+ rsc‑bundle watch, node‑renderer)          |
| SSR engine    | ExecJS / simple Node                        | dedicated node‑renderer (Fastify, worker pool) |
| bundles       | 2 (client, server)                          | 3 (client, server, rsc)                        |

---

## 4. Production builds in detail

### 4.1 🧒 ELI5

Pack every lunchbox once, perfectly: shrink the food (minify), put a **content sticker** on each box
(content hash like `client-AB12CD.js`) so browsers can cache it forever and only re‑download when the
_contents_ change, and write an index card (`manifest.json`) so Rails knows which sticker maps to
which dish.

### 4.2 The build sequence

```
rake assets:precompile  (RAILS_ENV=production)
   │
   ├─ 1) bin/shakapacker-precompile-hook
   │       • build ReScript (if used), generate packs (if auto-pack)
   │       • RSC: run the "client-reference discovery" build:
   │           RSC_REFERENCE_DISCOVERY_BUILD=true RSC_BUNDLE_ONLY=true bin/shakapacker
   │           → ssr-generated/rsc-client-references.json  (which 'use client' files exist)
   │
   ├─ 2) SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true bin/shakapacker
   │       • ServerClientOrBoth.js returns [clientConfig, serverConfig, rscConfig]
   │       • emits all three bundles with content hashing + manifests
   │
   └─ 3) (Pro post-precompile)
           • ReactOnRailsPro::PreSeedRendererCache.call()  (warm the node-renderer)
           • publish_current_bundle_if_configured()        (upload bundles for rolling deploys)
```

`config/shakapacker.yml` production section:

```yaml
production:
  public_output_path: webpack/production
  compile: false # must be precompiled (no on-demand compiles in prod)
  extract_css: true # real .css files (cacheable, parallel-loadable)
  cache_manifest: true # read manifest.json once, not per request
```

### 4.3 What lands where, and the optimization knobs

| Output                | Path                                                              | Notes                                                                       |
| --------------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Client bundle + CSS   | `public/webpack/production/client-[hash].js/.css`                 | minified, content‑hashed, code‑split                                        |
| `manifest.json`       | `public/webpack/production/manifest.json`                         | entry name → hashed filename (Rails reads this)                             |
| `loadable-stats.json` | `public/webpack/production/`                                      | `@loadable/webpack-plugin` for code splitting (added only when **not** HMR) |
| Server bundle         | `ssr-generated/server-bundle.js`                                  | **single chunk** (`LimitChunkCountPlugin maxChunks:1`), `minimize:false`    |
| RSC bundle            | `ssr-generated/rsc-bundle.js`                                     | built with the `react-server` condition                                     |
| RSC manifests         | `react-client-manifest.json`, `react-server-client-manifest.json` | client/server reference maps (see doc 03 + 01)                              |

- The **server/RSC bundles deliberately aren't content‑hashed or minified** — they run in a Node VM,
  load once, and readable stack traces matter more than bytes. The filter block in
  `serverWebpackConfig.js` strips **five** plugins by constructor name: `WebpackAssetsManifest`,
  `RspackManifestPlugin`, `MiniCssExtractPlugin`, `CssExtractRspackPlugin`, and
  `ForkTsCheckerWebpackPlugin` (the manifest/CSS pairs cover both the webpack and Rspack bundlers).
- The **client bundle** is where minification, code‑splitting (`@loadable/component`), and content
  hashing all live — that's the code shipped to thousands of browsers.

### 4.4 The node‑renderer in production

`react_on_rails_pro/spec/dummy/renderer/node-renderer.js` configures a Fastify server with a worker
pool (defaults to CPU − 1), a `serverBundleCachePath` (`.node-renderer-bundles/`), worker restart
intervals, `supportModules: true` (Buffer/process/setTimeout available in the VM), etc. On first
request it pulls the current bundle (by hash from the manifest) into its cache. In a rolling deploy,
`publish_current_bundle_if_configured` uploads bundles so freshly started renderers can fetch the
exact bundle matching the running Rails code (version skew protection).

---

## 5. Side‑by‑side cheat sheet

| Concern       | Development                                           | Production                                      |
| ------------- | ----------------------------------------------------- | ----------------------------------------------- |
| Client bundle | in‑memory via dev server (:3035), HMR + React Refresh | on disk, minified, hashed, code‑split           |
| Server bundle | `--watch` → `ssr-generated/server-bundle.js`          | one‑shot → same path, single chunk              |
| RSC bundle    | `--watch` → `ssr-generated/rsc-bundle.js`             | one‑shot, + discovery build for client refs     |
| CSS           | `extract_css: false` (inlined, hot‑swappable)         | `extract_css: true` (separate cacheable files)  |
| node‑renderer | reloads bundles from disk on change                   | pre‑seeded cache, bundles published for deploys |
| `compile`     | false (dev server owns it)                            | false (must precompile)                         |
| Manifests     | regenerated on each watch build                       | emitted once with content hashes                |
| Reload UX     | hot‑swap, state preserved                             | n/a                                             |

---

## 6. File index (paths relative to `react_on_rails_pro/spec/dummy/`, the Pro dummy app)

- `config/shakapacker.yml` — all the knobs (dev_server, hmr, extract_css, assets_bundler)
- `Procfile.dev` / `Procfile.static` / `Procfile.prod` — process sets
- `bin/dev` (generator template `react_on_rails/lib/generators/.../bin/dev`) → `ServerManager`
- `bin/shakapacker`, `bin/shakapacker-dev-server`, `bin/shakapacker-precompile-hook`
- `config/webpack/ServerClientOrBoth.js` — chooses client/server/rsc by env var
- `config/webpack/clientWebpackConfig.js` / `serverWebpackConfig.js` / `rscWebpackConfig.js`
- `config/webpack/development.js` (React Refresh) / `production.js`
- `config/webpack/rscManifestClientReferences.js` — RSC client‑reference manifest resolution
- `renderer/node-renderer.js` — the SSR/RSC VM host
- `react_on_rails/spec/support/shakapacker_precompile_hook_shared.rb` — shared precompile logic

**Next:** `03-rsc-npm-package-react19-webpack-vs-rspack.md` — why `rscWebpackConfig.js` needs the
`react-server` condition, why there's a separate npm package, and how webpack vs rspack differ here.
