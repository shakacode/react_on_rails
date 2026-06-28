# Upgrading React on Rails Pro

> [!NOTE]
> **Summary for AI agents:** Every React on Rails Pro version bump is a **coupled
> Ruby + JavaScript upgrade**. When you change the gem version in `Gemfile`, you
> must also update the matching npm packages **and** regenerate **both** lockfiles
> (`Gemfile.lock` and `yarn.lock` / `package-lock.json` / `pnpm-lock.yaml`).
> See [Coupled Pro upgrade checklist](#coupled-pro-upgrade-checklist) below before
> editing manifests by hand.

## Coupled Pro Upgrade Checklist

Treat any React on Rails Pro version change as a **coupled Ruby + JavaScript upgrade**.
Updating only the Ruby gem or only the npm package will produce a PR that looks
superficially correct but fails CI under frozen-lockfile install, or runs the gem
and JavaScript packages at mismatched versions.

This checklist applies to every Pro version bump — stable releases (`16.5.0` →
`16.6.0`) as well as release candidates (`16.7.0.rc.0`).

### Packages that must move together

**Ruby side (regenerate `Gemfile.lock`):**

- `Gemfile`: `react_on_rails_pro`
- `Gemfile.lock`: `react_on_rails_pro`, `react_on_rails`, and transitive Ruby
  dependencies such as `jwt` (used for offline license validation)

**JavaScript side (regenerate the JS lockfile):**

- `package.json`: `react-on-rails-pro`
- `package.json`: `react-on-rails-pro-node-renderer` (only if you use the
  standalone Node renderer)
- `package.json`: `react-on-rails-rsc` (required for React Server Components apps;
  check release notes for the correct version to pair)
- `yarn.lock`, `package-lock.json`, or `pnpm-lock.yaml`: matching npm resolutions
  and transitive npm dependencies

Commit **both** the Ruby lockfile and the JavaScript lockfile in the same change.
A PR that bumps `Gemfile.lock` but skips the JS lockfile (or vice versa) will pass
a `yarn install` that resolves loosely and fail the same install with
`--frozen-lockfile` in CI.

### Prerelease versions: Ruby vs npm format

The two ecosystems use different separators for prerelease tags. The Ruby gem and
the npm package refer to the same release, but the version strings look different:

| Release type      | Ruby gem version | npm package version |
| ----------------- | ---------------- | ------------------- |
| Stable            | `16.7.0`         | `16.7.0`            |
| Release candidate | `16.7.0.rc.0`    | `16.7.0-rc.0`       |
| Beta              | `16.7.0.beta.1`  | `16.7.0-beta.1`     |

If you copy the gem version string directly into `package.json` (or the npm version
string directly into `Gemfile`), the install will fail because no package exists
under that spelling. Substitute `.` for `-` (or `-` for `.`) when crossing the
language boundary.

### Strict version pinning

Use exact version constraints on both sides — never `^`, `~`, or `*`. Semver
wildcards in `package.json` cause boot failures starting in v16.2.x.

Replace `VERSION` below with the latest version from
[the CHANGELOG](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md).

```ruby
# Gemfile — pin with =
gem "react_on_rails_pro", "= VERSION"
```

```bash
# package.json — pin with --save-exact / --exact
yarn add react-on-rails-pro@VERSION --exact
npm install react-on-rails-pro@VERSION --save-exact
pnpm add react-on-rails-pro@VERSION --save-exact
```

### Suggested verification

After updating gem and npm versions, run install and a representative build:

```bash
bundle install

# Pick your package manager. Run the loose install first to regenerate the lockfile,
# then re-run with --frozen-lockfile to prove the lockfile matches package.json.
yarn install --non-interactive
yarn install --frozen-lockfile --non-interactive --prefer-offline
# or
pnpm install
pnpm install --frozen-lockfile
# or
npm install
npm ci

bundle exec rails react_on_rails:generate_packs
# Shakapacker projects:
NODE_ENV=development bundle exec bin/shakapacker
# Rspack projects: use your project's Rspack build script instead (e.g. `yarn build`)
```

The `--frozen-lockfile` (or `npm ci`) install is the same install CI runs. If your
local loose install succeeds but the frozen install fails, your JS lockfile was
not regenerated — re-run the loose install and commit the updated lockfile.

After upgrading to 16.5.0 or later, also verify gem/npm version alignment:

```bash
bundle exec rake react_on_rails:sync_versions
```

The task is dry-run by default and reports any drift between the gem and npm
package versions. Pass `WRITE=true` to apply the fix automatically.

### Extra verification for RSC apps

If your app uses React Server Components, also confirm that the asset build emits
both RSC manifests:

- `react-client-manifest.json`
- `react-server-client-manifest.json`

Both files should appear in your bundler's output directory. For Shakapacker apps,
the location is set by `public_output_path` in `config/shakapacker.yml`, typically
`public/webpack/development/` or `public/webpack/production/`. For Rspack apps,
check the `output.path` in your Rspack configuration. If either manifest
is missing, see [Manifest Files Not Generated](./react-server-components/upgrading-existing-pro-app.md#manifest-files-not-generated).

Then run your RSC and server-rendering specs to confirm SSR + RSC still work
end-to-end.

### Why this matters for automated upgrades

Dependency bots and coding agents commonly produce a PR that updates `Gemfile`,
`Gemfile.lock`, and `package.json` but skips the JS lockfile. That PR reads
correctly and may pass a loose local install, but CI will fail at the
frozen-lockfile install step, and a merged-but-stale lockfile can ship a
mismatched npm package alongside the new gem.

Following this checklist keeps the Ruby and JavaScript halves of React on Rails
Pro on the same version.

## Upgrading from GitHub Packages to Public Distribution

### Who This Guide is For

This guide is for existing React on Rails Pro customers who are:

- Previously using GitHub Packages authentication (private distribution)
- On any version before 16.4.0
- Upgrading to version 16.4.0 or higher

If you're a new customer, see [Installation](./installation.md) instead.

### What's Changing

React on Rails Pro packages are now **publicly distributed** via npmjs.com and RubyGems.org:

- ✅ No more GitHub Personal Access Tokens (PATs)
- ✅ No more `.npmrc` configuration
- ✅ Simplified installation with standard `gem install` and `npm install`
- ✅ License validation now happens at **runtime** using JWT tokens

Package names have changed:

| Package       | Old (Scoped)                                        | New (Unscoped)                     |
| ------------- | --------------------------------------------------- | ---------------------------------- |
| Client        | `react-on-rails`                                    | `react-on-rails-pro`               |
| Node Renderer | `@shakacode-tools/react-on-rails-pro-node-renderer` | `react-on-rails-pro-node-renderer` |

**Important:** Pro users should now import from `react-on-rails-pro` instead of `react-on-rails`. The Pro package includes all core features plus Pro-exclusive functionality.

## Version Alignment: Pro 3.x/4.x → 16.x

React on Rails Pro version numbers were aligned with the core React on Rails gem during the 16.x series. **Pro 16.x is the direct successor to Pro 3.x/4.x** — it is the same gem, with the same features, under a new version number.

| Version        | Distribution              | Notes                                       |
| -------------- | ------------------------- | ------------------------------------------- |
| Pro 3.3.x      | GitHub Packages (private) | Last 3.x release                            |
| Pro 4.0.0-rc.x | GitHub Packages (private) | Release candidates (pre-monorepo)           |
| Pro 16.1.x     | GitHub Packages (private) | Version-aligned with core gem               |
| Pro 16.2.0+    | RubyGems.org / npmjs.com  | First publicly distributed, version-aligned |

If you are upgrading from Pro 3.x, 4.0.0-rc.x, or any GitHub Packages version (including 16.1.x), follow the full [Migration Steps](#migration-steps) below.

## Breaking Changes and Deprecation Policy

To reduce upgrade risk, React on Rails Pro follows this policy:

1. **Deprecate first when practical** (docs/changelog + clear replacement).
2. **Warn at runtime when practical** if a deprecated setup is detected.
3. **Remove in a later release** with a short migration note in this guide.
4. **Exception:** security/legal fixes may be removed immediately, but must include an explicit upgrade note.

## Node Renderer Cache Layout

Starting with the release that adds `react_on_rails_pro:pre_seed_renderer_cache`, both the new task and the
deprecated `pre_stage_bundle_for_node_renderer` shim stage the renderer cache as `<cache>/<bundleHash>/<bundleHash>.js`.

Older `pre_stage_bundle_for_node_renderer` versions wrote a flat `<cache>/<renderer_bundle_file_name>` file. That
layout did not match the Node Renderer's runtime lookup, so most apps should not depend on it. Update any custom
scripts that read the old flat file directly.

### Your Current Setup (GitHub Packages)

If you're upgrading, you currently have:

**1. Gemfile with GitHub Packages source:**

```ruby
source "https://rubygems.pkg.github.com/shakacode-tools" do
  gem "react_on_rails_pro", "16.1.1"
end
```

**2. `.npmrc` file with GitHub authentication:**

```ini
always-auth=true
//npm.pkg.github.com/:_authToken=YOUR_TOKEN
@shakacode-tools:registry=https://npm.pkg.github.com
```

**3. Scoped package name in package.json:**

```json
{
  "private": true,
  "dependencies": {
    "@shakacode-tools/react-on-rails-pro-node-renderer": "16.1.1"
  }
}
```

**4. Scoped require statements:**

```javascript
const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');
```

### Migration Steps

> **Version note:** Replace `VERSION` below with the latest version from [the CHANGELOG](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md). After updating to 16.5.0+, run `bundle exec rake react_on_rails:sync_versions` to verify gem and npm versions are aligned.

#### Step 1: Update Gemfile

**Remove** the GitHub Packages source and use standard gem installation:

```diff
- source "https://rubygems.pkg.github.com/shakacode-tools" do
-   gem "react_on_rails_pro", "16.1.1"
- end
+ gem "react_on_rails_pro", "VERSION"
```

Then run:

```bash
bundle install
```

#### Step 2: Remove .npmrc Configuration

If you have a `.npmrc` file with GitHub Packages authentication, **delete it** or remove the GitHub-specific lines:

```bash
# Remove the entire file if it only contained GitHub Packages config
rm .npmrc

# Or edit it to remove these lines:
# always-auth=true
# //npm.pkg.github.com/:_authToken=YOUR_TOKEN
# @shakacode-tools:registry=https://npm.pkg.github.com
```

#### Step 3: Update package.json

**Add the client package** and update the node renderer package name:

```diff
{
  "dependencies": {
+   "react-on-rails-pro": "VERSION",
-   "@shakacode-tools/react-on-rails-pro-node-renderer": "16.1.1"
+   "react-on-rails-pro-node-renderer": "VERSION"
  }
}
```

Then reinstall:

```bash
npm install
# or
yarn install
```

#### Step 4: Update Import Statements

**Client code:** Change all imports from `react-on-rails` to `react-on-rails-pro`:

```diff
- import ReactOnRails from 'react-on-rails';
+ import ReactOnRails from 'react-on-rails-pro';
```

**Pro-exclusive features** (React Server Components, async loading):

```diff
- import RSCRoute from 'react-on-rails/RSCRoute';
+ import RSCRoute from 'react-on-rails-pro/RSCRoute';

- import registerServerComponent from 'react-on-rails/registerServerComponent/client';
+ import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

- import wrapServerComponentRenderer from 'react-on-rails/wrapServerComponentRenderer/client';
+ import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/client';
```

**Node renderer configuration file:**

```diff
- const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');
+ const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');
```

**Node renderer integrations (Sentry, Honeybadger):**

```diff
- require('@shakacode-tools/react-on-rails-pro-node-renderer/integrations/sentry').init();
+ require('react-on-rails-pro-node-renderer/integrations/sentry').init();

- require('@shakacode-tools/react-on-rails-pro-node-renderer/integrations/honeybadger').init();
+ require('react-on-rails-pro-node-renderer/integrations/honeybadger').init();
```

#### Step 5: Configure License Token (Production Only)

React on Rails Pro uses a friendly license model to simplify evaluation and development.

A license token is **optional** for non-production environments:

- Evaluation and local development
- Test environments and CI/CD pipelines
- Staging/non-production deployments

**A paid license is required only for production deployments.**

If no license is configured, Pro keeps running in unlicensed mode and logs license status instead of blocking your app. In production, that log message is a warning because a paid license is required.

Configure your React on Rails Pro license token as an environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

> **Migration note (legacy key-file setup):**
> `config/react_on_rails_pro_license.key` is no longer read by React on Rails Pro.
> If you previously used that file, move the token into `REACT_ON_RAILS_PRO_LICENSE`.

⚠️ **Security Warning**: Never commit your license token to version control. For production, use environment variables or secure secret management systems (Rails credentials, Heroku config vars, AWS Secrets Manager, etc.).

**Where to get your license token:** Visit [Pro pricing and sign up](https://pro.reactonrails.com/) or contact [justin@shakacode.com](mailto:justin@shakacode.com) if you don't have your license token.

For complete licensing details, see [LICENSE_SETUP.md](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/LICENSE_SETUP.md).

### Understanding the Pro npm packages

React on Rails Pro has two npm packages with different purposes:

| Package                            | Purpose                                                                     | When to install                                        |
| ---------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------ |
| `react-on-rails-pro`               | Client-side Pro features (immediate hydration, RSC, component registration) | **Always** — all Pro users need this                   |
| `react-on-rails-pro-node-renderer` | Server-side Node.js rendering pool                                          | **Only** if using the standalone Node Renderer for SSR |

If you only use ExecJS for SSR (the default), you do not need `react-on-rails-pro-node-renderer`.

### Additional Upgrade Notes

#### Upgrading to a version with the async-http node renderer client

React on Rails Pro now uses `async-http` instead of HTTPX for Rails-to-node-renderer requests.
This affects render, streaming render, and asset upload requests.

Before upgrading:

- Run Ruby 3.3 or newer. The `async-http` dependency requires Ruby 3.3+.
- Remove direct application assumptions about HTTPX-specific response or error classes in Pro renderer request paths.
- Treat `config.ssr_timeout` as a per-read socket timeout. With the async-http client, this is applied as the
  read timeout on each renderer socket. It no longer wraps the entire request as a single task-level timeout.
- Treat `config.renderer_http_pool_timeout` as the TCP connect timeout. After the socket connects, individual reads
  are bounded by `ssr_timeout`.
- Treat `config.renderer_http_pool_size` as the TCP connection-pool limit for the async-http client, not as an HTTP/2
  stream limit. With a long-lived `Fiber.scheduler` (for example Falcon or Puma configured with an async scheduler),
  the client is reused across renderer requests within that scheduler and the setting bounds pooled connections to the
  renderer. Under standard Puma streaming, `Sync {}` creates a per-request scheduler and cleans up the client when that
  streaming response ends, so reuse does not persist across consecutive Rails requests. Setting it to `nil` keeps the
  default pool limit; it does not make the async-http client unlimited.
- Expect renderer connection drops to surface immediately as `ReactOnRailsPro::Error`/connection failures. HTTPX
  previously performed one implicit transport retry for some connection drops; the async-http adapter uses
  `retries: 0` and leaves retry policy to the existing bundle-upload retry loop and caller behavior.
- Run the node renderer client from the normal Rails request path. Async Rails servers (Falcon, Puma with an async
  scheduler) are supported: the async-http client uses scheduler-scoped connection reuse automatically when a
  `Fiber.scheduler` already exists before the adapter enters `Sync {}`. Middleware and background code should call the
  renderer from a scheduler with a deliberate request or service lifecycle; a custom scheduler-only context can keep
  renderer clients alive longer than intended.
- `config.renderer_http_keep_alive_timeout` remains accepted for compatibility, but it has no effect because
  async-http manages connection lifecycle through its scheduler-scoped clients and ephemeral request clients. Setting
  it to a non-`nil` value emits a deprecation warning; `nil` is accepted silently.

#### Upgrading to 16.4.0 or later

##### JWT gem requirement

`react_on_rails_pro` uses `jwt` for offline license validation. Current versions require `jwt >= 2.7` (relaxed from the `16.7.0.rc.0` floor of `jwt >= 3.2.0`), so apps still pinned to jwt 2.x can bundle without upgrading. Apps that can resolve `jwt 3.2.0` or newer will continue to do so. If your Gemfile pins `jwt` below 2.7 (e.g., `2.2.x` for compatibility with OAuth gems), you will need to upgrade it. Check for conflicts with:

```bash
bundle update jwt
```

##### Node renderer config: `bundlePath` → `serverBundleCachePath`

The node renderer configuration key `bundlePath` has been renamed to `serverBundleCachePath`. Update your node renderer configuration file:

```diff
  const config = {
-   bundlePath: path.resolve(__dirname, '../.node-renderer-bundles'),
+   serverBundleCachePath: path.resolve(__dirname, '../.node-renderer-bundles'),
  };
```

##### Changed defaults (from Pro 3.x)

If you are upgrading from Pro 3.x and relied on default values without explicitly setting them, be aware of these changes:

| Setting                         | Old Default (3.x) | New Default (16.x) |
| ------------------------------- | ----------------- | ------------------ |
| `ssr_timeout`                   | 20 seconds        | 5 seconds          |
| `renderer_request_retry_limit`  | 1                 | 5                  |
| `renderer_use_fallback_exec_js` | `false`           | `true`             |

If your app depends on the previous defaults, set them explicitly in `config/initializers/react_on_rails_pro.rb`.

##### RSC payload template overrides

React on Rails Pro now renders the built-in RSC payload template with `formats: [:text]` so Rails view annotations cannot inject HTML comments into NDJSON responses.

If your app overrides `custom_rsc_payload_template`, make sure that override resolves to a text or format-neutral template path, such as `app/views/.../rsc_payload.text.erb`. Overrides that only exist as `.html.erb` templates will raise `ActionView::MissingTemplate` when the RSC payload endpoint renders.

##### Gemfile: `react_on_rails` is redundant with `react_on_rails_pro`

`react_on_rails_pro` declares `react_on_rails` as a dependency, so you do not need a separate `gem "react_on_rails"` line in your Gemfile when using Pro. Remove it to avoid confusion about which line controls the version:

```diff
- gem "react_on_rails", "VERSION"
  gem "react_on_rails_pro", "VERSION"
```

### Verify Migration

#### 1. Verify Gem Installation

```bash
bundle list | grep react_on_rails_pro
# Should show: react_on_rails_pro (16.4.0) or higher
```

#### 2. Verify NPM Package Installation

```bash
# Verify client package
npm list react-on-rails-pro
# Should show: react-on-rails-pro@16.4.0 or higher

# Verify node renderer (if using)
npm list react-on-rails-pro-node-renderer
# Should show: react-on-rails-pro-node-renderer@16.4.0 or higher
```

#### 3. Verify License Status

Start your Rails server and verify behavior:

```text
React on Rails Pro license validated successfully
```

If no license is set in non-production environments, the app still runs and logs informational status.

For production, ensure a valid license is configured.

#### 4. Test Your Application

- Start your Rails server
- Start the node renderer (if using): `npm run node-renderer`
- Verify that server-side rendering works correctly

### Troubleshooting

#### "Could not find gem 'react_on_rails_pro'"

- Ensure you removed the GitHub Packages source from your Gemfile
- Run `bundle install` again
- Check that you have the correct version specified

#### "Cannot find module 'react-on-rails-pro'" or "Cannot find module 'react-on-rails-pro-node-renderer'"

- Verify you added `react-on-rails-pro` to your package.json dependencies
- Verify you updated all import/require statements to use the correct package names
- Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`

#### "Cannot mix react-on-rails (core) with react-on-rails-pro"

This error occurs when you import from both `react-on-rails` and `react-on-rails-pro`. Pro users should **only** import from `react-on-rails-pro`:

```diff
- import ReactOnRails from 'react-on-rails';
+ import ReactOnRails from 'react-on-rails-pro';
```

The Pro package re-exports everything from core, so you don't need both.

#### "License validation failed" (production)

- Ensure `REACT_ON_RAILS_PRO_LICENSE` environment variable is set in production.
- Verify the token string is correct (no extra spaces or quotes).
- Contact [justin@shakacode.com](mailto:justin@shakacode.com) if you need a new token.

### Need Help?

If you encounter issues during migration, contact [justin@shakacode.com](mailto:justin@shakacode.com) for support.
