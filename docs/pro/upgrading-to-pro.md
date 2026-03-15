# Upgrading from React on Rails to React on Rails Pro

Already using React on Rails? Switching to Pro takes three steps and under ten minutes. The change is safe, reversible, and requires no license for evaluation.

## What You Get

Pro adds performance and rendering features on top of everything in React on Rails OSS:

- **[React Server Components](./react-server-components/tutorial.md)** - RSC with full Rails integration
- **[Streaming SSR](./streaming-server-rendering.md)** - Progressive server rendering with React 18+
- **[Fragment Caching](./caching.md)** - Cache rendered components and skip prop evaluation entirely
- **[Prerender Caching](./configuration.md)** - Cache JavaScript evaluation results across requests
- **[Node Renderer](./node-renderer/basics.md)** - Dedicated Node.js rendering server for better performance and tooling
- **[Code Splitting](./code-splitting-loadable-components.md)** - Loadable components with SSR support
- **[Bundle Caching](./bundle-caching.md)** - Skip redundant webpack builds during deployment

All OSS features continue to work. Pro re-exports everything from the core package.

## Three Steps to Upgrade

### 1. Add the Pro gem

```bash
bundle add react_on_rails_pro --version="<gem_version>" --strict
```

Or add it to your Gemfile directly:

```ruby
gem "react_on_rails_pro", "= <gem_version>"
```

Then run `bundle install`.

Check the [CHANGELOG](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md) for the latest version.

### 2. Add the Pro npm package

Install `react-on-rails-pro` and update your imports:

```bash
# npm
npm install react-on-rails-pro@<npm_version> --save-exact

# yarn
yarn add react-on-rails-pro@<npm_version> --exact

# pnpm
pnpm add react-on-rails-pro@<npm_version> --save-exact
```

Then update your imports to use `react-on-rails-pro` instead of `react-on-rails`:

```diff
- import ReactOnRails from 'react-on-rails';
+ import ReactOnRails from 'react-on-rails-pro';
```

The Pro package re-exports everything from core, so no other import changes are needed.

### 3. Run the Pro generator

```bash
bundle exec rails generate react_on_rails:pro
```

This adds the Pro initializer, configures webpack for Pro features, and sets up the Node renderer entry point.

After the generator runs, verify everything works:

```bash
bundle exec rails react_on_rails:doctor
bin/dev
```

That's it. Your app is now running React on Rails Pro.

## Using the Generator for Fresh Installs

If you're setting up a new app (not upgrading an existing one), use the `--pro` flag:

```bash
bundle add react_on_rails_pro --version="<gem_version>" --strict
bundle exec rails generate react_on_rails:install --pro
```

## Licensing

React on Rails Pro is **free for evaluation and non-production use**. No license token is needed for local development, testing, CI/CD, or staging environments.

A paid license is required only for production deployments. Set the token as an environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

Startups or teams without budget: email [justin@shakacode.com](mailto:justin@shakacode.com) and we'll work with you. For larger companies, your license supports continued development of the open-source project.

See [LICENSE_SETUP.md](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails_pro/LICENSE_SETUP.md) for complete license configuration.

## Reversibility

Switching to Pro is safe to reverse. To go back to OSS:

1. Remove `react_on_rails_pro` from your Gemfile and run `bundle install`
2. Replace `react-on-rails-pro` with `react-on-rails` in package.json and update imports
3. Remove the Pro initializer (`config/initializers/react_on_rails_pro.rb`)

Pro-only features (fragment caching, Node renderer, RSC) will stop working, but all standard React on Rails functionality continues unchanged.

## Next Steps

- [Installation reference](./installation.md) - Detailed manual installation steps
- [Configuration](./configuration.md) - All Pro configuration options
- [Upgrading Pro versions](./updating.md) - Upgrading between Pro versions
- [React Server Components](./react-server-components/tutorial.md) - Get started with RSC
