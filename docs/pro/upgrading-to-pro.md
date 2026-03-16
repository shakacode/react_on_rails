# Upgrading from React on Rails to React on Rails Pro

Already using React on Rails? Upgrading to Pro is straightforward: swap the gem and npm package with their Pro equivalents, then run the Pro generator. The upgrade is safe, reversible, and free to evaluate.

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

> **Version note:** The examples below use `16.4.0` for illustration. Before you begin, check [the CHANGELOG](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md) to find the latest version and substitute it in the commands below. Always use an exact version pin (`=`) for the gem and `--save-exact`/`--exact` for the npm package.
>
> **RC versions:** RubyGems and npm use different pre-release separators. For example, release candidate 9 of version 16.4.0 is `16.4.0.rc.9` on RubyGems (dots) but `16.4.0-rc.9` on npm (hyphen). Make sure to use the correct format for each package manager.

### 1. Swap the gem

Replace `react_on_rails` with `react_on_rails_pro` in your Gemfile. Pro depends on the core gem, so you only need the Pro entry:

```ruby
gem "react_on_rails_pro", "= 16.4.0"
```

Then run `bundle install`.

Or use the command line, which handles both the Gemfile edits and install:

```bash
bundle remove react_on_rails
bundle add react_on_rails_pro --version="= 16.4.0"
```

> **Important:** `bundle add` does not remove existing gems. You must run `bundle remove` first, otherwise both gems will appear in your Gemfile, which can cause Bundler warnings or version conflicts.

### 2. Swap the npm package

Replace `react-on-rails` with `react-on-rails-pro`:

```bash
# npm
npm uninstall react-on-rails && npm install react-on-rails-pro@16.4.0 --save-exact

# yarn
yarn remove react-on-rails && yarn add react-on-rails-pro@16.4.0 --exact

# pnpm
pnpm remove react-on-rails && pnpm add react-on-rails-pro@16.4.0 --save-exact
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
bundle add react_on_rails_pro --version="= 16.4.0"
bundle exec rails generate react_on_rails:install --pro
```

## Try Pro Risk-Free

React on Rails Pro is **free to try** — no license token is needed for local development, testing, CI/CD, or staging environments. Install it, experiment with the features, and see the performance difference in your own app before making any purchasing decisions.

A paid license is only required for production deployments. Visit [pro.reactrails.com](https://pro.reactrails.com/) for pricing and to get started. When you're ready, set the token as an environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

If you're a startup or team with limited budget, don't let cost be a barrier — email [justin@shakacode.com](mailto:justin@shakacode.com) and we'll work something out. For larger companies, your license supports continued development of the open-source project.

See [LICENSE_SETUP.md](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails_pro/LICENSE_SETUP.md) for complete license configuration.

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
- [React Server Components](./react-server-components/tutorial.md) - Get started with RSC
