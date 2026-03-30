# Upgrading React on Rails Pro

## Upgrading from GitHub Packages to Public Distribution

### Who This Guide is For

This guide is for existing React on Rails Pro customers who are:

- Previously using GitHub Packages authentication (private distribution)
- On version 16.2.0-beta.x or earlier
- Upgrading to version 16.2.0 or higher

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

#### Step 1: Update Gemfile

**Remove** the GitHub Packages source and use standard gem installation:

```diff
- source "https://rubygems.pkg.github.com/shakacode-tools" do
-   gem "react_on_rails_pro", "16.1.1"
- end
+ gem "react_on_rails_pro", "~> 16.2"
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
+   "react-on-rails-pro": "^16.2.0",
-   "@shakacode-tools/react-on-rails-pro-node-renderer": "16.1.1"
+   "react-on-rails-pro-node-renderer": "^16.2.0"
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
- import { RSCRoute } from 'react-on-rails/RSCRoute';
+ import { RSCRoute } from 'react-on-rails-pro/RSCRoute';

- import registerServerComponent from 'react-on-rails/registerServerComponent/client';
+ import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

- import { wrapServerComponentRenderer } from 'react-on-rails/wrapServerComponentRenderer/client';
+ import { wrapServerComponentRenderer } from 'react-on-rails-pro/wrapServerComponentRenderer/client';
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

React on Rails Pro uses a license-optional model to simplify evaluation and development.

A license token is **optional** for non-production environments:

- Evaluation and local development
- Test environments and CI/CD pipelines
- Staging/non-production deployments

**A paid license is required only for production deployments.**

Configure your React on Rails Pro license token as an environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

> **Migration note (legacy key-file setup):**
> `config/react_on_rails_pro_license.key` is no longer read by React on Rails Pro.
> If you previously used that file, move the token into `REACT_ON_RAILS_PRO_LICENSE`.

⚠️ **Security Warning**: Never commit your license token to version control. For production, use environment variables or secure secret management systems (Rails credentials, Heroku config vars, AWS Secrets Manager, etc.).

**Where to get your license token:** Contact [justin@shakacode.com](mailto:justin@shakacode.com) if you don't have your license token.

For complete licensing details, see [LICENSE_SETUP.md](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/LICENSE_SETUP.md).

### Understanding the Pro npm packages

React on Rails Pro has two npm packages with different purposes:

| Package                            | Purpose                                                                     | When to install                                        |
| ---------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------ |
| `react-on-rails-pro`               | Client-side Pro features (immediate hydration, RSC, component registration) | **Always** — all Pro users need this                   |
| `react-on-rails-pro-node-renderer` | Server-side Node.js rendering pool                                          | **Only** if using the standalone Node Renderer for SSR |

If you only use ExecJS for SSR (the default), you do not need `react-on-rails-pro-node-renderer`.

### Additional Upgrade Notes

#### Upgrading to 16.4.0 or later

##### JWT gem requirement

`react_on_rails_pro` 16.4.0 tightened the `jwt` gem requirement to `~> 2.7`. If your Gemfile pins `jwt` to an older version (e.g., `2.2.x` for compatibility with OAuth gems), you will need to upgrade it. Check for conflicts with:

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
- gem "react_on_rails", "16.4.0"
  gem "react_on_rails_pro", "16.4.0"
```

### Verify Migration

#### 1. Verify Gem Installation

```bash
bundle list | grep react_on_rails_pro
# Should show: react_on_rails_pro (16.2.0) or higher
```

#### 2. Verify NPM Package Installation

```bash
# Verify client package
npm list react-on-rails-pro
# Should show: react-on-rails-pro@16.2.0 or higher

# Verify node renderer (if using)
npm list react-on-rails-pro-node-renderer
# Should show: react-on-rails-pro-node-renderer@16.2.0 or higher
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
