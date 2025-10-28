# React on Rails

> **Integrate React components seamlessly into your Rails application with server-side rendering, hot reloading, and more.**

React on Rails integrates Rails with React, providing a high-performance framework for server-side rendering (SSR) and seamless component integration via [Shakapacker](https://github.com/shakacode/shakapacker).

## What is React on Rails?

React on Rails bridges the gap between Ruby on Rails and React, allowing you to:

- Render React components directly from Rails views with the `react_component` helper
- Pass props from Rails to React without building a separate API
- Enable server-side rendering for better SEO and initial page load performance
- Use hot module replacement (HMR) for fast development iterations
- Integrate with Redux, React Router, and the modern React ecosystem

Unlike a separate SPA approach, React on Rails lets you leverage Rails conventions while progressively enhancing your UI with React components.

## Why React on Rails?

**Key Benefits:**

1. **No Separate API Required** - Pass data directly from Rails views to React components
2. **Server-Side Rendering** - Built-in SSR support for SEO and performance (not available in Shakapacker alone)
3. **Rails Integration** - Works with Rails conventions, asset pipeline, and existing apps
4. **Modern Tooling** - Full Webpack, HMR, and NPM ecosystem support via Shakapacker
5. **Progressive Enhancement** - Mix Rails views with React components on the same page

## When to Use React on Rails

**Choose React on Rails if:**

- ✅ You have an existing Rails application
- ✅ You want React's component model and ecosystem
- ✅ You need server-side rendering for SEO or performance
- ✅ You want to avoid building and maintaining a separate API
- ✅ You value Rails conventions and want tight integration

**Consider alternatives if:**

- ❌ You're building a standalone SPA with a separate API backend

## Getting Started

Choose your path based on your situation:

### 🚀 New to React on Rails?

**[15-Minute Quick Start →](./getting-started/quick-start.md)**

Get your first component running in minutes. Perfect for exploring React on Rails quickly.

### 📦 Adding to an Existing Rails App?

**[Installation Guide →](./getting-started/installation-into-an-existing-rails-app.md)**

Detailed integration instructions for existing Rails applications with Shakapacker.

### 📚 Want a Comprehensive Tutorial?

**[Complete Tutorial →](./getting-started/tutorial.md)**

Step-by-step walkthrough building a full app with Redux, routing, and deployment.

### 👀 Learn by Example?

- **[Spec/Dummy App](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy)** - Simple example in this repo
- **[Tutorial Demo App](https://github.com/shakacode/react_on_rails_demo_ssr_hmr)** - Example with SSR, HMR, and TypeScript
- **[Live Demo with Source](https://github.com/shakacode/react-webpack-rails-tutorial)** - Full production app at [reactrails.com](https://reactrails.com)

## Popular Use Cases

Find guidance for your specific scenario:

| I want to...                        | Go here                                                                               |
| ----------------------------------- | ------------------------------------------------------------------------------------- |
| **Add React to existing Rails app** | [Installation Guide](./getting-started/installation-into-an-existing-rails-app.md)    |
| **Enable server-side rendering**    | [SSR Guide](./core-concepts/react-server-rendering.md)                                |
| **Set up hot reloading**            | [HMR Setup](./building-features/hmr-and-hot-reloading-with-the-webpack-dev-server.md) |
| **Use Redux with Rails**            | [Redux Integration](./building-features/react-and-redux.md)                           |
| **Deploy to production**            | [Deployment Guide](./deployment/deployment.md)                                        |
| **Troubleshoot issues**             | [Troubleshooting](./deployment/troubleshooting.md)                                    |

## Core Concepts

Before building features, understand these fundamentals:

- **[How React on Rails Works](./core-concepts/how-react-on-rails-works.md)** - Architecture overview
- **[Auto-Bundling](./core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md)** - Automatic component registration and bundle generation
- **[Client vs Server Rendering](./core-concepts/client-vs-server-rendering.md)** - When to use each
- **[Webpack Configuration](./core-concepts/webpack-configuration.md)** - Customizing your build

## Philosophy

React on Rails follows the **[Rails Doctrine](https://rubyonrails.org/doctrine)** and extends it to modern JavaScript development:

- **Convention over Configuration** - Sensible defaults for JavaScript tooling with Rails
- **Optimize for Programmer Happiness** - Hot reloading, ES6+, CSS modules, NPM ecosystem
- **Value Integrated Systems** - Tight Rails integration beats separate microservices for most apps

Read the full **[React on Rails Doctrine](./misc/doctrine.md)** for our design philosophy.

## System Requirements

- **Rails 7+** (Rails 5.2+ supported)
- **Ruby 3.0+**
- **Node.js 20+**
- **Shakapacker 6+** (7+ recommended for React on Rails v16)

## Need Help?

### Community Support

- **Active Community** - [Thousands of production sites use React on Rails](https://publicwww.com/websites/%22react-on-rails%22++-undeveloped.com+depth%3Aall/)
- **[React on Rails Discussions](https://github.com/shakacode/react_on_rails/discussions)** - Ask questions and share knowledge
- **[React + Rails Slack](https://reactrails.slack.com)** - Real-time community help
- **[GitHub Issues](https://github.com/shakacode/react_on_rails/issues)** - Report bugs

### Professional Support

- **[React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/)** - Advanced features (React Server Components, Suspense SSR, streaming)
- **[ShakaCode Consulting](mailto:react_on_rails@shakacode.com)** - Expert help with React on Rails projects

## External Resources

- **[Shakapacker Documentation](https://github.com/shakacode/shakapacker)** - Webpack integration for Rails (required)
- **[React Documentation](https://react.dev)** - Official React documentation
- **[Rails Guides](https://guides.rubyonrails.org)** - Ruby on Rails documentation

---

**Ready to start?** Pick your path above and let's build something great! 🚀
