# Migrate from `vite_rails`

This guide is for Rails apps that currently use `vite_rails` with React and want to move to React on Rails.

## When this migration makes sense

React on Rails is a better fit when you want one or more of these:

- Rails view helpers like `react_component`
- server-side rendering from Rails
- a tighter Rails-to-React integration story
- React on Rails Pro features like streaming SSR or React Server Components

If your app is already happy with a Vite-only client-rendered setup, this migration is optional.

## Preflight

Before you start, make sure the current app still installs cleanly on the Ruby and Node versions you plan to use for the migration.

- If `bundle install` fails on older native gems such as `pg`, `nio4r`, `mysql2`, or `msgpack`, refresh those gems or use the Ruby version already pinned by the app before introducing React on Rails.
- If the app has an older Bundler-era lockfile, refresh that lockfile first.
- If the repo uses Yarn and has a `yarn.lock` but no `"packageManager"` field in `package.json`, add one before introducing Shakapacker 9. Example for Yarn Classic: `npm pkg set packageManager="yarn@1.22.22"` (or add the field manually). Use the version that matches your project's Yarn installation.
- The React on Rails install generator boots the full app. Make sure `config/database.yml` exists and any required env vars for initializers are set before you run it.
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
```

## 2. Declare the package manager if needed

If you use Yarn and `package.json` does not already declare it, set the package manager before running the generator. This only updates `package.json`; it does not install or switch Yarn for you.

```bash
npm pkg set packageManager="yarn@1.22.22"
```

If you prefer, add the same field manually in `package.json`. The example above is for Yarn Classic; use the version that matches your project.

## 3. Run the generator

```bash
bundle exec rails generate react_on_rails:install
```

The generator adds the React on Rails initializer, `bin/dev`, Shakapacker config, example routes, and the server bundle entrypoint.

## 4. Replace Vite layout tags

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

If you use React on Rails auto-bundling, keep those empty pack-tag placeholders in the layout and let React on Rails load component-specific bundles per page.

## 5. Move frontend code into the React on Rails structure

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

## 6. Replace client bootstraps with Rails view rendering

Vite apps often mount React manually from an entrypoint:

```js
createRoot(document.getElementById('hero')).render(<Hero />);
```

With React on Rails, render the component from the Rails view instead:

```erb
<%= react_component("Hero", props: { title: "Welcome" }, auto_load_bundle: true) %>
```

This is the key mental model shift: Rails decides where the component mounts, and React on Rails handles registration and hydration.

## 7. Replace Vite-specific asset and env usage

### `vite_asset_path`

If your ERB templates use `vite_asset_path`, convert those assets to one of these patterns:

- keep them as normal Rails static assets
- import them from JavaScript so Shakapacker bundles them
- move them into a component-level asset flow that React on Rails already understands

### `import.meta.env`

Vite-specific `import.meta.env` usage needs to be replaced. In a React on Rails app, prefer:

- standard `process.env` access in bundled JavaScript
- Rails-passed props
- `railsContext` for request-aware values

## 8. Replace the development workflow

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

## 9. Remove Vite once parity is confirmed

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

One practical detail from real app migrations: if the generator fails while booting your app, treat that as an application preflight problem first, not a React on Rails problem. Missing `APP_URL`-style env vars or an absent `config/database.yml` can stop the migration before any React on Rails files are generated.
