# Migrate from `vite_rails`

This guide is for Rails apps that currently use `vite_rails` with React and want to move to React on Rails.

## When this migration makes sense

React on Rails is a better fit when you want one or more of these:

- Rails view helpers like `react_component`
- server-side rendering from Rails
- a tighter Rails-to-React integration story
- React on Rails Pro features like streaming SSR or React Server Components

If your app is already happy with a Vite-only client-rendered setup, this migration is optional.

## Two different starting points

Not all `vite_rails` + React apps are the same shape, and the migration effort is very different for each:

- **Rails-owned island mounts.** Rails renders real ERB views and mounts one or more React components inside them. This is what the steps below are written for. The migration is incremental: you can cut over one page (or one mount) at a time.
- **Client-routed SPA shells.** Rails serves a minimal layout and a single `<div id="app">`, and a client-side router (React Router / TanStack Router) owns everything after the first render. This is an **architecture case study**, not a quick first migration. Before you convert it, decide whether you are:
  1. moving Rails back to being view-owner and breaking the SPA into island mounts, or
  2. keeping the SPA shape and just replacing Vite's build integration.

The first is a real product decision and should not be bundled with a bundler/integration change. The second is narrower but rarely a one-PR job either, because SPA shells usually depend on Vite-specific runtime behavior (`import.meta.env`, `import.meta.glob`, Vite plugins with no direct Shakapacker analogue). Note that `import.meta.glob` has no direct Webpack equivalent — it must be replaced with explicit [`require.context`](https://webpack.js.org/guides/dependency-management/#requirecontext) calls, which use a different API: the glob pattern syntax differs, results are always synchronously resolved, and any lazy loading must be handled through explicit dynamic `import()` calls instead of a built-in lazy mode.

If your app is a SPA shell, do not use it as the first proof of React on Rails adoption. Start with a Rails-owned island somewhere else in the app — even a small one — and migrate that first.

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

## 1. Add React on Rails and Shakapacker

```bash
bundle add shakapacker --strict
bundle add react_on_rails --strict
bundle exec rails generate react_on_rails:install
```

The generator adds the React on Rails initializer, `bin/dev`, Shakapacker config, example routes, and the server bundle entrypoint.

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
