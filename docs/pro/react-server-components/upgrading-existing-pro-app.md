# Upgrading an Existing React on Rails Pro App to RSC

This guide walks you through adding React Server Components to an existing React on Rails Pro application using the standalone `react_on_rails:rsc` generator. If you're starting a new app from scratch, use `rails g react_on_rails:install --rsc` instead.

> **For React-side migration patterns** (restructuring components, Context, data fetching, etc.), see the [RSC Migration Guide series](../../oss/migrating/migrating-to-rsc.md). This page covers only the infrastructure upgrade.

> **17.1 RC soak:** the generator now pins `react-on-rails-rsc@19.3.0-rc.2` with matching
> React/React DOM 19.2.8. Upgrade the Pro gem and npm packages together to a 17.1 candidate that
> includes this support before changing RSC; earlier Pro releases reject it at startup.
> The stable 19.2.1 / React 19.2.7 combination below remains supported for existing apps.
> RSC package version 19.3 does not mean React 19.3: the runtime stays on React 19.2.x.

The standalone `react_on_rails:rsc` generator installs the RSC pin but does **not** upgrade
your existing React/React DOM dependencies. Before running the 17.1 RC generator, install
matching stable React/React DOM 19.2.x versions at least 19.2.8; the Node Renderer refuses
startup with the new RSC pin until this required upgrade is complete.

For that 17.1 candidate's generated defaults:

```bash
pnpm add react@~19.2.8 react-dom@~19.2.8 react-on-rails-rsc@19.3.0-rc.2
```

The RC loader accepts raw JSX/TSX and supports `parserPlugins` for proposal syntax already
handled by your application transpiler. A `"use client"` module must expose at least one runtime
ES-module export; type-only modules and CommonJS-style exports now produce a file-specific build
error. Add an ES-module export or remove the directive. Rspack builds now honor application
`splitChunks` settings while retaining the sibling chunk metadata needed for hydration.

## Prerequisites

Before running the generator, verify your environment:

| Requirement              | Check command                                                                                                                  | Expected                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------- |
| React on Rails Pro gem   | `bundle show react_on_rails_pro`                                                                                               | 17.1 candidate with RC support, or supported 17.0 stable path |
| React on Rails gem       | `bundle show react_on_rails`                                                                                                   | Same coordinated release as Pro                               |
| React on Rails Pro npm   | `npm ls react-on-rails-pro` / `yarn why react-on-rails-pro` / `pnpm list react-on-rails-pro` / `bun pm why react-on-rails-pro` | Matches gem version                                           |
| React version            | `npm ls react` / `yarn why react` / `pnpm list react` / `bun pm why react`                                                     | Stable 19.2.x: >=19.2.8 for 17.1 RC; >=19.2.7 for 17.0 stable |
| React DOM version        | `npm ls react-dom` / `yarn why react-dom` / `pnpm list react-dom` / `bun pm why react-dom`                                     | Must match `react` version                                    |
| `react-on-rails-rsc`     | `npm ls react-on-rails-rsc` / `yarn why react-on-rails-rsc` / `pnpm list react-on-rails-rsc` / `bun pm why react-on-rails-rsc` | 17.1 RC pin: 19.3.0-rc.2; 17.0 stable: stable 19.2.x >=19.2.1 |
| Node.js                  | `node --version`                                                                                                               | 18+                                                           |
| Pro initializer exists   | `ls config/initializers/react_on_rails_pro.rb`                                                                                 | File exists                                                   |
| Node renderer configured | Check `react_on_rails_pro.rb` for `server_renderer = "NodeRenderer"`                                                           | NodeRenderer enabled                                          |

For the **17.1 RC standalone generator**, upgrade React and React DOM together before running it:

