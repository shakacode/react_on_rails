# Upgrading React on Rails Pro

## Upgrading from GitHub Packages to Public Distribution

### Who This Guide is For

This guide is for existing React on Rails Pro customers who are:

- Currently using GitHub Packages authentication (private distribution)
- On version 16.2.0-beta.x or earlier
- Upgrading to version 16.2.0 or higher

If you're a new customer, see [Installation](./installation.md) instead.

### What's Changing

React on Rails Pro packages are now **publicly distributed** via npmjs.org and RubyGems.org:

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

### Your Current Setup (GitHub Packages)

If you're upgrading, you currently have:

**1. Gemfile with GitHub Packages source:**

```ruby
source "https://rubygems.pkg.github.com/shakacode-tools" do
  gem "react_on_rails_pro", "16.1.1"
end
```

**2. `.npmrc` file with GitHub authentication:**

```
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

#### Step 5: Configure License Token

Add your React on Rails Pro license token as an environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

**Or** configure it in your Rails initializer:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.license_token = ENV["REACT_ON_RAILS_PRO_LICENSE"]
end
```

⚠️ **Security Warning**: Never commit your license token to version control. Always use environment variables or secure secret management systems (Rails credentials, Heroku config vars, AWS Secrets Manager, etc.).

**Where to get your license token:** Contact [justin@shakacode.com](mailto:justin@shakacode.com) if you don't have your license token.

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

#### 3. Verify License Token

Start your Rails server. You should see a success message in the logs:

```
React on Rails Pro license validated successfully
```

If the license is invalid or missing, you'll see an error with instructions.

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

#### "License validation failed"

- Ensure `REACT_ON_RAILS_PRO_LICENSE` environment variable is set
- Verify the token string is correct (no extra spaces or quotes)
- Contact [justin@shakacode.com](mailto:justin@shakacode.com) if you need a new token

### Need Help?

If you encounter issues during migration, contact [justin@shakacode.com](mailto:justin@shakacode.com) for support.
