# Migrate from `vite_rails`

This guide is for Rails apps that currently use `vite_rails` with React and want to move to React on Rails.

If you want repo-shaped references before touching your own app, start with
[Example Migrations](./example-migrations.md) and then come back here for the
mechanics.

A public worked example repo is planned as a separate follow-up in
[reactonrails.com#140](https://github.com/shakacode/reactonrails.com/issues/140);
use [Example Migrations](./example-migrations.md) until that repo exists.

## When this migration makes sense

React on Rails is a better fit when you want one or more of these:

- Rails view helpers like `react_component`
- server-side rendering from Rails
- a tighter Rails-to-React integration story
- React on Rails Pro features like streaming SSR or React Server Components

If your app is already happy with a Vite-only client-rendered setup, this migration is optional.

| Stay on `vite_rails` when...                                                           | Move to React on Rails when...                                                                                         |
| -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| The app is a Vite-powered SPA and Rails only serves the shell.                         | Rails should own page rendering, route-level props, or several React islands inside existing ERB views.                |
| Client-side rendering already meets SEO and performance needs.                         | You need SSR from Rails, a path to streaming SSR, or React Server Components.                                          |
| Vite plugins, `import.meta.glob`, or Vite's dev server are central to your workflow.   | You want to consolidate on Shakapacker / webpack semantics or remove a separate Vite build path from Rails deployment. |
| The current app has no bundler pain and no React on Rails Pro feature needs.           | You need React on Rails helpers, Rails request context, Pro Node rendering, streaming SSR, or RSC as app requirements. |
| The migration would also require a product rewrite or router redesign you do not want. | You can keep the current product shape and migrate route-by-route or as one top-level SPA mount first.                 |

## Two different starting points

Not all `vite_rails` + React apps are the same shape, and the migration effort differs for each:

- **Rails-owned island mounts.** Rails renders real ERB views and mounts one or more React components inside them. The migration is incremental: you can cut over one page (or one mount) at a time.
- **Client-routed SPA shells.** Rails serves a minimal layout and a single `<div id="app">`, and a client-side router (React Router / TanStack Router) owns everything after the first render. You have two reasonable migration shapes here:
  1. **Keep the SPA shape.** Render the top-level SPA component from a single ERB view using `react_component` (or `react_component_hash` when you need SSR that returns multiple regions such as `componentHtml`, `title`, and other head tags). One React on Rails call mounts the whole app — this is the pattern used by the largest React on Rails Pro deployment in production, Popmenu (for example, [110grill.com](https://www.110grill.com/) and other Popmenu-powered restaurant sites), where the entire app is a single top-level component call.
  2. **Break the SPA into island mounts** by moving Rails back to being the view-owner. This is a real product decision and should not be bundled with the bundler/integration change.

For most teams, the **Keep the SPA shape** path is the fastest first step: you're swapping Vite's build integration for Shakapacker, not re-architecting the app. The main friction is usually not the Rails-side `react_component` call — it's the Vite-specific runtime behavior (`import.meta.env`, `import.meta.glob`, Vite plugins with no direct Shakapacker analogue) that the client code may depend on. See [Replace Vite-specific asset and env usage](#5-replace-vite-specific-asset-and-env-usage) for the concrete replacements.

## Estimate the migration before coding

Use the smallest shape that proves parity. For Rails-owned island apps, that usually means one page or mount at a time.
For SPA-shell apps, it often means one top-level `react_component` call first, with any island split treated as a later
product decision.

| App surface to count                        | Typical effort after dependencies install cleanly | What changes the estimate                                                                                                                                                                              |
| ------------------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Initial React on Rails + Shakapacker setup  | 0.5-1 engineer-day                                | Older lockfiles, custom `client/` package roots, or existing webpack config can add setup time.                                                                                                        |
| Rails-owned island mount                    | 0.25-0.5 day per mount                            | Most work is moving the mount call from a Vite entrypoint into an ERB `react_component` call and checking props/hydration.                                                                             |
| Top-level client-routed SPA shell           | 1-3 days                                          | Keep the SPA shape first. Add time if the shell depends on Vite-only env handling, asset paths, or plugin behavior during boot.                                                                        |
| Vite layout/helper cleanup                  | 0.5-1 day per layout family                       | More layouts, engines, or custom helper wrappers increase search-and-replace plus QA time.                                                                                                             |
| `import.meta.env` / `vite_asset_path` usage | 0.25-1 day per usage pattern                      | Rails-passed props are usually simple. Treat client env injection as a security review: only publish values that are safe in browser bundles, and keep server-only secrets out of webpack definitions. |
| `import.meta.glob` or route auto-discovery  | 0.5-2 days per pattern                            | `require.context` differs in key shape and sync/lazy behavior, so route/module registries need focused tests.                                                                                          |
| Vite plugins with no Shakapacker equivalent | 1-3 days per plugin                               | Spike these before committing the full migration; a plugin replacement can be the real schedule driver.                                                                                                |
| SSR or Pro feature adoption                 | 2-5 days for the first representative page        | Add renderer setup, asset/CSS parity checks, and performance validation for ExecJS vs the Pro Node renderer; size streaming SSR/RSC separately from the bundler migration.                             |

Examples:

- **Rails-owned island app:** 8 mounts, two layouts, no Vite-only plugins: roughly 4-7 engineer-days.
- **SPA shell with light Vite usage:** one top-level app, `import.meta.env`, a few asset-path replacements: roughly 3-7 engineer-days.
- **Vite-heavy app:** custom plugins plus `import.meta.glob` route discovery: run a 1-2 day spike first, then estimate from the plugin and module-discovery replacements.

These ranges exclude visual QA, product redesign, and optional work to split a SPA into islands. Keep those as separate
line items so the bundler/integration migration stays measurable.

## Preflight

Before you start, make sure the current app still installs cleanly on the Ruby and Node versions you plan to use for the migration.

- If `bundle install` fails on older native gems such as `pg`, `nio4r`, or `msgpack`, refresh those gems or use the Ruby version already pinned by the app before introducing React on Rails.
- If the app has an older Bundler-era lockfile, refresh that lockfile first.
- Commit or stash your current work so the generator diff is easier to review.

Then inventory the Vite-specific pieces in your app:

- layout helpers like `vite_client_tag`, `vite_react_refresh_tag`, `vite_stylesheet_tag`, `vite_typescript_tag`, and `vite_asset_path`
- `app/frontend/entrypoints/*`
- `vite.config.ts`
- `config/vite.rb` and `config/vite.json`
- dev scripts like `bin/vite`, `bin/live`, or a `Procfile.dev` entry that runs Vite
- JavaScript that depends on `import.meta.env`

Expect this migration to touch both Ruby and JavaScript entrypoints.

## Recommended migration strategy

Do the migration in a branch and keep the Vite setup working until the new React on Rails path is rendering the same screens.

For anything beyond a tiny app, prefer a route-by-route cutover instead of a big-bang rewrite.

If the app uses `vite_rails` plus a custom Rails-side React wrapper, the first credible PR may be maintainability-first rather than a full Vite removal. In that case:

1. Replace one helper-backed component or boundary with React on Rails first.
2. Keep Vite in place for the rest of the app until the narrow slice has parity.
3. Treat Vite removal as a later step, not as the proof point itself.

## 1. Add React on Rails and Shakapacker

```bash
bundle add shakapacker --strict
bundle add react_on_rails --strict
bundle exec rails generate react_on_rails:install
```

The generator adds the React on Rails initializer, `bin/dev`, Shakapacker config, example routes, and the server bundle entrypoint.

### Nested `client/` package roots

Some legacy Rails apps keep `package.json`, lockfiles, `node_modules`, and the webpack config under `client/`.
You can keep that layout during an incremental migration instead of moving every JavaScript file to the Rails root in
the first PR.

First, point React on Rails diagnostics at the real package root:

```ruby
# config/initializers/react_on_rails.rb
config.node_modules_location = "client"
```

Then keep root-level binstubs and config files as thin wrappers so Rails, Shakapacker, and CI still have the paths they
expect:

```bash
#!/usr/bin/env bash
# bin/shakapacker - create this file, then make it executable:
#   chmod +x bin/shakapacker
# set -eu: exit immediately on any error (-e) or reference to an unset variable (-u).
# exec then propagates shakapacker's exit code directly to the caller.
set -eu
cd "$(dirname "$0")/.."
JS_PACKAGE_ROOT=client # Match config.node_modules_location; change this if you use frontend/, app/javascript/, etc.
exec "./${JS_PACKAGE_ROOT}/node_modules/.bin/shakapacker" "$@"
```

```js
// config/webpack/webpack.config.js
// "../../" goes from config/webpack/ back to the Rails root, then into client/.
module.exports = require('../../client/config/webpack/webpack.config.js');
```

```text
# Procfile.dev
web: bin/rails server
js: bin/shakapacker --watch --mode development
```

Use the same pattern for any static-assets Procfile or custom `bin/dev` launcher: keep the Rails-facing command at the
repo root, but delegate the actual JavaScript executable to the configured package root's `node_modules/.bin`. Once the
migration is stable, you can decide separately whether moving the package root to the Rails root is worth the churn.

## 2. Replace Vite layout tags

A typical Vite layout looks like this:

```erb
<%= vite_client_tag %>
<%= vite_react_refresh_tag %>
<%= vite_stylesheet_tag "styles.scss" %>
<%= vite_typescript_tag "application" %>
```

React on Rails + Shakapacker layouts use pack tags instead:

```erb
<%= stylesheet_pack_tag %>
<%= javascript_pack_tag %>
```

These empty pack tags are the default for React on Rails auto-bundling — React on Rails injects component-specific bundles per page. If you use a manual entrypoint instead (non-auto-bundling), pass the pack name explicitly, e.g. `javascript_pack_tag "application"`.

## 3. Move frontend code into the React on Rails structure

A common Vite layout is:

```text
app/frontend/
  components/
  entrypoints/
  styles/
```

For React on Rails, move the code into `app/javascript/`. A good target is:

```text
app/javascript/
  packs/
  src/
```

For auto-bundling, move page-level components into a `ror_components` directory, for example:

```text
app/javascript/src/Hero/ror_components/Hero.client.jsx
```

## 4. Replace client bootstraps with Rails view rendering

Vite apps often mount React manually from an entrypoint:

```js
createRoot(document.getElementById('hero')).render(<Hero />);
```

With React on Rails, render the component from the Rails view instead:

```erb
<%= react_component("Hero", props: { title: "Welcome" }, auto_load_bundle: true) %>
```

This is the key mental model shift: Rails decides where the component mounts, and React on Rails handles registration and hydration.

## 5. Replace Vite-specific asset and env usage

### `vite_asset_path`

If your ERB templates use `vite_asset_path`, convert those assets to one of these patterns:

- keep them as normal Rails static assets
- import them from JavaScript so Shakapacker bundles them
- move them into a component-level asset flow that React on Rails already understands

### `import.meta.env`

Vite-specific `import.meta.env` usage needs to be replaced. In a React on Rails app, prefer:

- Rails-passed props (most reliable for both client and server rendering)
- `railsContext` for request-aware values
- `process.env` in server-rendered bundles (available natively in Node); for client bundles, values must be injected via webpack's `DefinePlugin` or `EnvironmentPlugin`

### `import.meta.glob`

`import.meta.glob` has no direct Webpack equivalent. Replace it with [`require.context`](https://webpack.js.org/guides/dependency-management/#requirecontext):

- the glob-pattern syntax differs (Webpack uses a regex argument, not a glob string)
- lazy/eager behavior is selected via a `mode` argument (`'sync'`, `'lazy'`, `'lazy-once'`, `'eager'`, `'weak'`) rather than the per-call options `import.meta.glob` exposes
- the returned context function requires explicit `.keys()` + key lookup, not the object-map shape `import.meta.glob` returns

A minimal before/after — note two semantic mismatches that bite during migration:

1. **Key paths differ.** Vite returns paths relative to the _calling module_ (`'./dir/foo.js'`); `require.context` returns paths relative to the _context directory_ (`'./foo.js'`). Code that derives names from keys (routing, registration, etc.) needs to account for this.
2. **Sync vs async.** `import.meta.glob` is lazy by default — values are `() => import(...)` returning a Promise. The default `require.context(dir, recursive, regex)` (no 4th argument) is synchronous, so `ctx(key)` returns the module directly. For the lazy case, pass `'lazy'` as the 4th argument so `ctx(key)` returns a `Promise<Module>` (see the lazy example below).

Eager / synchronous case:

```js
// Vite (eager)
const modules = import.meta.glob('./dir/**/*.js', { eager: true });
// { './dir/foo.js': <module>, ... }  ← keys relative to current file

// Webpack (Shakapacker) — synchronous equivalent
const ctx = require.context('./dir', true, /\.js$/);
// ctx.keys() → ['./foo.js', ...]  ← keys relative to context dir, NOT './dir/foo.js'
// ctx('./foo.js') → the module (synchronous)
```

Lazy (default Vite) case — pass `'lazy'` as the 4th `require.context` argument so `ctx(key)` returns a `Promise<Module>`:

```js
// Vite (lazy, the default)
const modules = import.meta.glob('./dir/**/*.js');
// { './dir/foo.js': () => import('./dir/foo.js'), ... }

// Webpack (Shakapacker) — lazy equivalent
const ctx = require.context('./dir', true, /\.js$/, 'lazy');
// ctx.keys() → ['./foo.js', ...]  ← keys relative to context dir, NOT './dir/foo.js'
// ctx(key) now returns Promise<Module>, matching Vite's lazy semantics
const lazyModules = Object.fromEntries(ctx.keys().map((key) => [key, () => ctx(key)]));
```

## 6. Replace the development workflow

Vite apps usually have a dev command like:

```text
vite: bin/vite dev
web: bin/rails s
```

React on Rails uses the generated `bin/dev` flow with Rails plus the Shakapacker watcher.

After migration:

```bash
bin/rails db:prepare
bin/dev
```

## 7. Remove Vite once parity is confirmed

After the new React on Rails entrypoints are working, remove:

- `vite_rails` and related Vite gems
- `vite.config.ts`
- `config/vite.rb`
- `config/vite.json`
- `bin/vite` and Vite-only Procfile entries
- unused `app/frontend/entrypoints/*`

Do this only after the Rails views are using React on Rails helpers and the app no longer depends on Vite-specific helpers.

## Practical example mapping

For a Vite app with:

- `app/frontend/components/Hero.jsx`
- `app/frontend/entrypoints/application.ts`
- `<div id="hero"></div>` in ERB

one reasonable React on Rails target is:

- `app/javascript/src/Hero/ror_components/Hero.client.jsx`
- `app/views/...` uses `<%= react_component("Hero", ..., auto_load_bundle: true) %>`
- generated `server-bundle.js` remains available if you later add SSR

## What usually stays the same

- your React components
- most of your CSS
- Rails controllers and routes
- Turbo usage, if your app already uses it

The migration is mostly about asset/build integration, mounting strategy, and optional SSR capability.

For additional real-world migration references and active public PRs, see [Example Migrations](./example-migrations.md).