```bash
pnpm add react@~19.2.8 react-dom@~19.2.8 react-on-rails-rsc@19.3.0-rc.2
# or: yarn add react@~19.2.8 react-dom@~19.2.8 react-on-rails-rsc@19.3.0-rc.2
# or: npm install react@~19.2.8 react-dom@~19.2.8 && npm install --save-exact react-on-rails-rsc@19.3.0-rc.2
```

For apps staying on the **supported 17.0 stable path**, use this coordinated set instead:

```bash
pnpm add react@~19.2.7 react-dom@~19.2.7 react-on-rails-rsc@19.2.1
# or: yarn add react@~19.2.7 react-dom@~19.2.7 react-on-rails-rsc@19.2.1
# or: npm install react@~19.2.7 react-dom@~19.2.7 react-on-rails-rsc@19.2.1
```

> Both paths require matching **stable** React/React DOM 19.2.x versions. The minimum is 19.2.8 for RSC 19.3 and 19.2.7 for stable RSC 19.2. React prereleases and React 19.0.x are not supported Pro RSC runtimes in v17.

> [!NOTE]
> The 17.0 generator uses the coordinated React 19.2.7 / stable `react-on-rails-rsc@19.2.1` package set. Later stable 19.2.x packages with patch >= 19.2.1 remain supported. See the 17.1 RC defaults above for new candidate apps.

> [!NOTE]
> Keep React, React DOM, and `react-on-rails-rsc` upgraded as a coordinated set. The RSC bundler APIs are version-coupled, so do not bump `react-on-rails-rsc` by itself.

The generator-managed RSC version is what goes in your app's `package.json`. Separately, the Pro package itself declares an optional peer range, which is broader on purpose:

> [!NOTE]
> During the 17.1 soak, the Pro package's optional `react-on-rails-rsc` peer range is
> `>=19.2.1 <19.4.0 || ~19.3.0-rc.2`. Only the 19.3.0 prerelease tuple from rc.2 onward is
> admitted. Doctor and the Node Renderer enforce React/React DOM 19.2.7+ for RSC 19.2, and
> 19.2.8+ for RSC 19.3, with matching stable React/DOM 19.2.x versions. Set
> `REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK=1` only as an emergency diagnostic escape hatch;
> it downgrades startup errors to warnings and does not make an unsupported tuple supported.
>
> This qualification installs exactly `19.3.0-rc.2`; the compatibility range does not
> mean that every later satisfying version has been tested.

## Pre-Migration: Audit Components for Client API Usage

Before running the generator, audit your existing components to identify which ones use client-side APIs. When RSC is enabled, any component **without** `'use client'` is automatically classified as a React Server Component. Components that use client APIs will break if misclassified.

### What to look for

Components that use any of the following **must** have `'use client'`:

- **React hooks** (`import { ... } from 'react'`): `useState`, `useEffect`, `useLayoutEffect`, `useInsertionEffect`, `useContext`, `useRef`, `useImperativeHandle`, `useReducer`, `useCallback`, `useMemo`, `useTransition`, `useDeferredValue`, `useId`, `useSyncExternalStore`, `useOptimistic`
- **React DOM hooks** (`import { ... } from 'react-dom'`): `useFormStatus`
- **React on Rails client APIs**: `ReactOnRails.getStore()`, `ReactOnRails.authenticityToken()`
- **Redux**: `useSelector`, `useDispatch`, `connect()`, `<Provider>`
- **Router client APIs**: `useNavigate`, `useLocation`, `useParams`
- **SSR entry-point files** using `StaticRouter`: these are SSR wrappers, not RSC server components — see the `.server.jsx` naming collision below
- **Event handlers**: `onClick`, `onChange`, `onSubmit`, etc.
- **Browser APIs**: `window`, `document`, `localStorage`

