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

- **Scoped** (old): `@shakacode-tools/react-on-rails-pro-node-renderer`
- **Unscoped** (new): `react-on-rails-pro-node-renderer`

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

Change the package name from **scoped** to **unscoped**:

```diff
{
  "dependencies": {
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

#### Step 4: Update Require Statements

Update all require/import statements to use the **unscoped** package name:

**In your node renderer configuration file:**

```diff
- const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');
+ const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');
```

**If using integrations (Sentry, Honeybadger):**

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
npm list react-on-rails-pro-node-renderer
# or
yarn list --pattern react-on-rails-pro-node-renderer

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

#### "Cannot find module 'react-on-rails-pro-node-renderer'"

- Verify you updated all require statements to the unscoped name
- Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`
- Check that package.json has the correct unscoped package name

#### "License validation failed"

- Ensure `REACT_ON_RAILS_PRO_LICENSE` environment variable is set
- Verify the token string is correct (no extra spaces or quotes)
- Contact [justin@shakacode.com](mailto:justin@shakacode.com) if you need a new token

### Need Help?

If you encounter issues during migration, contact [justin@shakacode.com](mailto:justin@shakacode.com) for support.
