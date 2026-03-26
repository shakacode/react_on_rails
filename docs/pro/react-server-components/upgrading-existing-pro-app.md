# Upgrading an Existing React on Rails Pro App to RSC

This guide walks you through adding React Server Components to an existing React on Rails Pro application using the standalone `react_on_rails:rsc` generator. If you're starting a new app from scratch, use `rails g react_on_rails:install --rsc` instead.

> **For React-side migration patterns** (restructuring components, Context, data fetching, etc.), see the [RSC Migration Guide series](../../oss/migrating/migrating-to-rsc.md). This page covers only the infrastructure upgrade.

## Prerequisites

Before running the generator, verify your environment:

| Requirement              | Check command                                                        | Expected                          |
| ------------------------ | -------------------------------------------------------------------- | --------------------------------- |
| React on Rails Pro gem   | `bundle show react_on_rails_pro`                                     | v16.4.0+                          |
| React on Rails Pro npm   | `pnpm list react-on-rails-pro`                                       | Matches gem version               |
| React version            | `pnpm list react`                                                    | 19.0.x (19.1.x not yet supported) |
| React DOM version        | `pnpm list react-dom`                                                | Must match `react` version        |
| Node.js                  | `node --version`                                                     | 20+                               |
| Pro initializer exists   | `ls config/initializers/react_on_rails_pro.rb`                       | File exists                       |
| Node renderer configured | Check `react_on_rails_pro.rb` for `server_renderer = "NodeRenderer"` | NodeRenderer enabled              |

If React is below 19.0.x, upgrade it first:

```bash
pnpm add react@~19.0.4 react-dom@~19.0.4
```

> **React 19.0.4+** is recommended. Earlier 19.0.x versions (19.0.0--19.0.3) have known security vulnerabilities — see the [v16.2.0 release notes](../../oss/upgrading/release-notes/16.2.0.md) for details.

## Step 1: Run the Generator

```bash
rails generate react_on_rails:rsc
# or with TypeScript:
rails generate react_on_rails:rsc --typescript
```

The generator is idempotent -- safe to run multiple times.

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

Apps generated with React on Rails Pro v16.4.0+ export an object from `serverWebpackConfig.js`:

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

### Legacy Export Shape (pre-v16.4.0)

Older Pro apps or apps upgraded from OSS export a plain function. These apps must upgrade to v16.4.0+ before adding RSC (see [Prerequisites](#prerequisites)):

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
CLIENT_BUNDLE_ONLY=yes bin/shakapacker
SERVER_BUNDLE_ONLY=yes bin/shakapacker
RSC_BUNDLE_ONLY=yes bin/shakapacker
```

All three builds should succeed without errors.

### Generated Files Check

Verify these files exist in your webpack output directory (typically `public/webpack/production/` or `public/webpack/development/`):

- [ ] `rsc-bundle.js` -- the RSC bundle
- [ ] `react-client-manifest.json` -- maps client component references to browser chunks
- [ ] `react-server-client-manifest.json` -- maps client component references for SSR

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

- **Missing `react-on-rails-rsc` package**: Run `pnpm add react-on-rails-rsc`
- **React version mismatch**: RSC requires React 19.0.x. Check with `pnpm list react`
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