> [!NOTE]
> `fetch`, `Headers`, `Request`, `Response`, `AbortController`, and `AbortSignal` do **not** require `'use client'`, but they are not available inside the node renderer VM by default. If your existing Server Components call `fetch()` directly, bundle an HTTP client (`node-fetch` v2 or `undici`) or inject fetch globals via `additionalContext` at renderer startup. See [Node Renderer Runtime Globals](../../oss/building-features/node-renderer/js-configuration.md#runtime-globals-for-ssr-and-rsc).

### The `.server.jsx` naming collision

If your app uses React on Rails' auto-bundling with `.client.jsx` / `.server.jsx` file pairs, be aware of a naming collision:

- In **React on Rails auto-bundling** (pre-RSC), `.server.jsx` means "include this file in the server bundle for SSR." These files typically contain traditional SSR logic using `StaticRouter`, `ReactOnRails.getStore()`, etc.
- In **React Server Components**, "server component" means a component that runs in the RSC environment with restricted APIs (no hooks, no state, no browser APIs).

**These are completely different concepts.** A `.server.jsx` file is **not** a React Server Component -- it's a file included in the server bundle. Without `'use client'`, the RSC infrastructure will misclassify it as a Server Component, causing runtime errors.

> **Important:** Do **not** rename `.server.jsx` files to `.ssr.jsx` — React on Rails' auto-bundling relies on the `.server.` suffix to detect server-bundle entries (`Dir.glob("*.server.*")` in `packs_generator.rb`). Renaming would silently drop the file from server bundle registration. Instead, add `'use client'` to these files so the RSC infrastructure classifies them correctly while preserving auto-bundling behavior.

### How auto-classification works

When RSC is enabled, React on Rails classifies components at build time:

1. **File has `'use client'`** → registered via `ReactOnRails.register()` → **Client Component**
2. **File does NOT have `'use client'`** → registered via `registerServerComponent()` → **Server Component**

There is no warning when a component is auto-classified as a server component. If it uses client APIs, it will fail at runtime with errors like "useState is not a function" or "Cannot read properties of undefined."

### Audit checklist

Before proceeding to Step 1:

- [ ] Search your component source files for `useState`, `useEffect`, `useLayoutEffect`, `useInsertionEffect`, `useContext`, `useRef`, `useImperativeHandle`, `useReducer`, `useCallback`, `useMemo`, `useTransition`, `useDeferredValue`, `useId`, `useSyncExternalStore`, `useOptimistic`, `useFormStatus`, `useSelector`, `useDispatch`, `connect(`, `useNavigate`, `useLocation`, `useParams`, `ReactOnRails.getStore`, `ReactOnRails.authenticityToken`
- [ ] Check all `.server.jsx` files -- these almost certainly need `'use client'`
- [ ] Check components that use `StaticRouter` (SSR wrapper, not a client API — but the file likely uses other client APIs)
- [ ] Verify no component relies on browser globals (`window`, `document`) without `'use client'`

> **When in doubt, add `'use client'`.** Starting with all components as Client Components is safe and preserves existing behavior. You can remove the directive later when you're ready to convert a component to a Server Component.

## Step 1: Run the Generator

```bash
rails generate react_on_rails:rsc
# or with TypeScript:
rails generate react_on_rails:rsc --typescript
```

The generator is safe to re-run -- new files are skipped and existing-file patches are applied only when the target pattern is not already present. If a transform cannot be applied (e.g. because your config has been customized), the generator reports a warning but continues.

### What the Generator Creates

| File                                                                        | Purpose                                      |
| --------------------------------------------------------------------------- | -------------------------------------------- |
| `config/webpack/rscWebpackConfig.js`                                        | RSC webpack bundle configuration             |
| `app/javascript/src/HelloServer/ror_components/HelloServer.jsx` (or `.tsx`) | React on Rails registration entry-point      |
| `app/javascript/src/HelloServer/components/HelloServer.jsx` (or `.tsx`)     | Example Server Component                     |
| `app/javascript/src/HelloServer/components/LikeButton.jsx` (or `.tsx`)      | Example Client Component used by HelloServer |
| `app/controllers/hello_server_controller.rb`                                | Controller for the example RSC page          |
| `app/views/hello_server/index.html.erb`                                     | View for the example RSC page                |

### What the Generator Modifies

| File                                        | Change                                                              |
| ------------------------------------------- | ------------------------------------------------------------------- |
| `config/webpack/serverWebpackConfig.js`     | Adds `RSCWebpackPlugin`, `rscBundle` parameter to `configureServer` |
| `config/webpack/clientWebpackConfig.js`     | Adds `RSCWebpackPlugin`                                             |
| `config/webpack/ServerClientOrBoth.js`      | Adds `rscWebpackConfig` import, `RSC_BUNDLE_ONLY` guard             |
| `config/initializers/react_on_rails_pro.rb` | Adds RSC configuration block                                        |
| `config/routes.rb`                          | Adds `rsc_payload_route` and `hello_server` route                   |
| `Procfile.dev`                              | Adds RSC bundle watcher process                                     |
| `package.json`                              | Adds `react-on-rails-rsc` dependency                                |

## Step 2: Legacy Webpack Config Compatibility

The generator automatically handles both webpack export shapes used across Pro app versions. No manual action is needed, but understanding the difference helps with troubleshooting.

### Current Export Shape (v16.4.0+)

Recent versions of the React on Rails Pro generator export an object from `serverWebpackConfig.js` (introduced via [PR 2424](https://github.com/shakacode/react_on_rails/pull/2424)):

```js
// config/webpack/serverWebpackConfig.js
module.exports = {
  default: configureServer,
  extractLoader,
};
```

And `ServerClientOrBoth.js` destructures the import:

```js
const { default: serverWebpackConfig } = require('./serverWebpackConfig');
```

### Legacy Export Shape

Older Pro apps or apps upgraded from OSS export a plain function. These apps must be on
`react_on_rails_pro` v16.4.0+ before adding RSC (see [Prerequisites](#prerequisites)); once upgraded, no
manual export-shape rewrite is required:

```js
// config/webpack/serverWebpackConfig.js
module.exports = configureServer;
```

And `ServerClientOrBoth.js` imports directly:

```js
const serverWebpackConfig = require('./serverWebpackConfig');
```

### How the RSC Config Handles Both

The generated `rscWebpackConfig.js` includes backward-compatible imports that work with either shape:

```js
const serverWebpackModule = require('./serverWebpackConfig');

// Works with both export shapes
const serverWebpackConfig = serverWebpackModule.default || serverWebpackModule;
const extractLoader =
  serverWebpackModule.extractLoader ||
  ((rule, loaderName) => {
    // Fallback implementation when extractLoader is not exported
    if (!Array.isArray(rule.use)) return null;
    return rule.use.find((item) => {
      const testValue = typeof item === 'string' ? item : item.loader;
      return testValue && testValue.includes(loaderName);
    });
  });
```

If `extractLoader` is not exported (legacy shape), the RSC config provides a built-in fallback that scans webpack rule arrays the same way. This means legacy apps do not need to modify their `serverWebpackConfig.js` export shape.

## Step 3: Verify the Setup

After running the generator, verify the setup works end-to-end.

### Build Check

```bash
# Build all three bundles
bin/shakapacker

# Or build individually to isolate errors
CLIENT_BUNDLE_ONLY=true bin/shakapacker
SERVER_BUNDLE_ONLY=true bin/shakapacker
RSC_BUNDLE_ONLY=true bin/shakapacker
```

All three builds should succeed without errors.

### Generated Files Check

Verify these files exist in the expected locations:

- [ ] `react-client-manifest.json` -- in your webpack output directory (typically `public/webpack/development/` or `public/webpack/production/`)
- [ ] `react-server-client-manifest.json` -- in the same webpack output directory
- [ ] `rsc-bundle.js` -- in your `server_bundle_output_path` directory (default: `ssr-generated/`)

### Route Check

```bash
rails routes | grep rsc_payload
```

Should show the RSC payload endpoint (e.g., `GET /rsc_payload/:component_name`).

### Page Render Check

Start the dev server and visit the example page:

```bash
bin/dev
# Visit http://localhost:3000/hello_server
```

The page should render the HelloServer component with:

- Server-rendered content (text from the Server Component)
- A working LikeButton (interactive Client Component)
- No console errors in the browser DevTools

### Development Process Check

Verify all processes start correctly in `Procfile.dev`:

```bash
bin/dev
```

You should see log output from:

- Rails server
- webpack-dev-server (client bundle)
- Server bundle watcher
- **RSC bundle watcher** (new)
- Node renderer

## Troubleshooting

### "Pro gem not installed" Error

The RSC generator requires the Pro gem. If you see this error, ensure `react_on_rails_pro` is in your Gemfile:

```ruby
gem 'react_on_rails_pro'
```

Then run `bundle install` before retrying the generator.

### RSC Bundle Build Fails

If the RSC bundle build fails but server and client builds succeed, the issue is likely in `rscWebpackConfig.js`. Common causes:

- **Missing `react-on-rails-rsc` package**: Run `npm install react-on-rails-rsc@19.2.1` / `yarn add react-on-rails-rsc@19.2.1` / `pnpm add react-on-rails-rsc@19.2.1`, or install a later stable 19.2.x package with patch >= 19.2.1.
- **React or `react-on-rails-rsc` version mismatch**: Stable RSC 19.2.1+ requires React/React DOM 19.2.7+; the 17.1 RSC 19.3 RC soak requires 19.2.8+. React and React DOM must match and stay on the 19.2.x runtime line. Check with `npm ls react react-dom react-on-rails-rsc`, `yarn why react` / `yarn why react-dom` / `yarn why react-on-rails-rsc`, or `pnpm list react react-dom react-on-rails-rsc`.
- **Custom webpack config incompatibility**: If your `serverWebpackConfig.js` was heavily customized, the generator's transforms may not apply cleanly. See [Preparing Your App: Step 4](../../oss/migrating/rsc-preparing-app.md#step-4-set-up-the-rsc-webpack-bundle) for the underlying intent of each webpack change

### Manifest Files Not Generated

If `react-client-manifest.json` or `react-server-client-manifest.json` are missing after building:

1. Verify `RSCWebpackPlugin` was added to both `clientWebpackConfig.js` and `serverWebpackConfig.js`
2. Check that `clientReferences` in the plugin config points to a directory that contains your component source files
3. Ensure at least one file has a `'use client'` directive -- the plugin only generates entries for files it detects as Client Components

### Stream Backpressure Deadlock

If SSR hangs with large RSC payloads, you may need to update `react-on-rails-pro`. See [Stream Backpressure Deadlock](../../oss/migrating/rsc-troubleshooting.md#stream-backpressure-deadlock) for details.

## What's Next

After the infrastructure is in place, migrate your React components:

1. **[Add `'use client'` to all entry points](../../oss/migrating/rsc-preparing-app.md#step-5-add-use-client-to-all-registered-component-entry-points)** -- marks all existing components as Client Components so nothing changes yet
2. **[Switch to streaming rendering](../../oss/migrating/rsc-preparing-app.md#step-6-switch-to-streaming-rendering)** -- update controllers and view helpers
3. **[Restructure components](../../oss/migrating/rsc-component-patterns.md)** -- push `'use client'` boundaries down to leaf components
4. **[Migrate data fetching](../../oss/migrating/rsc-data-fetching.md)** -- move from client-side fetching to server component patterns

## Implementation Context

- [PR #2284](https://github.com/shakacode/react_on_rails/pull/2284) -- Added `--pro` and `--rsc` flags to the install generator and standalone generators
- [PR #2424](https://github.com/shakacode/react_on_rails/pull/2424) -- Added legacy Pro webpack compatibility for the standalone RSC generator
