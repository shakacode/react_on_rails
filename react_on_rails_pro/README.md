# React on Rails Pro

[![License](https://img.shields.io/badge/license-Commercial-blue.svg)](./LICENSE)
[![Build Integration Tests](https://github.com/shakacode/react_on_rails/actions/workflows/pro-integration-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/pro-integration-tests.yml)
[![Build Lint](https://github.com/shakacode/react_on_rails/actions/workflows/pro-lint.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/pro-lint.yml)
[![Build Package Tests](https://github.com/shakacode/react_on_rails/actions/workflows/pro-package-tests.yml/badge.svg)](https://github.com/shakacode/react_on_rails/actions/workflows/pro-package-tests.yml)

**Performance enhancements and advanced features for [React on Rails](https://github.com/shakacode/react_on_rails).**

_See the [CHANGELOG](./CHANGELOG.md) for release updates and **upgrade** details._

---

## 📋 Table of Contents

- [What is React on Rails Pro?](#-what-is-react-on-rails-pro)
- [License & Pricing](#-license--pricing)
- [Why Use Pro?](#-why-use-pro)
- [Key Features](#-key-features)
- [Requirements](#-requirements)
- [Getting Started](#-getting-started)
- [Documentation](#-documentation)
- [Examples](#-examples)
- [Support & Contact](#-support--contact)
- [FAQ](#-faq)

---

## 🎯 What is React on Rails Pro?

React on Rails Pro is a **commercial extension** to the open-source [React on Rails](https://github.com/shakacode/react_on_rails) gem that provides advanced performance optimizations and enterprise features for Rails applications using React.

**Key Points:**

- **Requires**: [React on Rails](https://github.com/shakacode/react_on_rails) (open-source) as a foundation
- **Location**: Part of the React on Rails monorepo at `react_on_rails_pro/`
- **Free for**: Non-commercial use, development, testing, and evaluation (with registration)
- **Commercial license**: Required for production deployments

### How It Relates to React on Rails

```
┌─────────────────────────────────────────────────┐
│ React on Rails Pro (this package)               │
│ • SSR performance enhancements                  │
│ • React Server Components                       │
│ • Advanced caching                              │
│ • Node.js rendering pool                        │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│ React on Rails (open-source, required)          │
│ • Basic SSR                                     │
│ • Component registration                        │
│ • Rails integration                             │
└─────────────────────────────────────────────────┘
```

---

## 📜 License & Pricing

### License Types

#### 🆓 Free License (Non-Commercial)

- **Duration**: 3 months (renewable)
- **Usage**: Personal projects, evaluation, development, testing, CI/CD
- **Restrictions**: **NOT for production deployments**
- **Cost**: FREE - just register with your email
- **Get it**: [https://shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)

**⚠️ Important**: All environments (development, test, CI) require a valid license. The free license is perfect for these use cases!

#### 💼 Commercial License (Production)

- **Duration**: 1 year subscription (or longer)
- **Usage**: Production deployments and commercial applications
- **Support**: Professional support included
- **Contact**: [justin@shakacode.com](mailto:justin@shakacode.com) for pricing

### Quick License Setup

**Get your FREE license in 30 seconds:**

1. Visit [https://shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)
2. Register with your email
3. Receive your license token immediately
4. Set environment variable:
   ```bash
   export REACT_ON_RAILS_PRO_LICENSE="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
   ```

**📖 Detailed setup instructions**: See [LICENSE_SETUP.md](./LICENSE_SETUP.md) for complete configuration guide, team setup, CI/CD integration, and troubleshooting.

---

## 🚀 Why Use Pro?

### Real-World Performance Gains

React on Rails Pro delivers **measurable performance improvements** for production applications:

**Case Study: Popmenu**

- **73% decrease** in average response times
- **20-25% reduction** in Heroku costs
- **Tens of millions** of SSR requests served daily
- [Read the full case study →](https://www.shakacode.com/recent-work/popmenu/)

### When You Need Pro

Consider React on Rails Pro if you:

- ✅ Need **faster server-side rendering** for SEO and initial page loads
- ✅ Want **advanced caching** to reduce server load
- ✅ Require **React Server Components** (RSC) support
- ✅ Need **streaming SSR** for progressive rendering
- ✅ Want **code splitting** with React Router or loadable-components
- ✅ Have **high-traffic applications** where performance matters
- ✅ Need **professional support** for your Rails + React stack

### Pro vs. Open Source

| Feature                 | Open Source | Pro |
| ----------------------- | ----------- | --- |
| Basic SSR               | ✅          | ✅  |
| Component Registration  | ✅          | ✅  |
| Rails Integration       | ✅          | ✅  |
| Fragment Caching        | ❌          | ✅  |
| Prerender Caching       | ❌          | ✅  |
| Proper Node Renderer    | ❌          | ✅  |
| React Server Components | ❌          | ✅  |
| Streaming SSR           | ❌          | ✅  |
| Code Splitting (SSR)    | ❌          | ✅  |
| Bundle Caching          | ❌          | ✅  |
| Professional Support    | ❌          | ✅  |

---

## ✨ Key Features

### 1. Fragment Caching

Cache React components at the Rails view layer with intelligent cache key generation.

```ruby
# Cache component output with automatic cache key from props
<%= cached_react_component("UserProfile", cache_key: [@user]) do
  { user_id: @user.id }
end %>

# Lazy evaluation of props - only evaluated on cache miss
<%= cached_react_component("ExpensiveComponent", cache_key: [@user, @post]) do
  expensive_calculation
end %>
```

**Benefits:**

- Reduces server rendering time by 80%+ for repeated renders
- Automatic cache invalidation based on props
- Works with Rails fragment caching infrastructure

**📖 Learn more**: [docs/caching.md](./docs/caching.md)

### 2. Prerender Caching

Cache the JavaScript evaluation results on the Node.js side.

```ruby
# In config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.prerender_caching = true
end
```

**Benefits:**

- Dramatically reduces Node.js CPU usage
- Caches across multiple requests
- Complements fragment caching for maximum performance

**📖 Learn more**: [docs/caching.md](./docs/caching.md)

### 3. React on Rails Pro Node Renderer

High-performance standalone Node.js server for server-side rendering with connection pooling and automatic worker management.

**Key Advantages:**

- **Parallel rendering**: Multiple worker processes for concurrent SSR
- **Memory management**: Automatic worker restarts to prevent leaks
- **Better performance**: Up to 10x faster than ExecJS for high-traffic sites
- **Loadable Components**: Full support for code splitting with SSR

**Example Configuration:**

```javascript
// react-on-rails-pro/react-on-rails-pro-node-renderer.js
const { reactOnRailsProNodeRenderer } = require('@shakacode-tools/react-on-rails-pro-node-renderer');

reactOnRailsProNodeRenderer({
  bundlePath: path.resolve(__dirname, '../app/assets/webpack'),
  port: 3800,
  workersCount: 4,
  supportModules: true, // Required for loadable-components
});
```

**📖 Learn more**: [docs/node-renderer/basics.md](./docs/node-renderer/basics.md)

### 4. React Server Components (RSC)

Full support for React 18+ Server Components with streaming.

```ruby
# Stream React Server Components
<%= stream_react_component("MyServerComponent", props: @props) %>

# Or with caching
<%= cached_stream_react_component("MyServerComponent", props: @props) %>
```

**Benefits:**

- Reduce JavaScript bundle size
- Fetch data on the server
- Progressive rendering with Suspense
- Automatic code splitting

**📖 Learn more**: Contact [justin@shakacode.com](mailto:justin@shakacode.com) for RSC documentation

### 5. Bundle Caching

Speed up webpack rebuilds by caching unchanged bundles.

**Benefits:**

- **Faster CI/CD**: Skip rebuilding unchanged bundles
- **Faster development**: Hot reload only what changed
- **Lower costs**: Reduce build server time

**📖 Learn more**: [docs/bundle-caching.md](./docs/bundle-caching.md)

### 6. Global State Management

Prevent state leaks between SSR requests.

```ruby
ReactOnRailsPro.configure do |config|
  # Run JavaScript before each render to clear global state
  config.ssr_pre_hook_js = "global.myLeakyLib && global.myLeakyLib.reset();"
end
```

**📖 Learn more**: [docs/configuration.md](./docs/configuration.md)

---

## 📋 Requirements

### Prerequisites

- **Ruby**: >= 3.0
- **Rails**: >= 6.0 (recommended: 7.0+)
- **React on Rails**: >= 11.0.7 (recommended: latest)
- **Node.js**: >= 18 (for Node Renderer)
- **React**: >= 16.8 (recommended: 18+ for RSC/Streaming)

### Compatibility Matrix

| React on Rails Pro | React on Rails | Rails  | Ruby   | React   |
| ------------------ | -------------- | ------ | ------ | ------- |
| 4.x                | >= 16.0        | >= 7.0 | >= 3.2 | >= 18   |
| 3.x                | >= 13.0        | >= 6.0 | >= 3.0 | >= 16.8 |

**📖 Check compatibility**: See [CHANGELOG.md](./CHANGELOG.md) for version-specific requirements

---

## 🏁 Getting Started

### Quick Start (5 Minutes)

**1. Get a License**

Visit [https://shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro) to get your FREE license (takes 30 seconds).

**2. Set License Environment Variable**

```bash
# Add to .env or your shell profile
export REACT_ON_RAILS_PRO_LICENSE="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**3. Install the Gem**

Since React on Rails Pro is part of the public monorepo, you can install it directly from GitHub:

```ruby
# Gemfile
gem 'react_on_rails_pro', '~> 4.0'
```

Or use a specific version/tag:

```ruby
gem 'react_on_rails_pro', git: 'https://github.com/shakacode/react_on_rails.git',
                          glob: 'react_on_rails_pro/*.gemspec',
                          tag: 'v4.0.0'
```

Then run:

```bash
bundle install
```

**4. Configure (Optional)**

Create `config/initializers/react_on_rails_pro.rb`:

```ruby
ReactOnRailsPro.configure do |config|
  # Enable prerender caching for performance
  config.prerender_caching = true
end
```

**5. Verify Installation**

```bash
rails console
> ReactOnRails::Utils.react_on_rails_pro?
# => true
```

**🎉 Done!** You're now using React on Rails Pro.

### Next Steps

- **Enable caching**: See [docs/caching.md](./docs/caching.md)
- **Set up Node Renderer**: See [docs/node-renderer/basics.md](./docs/node-renderer/basics.md)
- **Optimize performance**: See [docs/configuration.md](./docs/configuration.md)
- **Set up for your team**: See [LICENSE_SETUP.md](./LICENSE_SETUP.md#team-setup)

---

## 📚 Documentation

### Installation & Setup

- **[Installation Guide](./docs/installation.md)** - Detailed installation instructions
- **[License Setup](./LICENSE_SETUP.md)** - Complete license configuration guide
- **[Configuration Reference](./docs/configuration.md)** - All configuration options

### Features

- **[Caching Guide](./docs/caching.md)** - Fragment and prerender caching
- **[Bundle Caching](./docs/bundle-caching.md)** - Speed up webpack builds
- **[Node Renderer Basics](./docs/node-renderer/basics.md)** - Standalone Node.js server
- **[Node Renderer Configuration](./docs/node-renderer/js-configuration.md)** - JavaScript config

### API Reference

- **[Ruby API](./docs/ruby-api.md)** - Helper methods and utilities
- **[CHANGELOG](./CHANGELOG.md)** - Version history and upgrade notes

### Upgrading

- **[CHANGELOG](./CHANGELOG.md)** - See "Changed (Breaking)" sections for migration steps
- **Contact Support**: For upgrade assistance, email [justin@shakacode.com](mailto:justin@shakacode.com)

---

## 💡 Examples

### Example Application

The **Pro dummy app** demonstrates all features in action:

**Location**: [spec/dummy](./spec/dummy) (in this monorepo)

**Features Demonstrated**:

1. ✅ Fragment caching with `cached_react_component`
2. ✅ Prerender caching configuration
3. ✅ Node Renderer with loadable-components
4. ✅ Streaming SSR (React 18+)
5. ✅ React Server Components
6. ✅ Code splitting with SSR
7. ✅ HMR with loadable-components

**Running the Example**:

```bash
# From the monorepo root
cd react_on_rails_pro/spec/dummy
bundle install
yarn install

# Start the Rails app
bin/dev
```

Visit `http://localhost:3000` to see the examples.

**📖 Learn more**: See [spec/dummy/README.md](./spec/dummy/README.md)

### Real-World Examples

Check out these production applications using React on Rails Pro:

- **[Popmenu](https://www.shakacode.com/recent-work/popmenu/)** - Restaurant digital marketing platform (case study)

---

## 💬 Support & Contact

### Getting Help

- **📧 Email Support**: [support@shakacode.com](mailto:support@shakacode.com)
- **💼 Sales & Licensing**: [justin@shakacode.com](mailto:justin@shakacode.com)
- **📖 Documentation**: [docs/](./docs/)
- **🐛 Found a Bug?**: Email [support@shakacode.com](mailto:support@shakacode.com) (for Pro customers)

### Professional Services

Need help with your React on Rails project?

**ShakaCode offers**:

- 🚀 Performance optimization
- ⬆️ React on Rails upgrades
- 🏗️ Architecture consulting
- 🎓 Team training
- 🔧 Custom development

**[Book a consultation →](https://meetings.hubspot.com/justingordon/30-minute-consultation)** with Justin Gordon, creator of React on Rails.

### About ShakaCode

React on Rails Pro is developed and maintained by [ShakaCode](https://www.shakacode.com), the team behind:

- **[React on Rails](https://github.com/shakacode/react_on_rails)** - Open-source Rails + React integration
- **[Shakapacker](https://github.com/shakacode/shakapacker)** - Official successor to rails/webpacker
- **[Control Plane Flow](https://github.com/shakacode/control-plane-flow/)** - Heroku alternative with Kubernetes

---

## ❓ FAQ

### Licensing Questions

**Q: Is React on Rails Pro free?**

A: Yes for non-commercial use! You get a FREE 3-month license (renewable) for:

- Personal projects
- Evaluation and testing
- Development environments
- CI/CD

Production deployments require a commercial license. [Learn more →](./LICENSE_SETUP.md)

**Q: Do I need a license for development?**

A: Yes, but it's FREE! Register at [shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro) to get your free 3-month license in 30 seconds (no credit card required).

**Q: Can multiple developers share one license?**

A: Yes! All developers in an organization can share the same license. You can use a shared license via environment variable or configuration file. [See team setup →](./LICENSE_SETUP.md#team-setup)

**Q: What happens when my free license expires?**

A:

- **Development/Test**: Application fails to start immediately (helps catch expiration early)
- **Production**: 1-month grace period with warnings, then fails to start
- **Solution**: Get a new free license or purchase a commercial license

**Q: How much does a commercial license cost?**

A: Pricing is customized based on your needs. Contact [justin@shakacode.com](mailto:justin@shakacode.com) for a quote.

### Technical Questions

**Q: What's the difference between Pro and open-source React on Rails?**

A: Pro adds performance features on top of the open-source gem:

- Advanced caching (fragment + prerender)
- Proper Node.js rendering pool
- React Server Components
- Streaming SSR
- Immediate hydration
- Code splitting with SSR support

[See full comparison →](#pro-vs-open-source)

**Q: Do I need the Node Renderer?**

A: No, it's optional but recommended. The Node Renderer provides the best performance for high-traffic sites and is required for:

- Loadable-components with SSR
- React Server Components
- Streaming SSR

For apps that do not require advanced performance features, ExecJS (the default) works fine.

**Q: Is React on Rails Pro compatible with my React version?**

A: Pro works with React 16.8+. For React Server Components and Streaming SSR, you need React 18+. [See requirements →](#requirements)

**Q: Can I use Pro with Vite instead of Webpack/Shakapacker?**

A: The Node Renderer currently expects webpack bundles. For Vite support, contact [justin@shakacode.com](mailto:justin@shakacode.com).

**Q: Does Pro work with TypeScript?**

A: Yes! Pro works seamlessly with TypeScript applications.

**Q: How do I upgrade from an older Pro version?**

A: Check the [CHANGELOG](./CHANGELOG.md) for breaking changes and migration steps. For major upgrades, we recommend professional support: [justin@shakacode.com](mailto:justin@shakacode.com)

### Getting Started Questions

**Q: Where do I start?**

A: Follow our [Quick Start guide](#-getting-started) - you can be up and running in 5 minutes!

**Q: Can I try Pro before buying?**

A: Yes! Get a FREE 3-month license to evaluate all features. No credit card required. [Get started →](https://shakacode.com/react-on-rails-pro)

**Q: Is there a demo application?**

A: Yes! The [spec/dummy](./spec/dummy) app demonstrates all Pro features. [See examples →](#-examples)

---

## 📄 License

React on Rails Pro is commercial software. See [LICENSE](./LICENSE) for the complete license agreement.

**Summary**:

- ✅ **Free** for non-commercial use (personal, evaluation, development, testing)
- 💼 **Commercial license required** for production deployments
- 📧 **Questions?** Contact [justin@shakacode.com](mailto:justin@shakacode.com)

**Get your FREE license**: [https://shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)

---

## 🤝 Contributing

React on Rails Pro is part of the React on Rails monorepo. For contribution guidelines, see:

- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Pro-specific contribution guide
- **[Main CONTRIBUTING.md](../CONTRIBUTING.md)** - General contribution guidelines

**Note**: Pro features are developed by the ShakaCode team and licensed customers only.

---

<p align="center">
  Made with ❤️ by <a href="https://www.shakacode.com">ShakaCode</a>
</p>

<p align="center">
  <a href="https://www.shakacode.com">
    <img src="https://user-images.githubusercontent.com/10421828/79436256-517d0500-7fd9-11ea-9300-dfbc7c293f26.png" alt="ShakaCode" height="60">
  </a>
</p>
