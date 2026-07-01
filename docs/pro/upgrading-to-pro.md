# Upgrading from React on Rails to React on Rails Pro

Already using React on Rails? Upgrading to Pro is straightforward: swap the gem and npm package with their Pro equivalents, then run the Pro generator. The upgrade is safe, reversible, and free to evaluate. See [Pro pricing and sign up](https://pro.reactonrails.com/) when you are ready for production.

> [!NOTE]
> **Summary for AI agents:** Use this page when the user already has OSS React on Rails and wants to upgrade to Pro. The upgrade is three steps: swap the gem, swap the npm package, run the generator. Remember the pairing rule: `react_on_rails_pro` gem pairs with `react-on-rails-pro` npm package (never with the base `react-on-rails`).

## What You Get

Pro adds performance and rendering features on top of everything in React on Rails OSS:

- **[React Server Components](./react-server-components/tutorial.md)** - RSC with full Rails integration
- **[Streaming SSR](../oss/building-features/streaming-server-rendering.md)** - Progressive server rendering with React 19
- **[Fragment Caching](../oss/building-features/caching.md)** - Cache rendered components and skip prop evaluation entirely
- **Prerender Caching** ([`config.prerender_caching`](../oss/configuration/configuration-pro.md#example-of-configuration)) - Cache JavaScript evaluation results across requests
- **[Node Renderer](../oss/building-features/node-renderer/basics.md)** - Dedicated Node.js rendering server for better performance and tooling
- **[Code Splitting](../oss/building-features/code-splitting.md)** - Loadable components with SSR support
- **[Bundle Caching](../oss/building-features/bundle-caching.md)** - Skip redundant webpack builds during deployment

Pro includes core React on Rails as a dependency — just swap the packages and everything continues to work.

## Three Steps to Upgrade

> **Version note:** Replace `VERSION` below with the latest version from [the CHANGELOG](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md). React on Rails requires exact gem/npm version parity — use `=` for the gem and `--save-exact`/`--exact` for npm. After upgrading to 16.5.0+, run `bundle exec rake react_on_rails:sync_versions` to verify versions are aligned.
>
> **RC versions:** RubyGems and npm use different pre-release separators — e.g., `VERSION.rc.9` on RubyGems (dots) vs `VERSION-rc.9` on npm (hyphen).
>
> **For later upgrades:** Once you are on Pro, follow the [Coupled Pro Upgrade Checklist](./updating.md#coupled-pro-upgrade-checklist) for every subsequent Pro version bump. It covers the Ruby + JavaScript lockfile pairing, prerelease formats, and RSC manifest verification.

### 1. Swap the gem

Replace `react_on_rails` with `react_on_rails_pro` in your Gemfile. Pro depends on the core gem, so you only need the Pro entry:

```ruby
gem "react_on_rails_pro", "= VERSION"
```

Then run `bundle install`.

Or use the command line, which handles both the Gemfile edits and install:

```bash
bundle remove react_on_rails
bundle add react_on_rails_pro --version="= VERSION"
```

> **Important:** `bundle add` does not remove existing gems. You must run `bundle remove` first, otherwise both gems will appear in your Gemfile, which can cause Bundler warnings or version conflicts.

### 2. Swap the npm package

Replace `react-on-rails` with `react-on-rails-pro`:

```bash
# npm
npm uninstall react-on-rails && npm install react-on-rails-pro@VERSION --save-exact

# yarn
yarn remove react-on-rails && yarn add react-on-rails-pro@VERSION --exact

# pnpm
pnpm remove react-on-rails && pnpm add react-on-rails-pro@VERSION --save-exact

# bun
bun remove react-on-rails && bun add react-on-rails-pro@VERSION --exact
```

Then update your imports:

```diff
- import ReactOnRails from 'react-on-rails';
+ import ReactOnRails from 'react-on-rails-pro';
```

The Pro package re-exports everything from core, so no other import changes are needed.

### 3. Run the Pro generator and enable the Node renderer

```bash
bundle exec rails generate react_on_rails:pro
```

This adds the Pro initializer, configures webpack for Pro features, and sets up the Node renderer entry point and configuration.

After the generator runs, verify everything works:

```bash
bundle exec rails react_on_rails:doctor
bin/dev
```

That's it. Your app is now running React on Rails Pro.

## Using the Generator for Fresh Installs

If you're setting up a new app (not upgrading an existing one), use the `--pro` flag:

```bash
bundle add react_on_rails_pro --version="= VERSION"
bundle exec rails generate react_on_rails:install --pro
```

## Try Pro Risk-Free

React on Rails Pro uses **ShakaCode Trust-Based Commercial Licensing**: try Pro freely in development, test, CI/CD, and staging. No token is required to evaluate. Install it, experiment with the features, and see the performance difference in your own app before making any purchasing decisions.

If no license is configured, Pro keeps running in unlicensed mode and logs license status instead of blocking your app. In production, that log message is a warning because a paid license is required.

A **paid license is required for all production deployments**. Visit [Pro pricing and sign up](https://pro.reactonrails.com/) for current options. Startups and small companies should contact [justin@shakacode.com](mailto:justin@shakacode.com) for discounted pricing. When you're ready, set the token as an environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

If you're a startup or team with limited budget, don't let cost be a barrier — email [justin@shakacode.com](mailto:justin@shakacode.com) and we'll work something out. For larger companies, your license supports continued development of the open-source project.

See [LICENSE_SETUP.md](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/LICENSE_SETUP.md) for complete license configuration.

## Reversibility

Switching to Pro is safe to reverse. To go back to OSS:

1. Replace `react_on_rails_pro` with `react_on_rails` in your Gemfile and run `bundle install`
2. Replace `react-on-rails-pro` with `react-on-rails` in package.json and update imports
3. Remove the Pro initializer (`config/initializers/react_on_rails_pro.rb`)

Pro-only features (fragment caching, Node renderer, RSC) will stop working, but all standard React on Rails functionality continues unchanged.

## Next Steps

- [Installation reference](./installation.md) - Detailed manual installation steps
- [Configuration](../oss/configuration/configuration-pro.md) - All Pro configuration options
- [Upgrading Pro versions](./updating.md) - Upgrading between Pro versions
- [Add RSC to Your Pro App](./react-server-components/upgrading-existing-pro-app.md) - Add RSC support to an existing Pro installation
- [React Server Components Tutorial](./react-server-components/tutorial.md) - Learn RSC concepts step by step
