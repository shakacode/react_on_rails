# 15-Minute Quick Start Guide

> **Get your first React component running in Rails in 15 minutes**

> [!NOTE]
> **Summary for AI agents:** Use this page when the user wants the shortest path to a working React on Rails install in a new Rails app. For adding React to an existing app, use [Install into an Existing Rails App](./installation-into-an-existing-rails-app.md) instead. For a guided walkthrough, use the [Tutorial](./tutorial.md).

This guide will have you rendering React components in your Rails app as quickly as possible. We'll skip the theory for now and focus on getting something working.

## ✅ Prerequisites

Before starting, make sure you have:

- **🚨 React on Rails 16.4.0+** (this guide)
- **🚨 Shakapacker 6+** (7+ recommended for React on Rails 16)
- **Rails 7+** application (Rails 5.2+ supported)
- **Ruby 3.0+** (required)
- **Node.js 18+** and a package manager (**npm**, **pnpm**, **Yarn**, or **bun**)
- **Foreman or Overmind** (for running `bin/dev`)
- **Basic familiarity** with React and Rails

> 💡 **Don't have a Rails app?** Run `rails new my_react_app` first.

## 📦 Step 1: Install React on Rails (3 minutes)

Add the React on Rails gem and run its installer:

```bash
# Add the gem
bundle add react_on_rails --strict

# Optional but recommended: commit or stash first so generated files show as a clean diff
# git add . && git commit -m "Prepare for React on Rails install"

# Run the installer for TypeScript
bin/rails generate react_on_rails:install --typescript

# Optional: Use Rspack for faster builds
# bin/rails generate react_on_rails:install --typescript --rspack

# For JavaScript instead of TypeScript, omit --typescript
# bin/rails generate react_on_rails:install
```

If the generator reports dependency-install warnings (for example, `JavaScript dependencies installation failed ...`), run your package manager install and compile once before moving on:

```bash
npm install
# or: pnpm install
# or: yarn install
# or: bun install

bundle exec rails shakapacker:compile
```

Take a look at the files created by the generator.

- Component files (`.tsx` for TypeScript, `.jsx` for JavaScript)
- Shakapacker install
- React component files in `client/`
- A sample controller and view
- Webpack configuration

> 💡 **Performance Tip:** Add the `--rspack` flag for significantly faster builds (~20x improvement). You can also switch bundlers later with `bin/switch-bundler rspack`.
>
> **Note on `bin/switch-bundler`:** This utility safely switches between webpack and rspack by updating `shakapacker.yml` and managing dependencies. However, it does not modify custom webpack configuration code. If you have custom webpack plugins or loaders, you may need to update those manually to work with rspack. See [Rspack documentation](../api-reference/generator-details.md#rspack-support) for details on unified configuration patterns.

## 🎯 Step 2: Start the Development Server (1 minute)

> **Note:** Ensure you have `overmind` or `foreman` installed to run `bin/dev`.
>
> - **overmind**: `brew install overmind` (macOS) or see [installation guide](https://github.com/DarthSim/overmind#installation)
> - **foreman**: `gem install foreman` (install globally, not in your project bundle - [details](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman))

Start both Rails and the Webpack dev server:

```bash
./bin/dev
```

This starts both:

- Rails server on `http://localhost:3000`
- Webpack dev server for hot reloading

## 🎨 Step 3: See Your Component (2 minutes)

Open your browser and navigate to:

```text
http://localhost:3000/hello_world
```

You should see a page with a React component saying "Hello World"!

🎉 **Congratulations!** You have React running in your Rails app.

## 🔧 Step 4: Edit Your Component (2 minutes)

Let's make a quick change to see hot reloading in action:

1. Open the generated HelloWorld component (`app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx`)
2. Change the text from "Hello World" to "Hello from React!"
3. Save the file
4. Watch your browser automatically refresh

## 🚀 Step 5: Add Components to Existing Views (5 minutes)

Now let's add a React component to one of your existing Rails views:

### Create a New Component

```bash
# Create a new component directory
mkdir -p app/javascript/src/SimpleCounter/ror_components

# Create the component file
touch app/javascript/src/SimpleCounter/ror_components/SimpleCounter.tsx
```

Add this content to `SimpleCounter.tsx`:

```tsx
import React, { useState } from 'react';

const SimpleCounter = ({ initialCount = 0 }) => {
  const [count, setCount] = useState(initialCount);

  return (
    <div style={{ padding: '20px', border: '1px solid #ccc' }}>
      <h3>React Counter</h3>
      <p>
        Current count: <strong>{count}</strong>
      </p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
      <button onClick={() => setCount(count - 1)}>Decrement</button>
      <button onClick={() => setCount(0)}>Reset</button>
    </div>
  );
};

export default SimpleCounter;
```

### Use It in a Rails View (Auto-Bundling)

With React on Rails auto-bundling, you don't need manual registration! Just add this to any Rails view (like `app/views/application/index.html.erb`):

```erb
<h1>My Rails App</h1>

<p>Here's a React component embedded in this Rails view:</p>

<%= react_component("SimpleCounter", { initialCount: 5 }, { auto_load_bundle: true }) %>
```

Note, your layout needs to include this in the `<head>` section:

```erb
    <%= stylesheet_pack_tag %>
    <%= javascript_pack_tag %>
```

That's it! React on Rails will automatically:

- ✅ Find your component in any directory named `ror_components` (configurable)
- ✅ Create optimized webpack bundles with code splitting
- ✅ Register the component for immediate use
- ✅ Include only necessary JavaScript on each page (reduces bundle size)

> **🚀 Performance Tip:** Auto-bundling automatically optimizes your JavaScript delivery by only loading components used on each page, significantly reducing initial bundle size compared to manual bundling.

Restart your server and visit the page - you should see your interactive counter!

## ✅ What You've Accomplished

In 15 minutes, you've:

- ✅ Installed and configured React on Rails
- ✅ Seen server-side rendering in action
- ✅ Experienced hot module reloading
- ✅ Created and used a custom React component with auto-bundling
- ✅ Passed props from Rails to React
- ✅ Used zero-configuration automatic bundling (no manual pack setup!)

## 🎓 Next Steps

Now that you have React on Rails working, here's what to explore next:

### Immediate Next Steps

1. **[Using React on Rails](./using-react-on-rails.md)** - Core concepts explained
2. **[View Helpers API](../api-reference/view-helpers-api.md)** - Learn all the options for `react_component`
3. **[Hot Module Replacement](../building-features/hmr-and-hot-reloading-with-the-webpack-dev-server.md)** - Optimize your dev workflow
4. **[Curious how React on Rails compares to alternatives?](./comparing-react-on-rails-to-alternatives.md)** - Supplemental context on Hotwire, Inertia Rails, and react-rails

### Dive Deeper

1. **[Complete Tutorial](../getting-started/tutorial.md)** - Build a full app with Redux
2. **[Server-Side Rendering](../core-concepts/react-server-rendering.md)** - Optimize for SEO and performance
3. **[Production Deployment](../deployment/README.md)** - Deploy to production

### Advanced Features

1. **[Redux Integration](../building-features/react-and-redux.md)** - Manage application state
2. **[React Router](../building-features/react-router.md)** - Client-side routing

### Go Pro

:::tip Pro Upgrade
Start at [React on Rails Pro](../../pro/react-on-rails-pro.md) for the canonical route map. From there you can jump to the [upgrade guide](../../pro/upgrading-to-pro.md), [React Server Components](../../pro/react-server-components/tutorial.md), [streaming SSR](../../pro/streaming-ssr.md), [fragment caching](../../pro/fragment-caching.md), and the [Node renderer](../../pro/node-renderer.md). Free to evaluate — no license needed for development.
:::

- **[OSS vs Pro comparison](./oss-vs-pro.md)** - See what Pro adds
- **[Upgrade to Pro](../../pro/upgrading-to-pro.md)** - Three-step migration from OSS

## 🆘 Need Help?

- **[Troubleshooting Guide](../deployment/troubleshooting.md)** - Common issues and solutions
- **[React + Rails Slack](https://reactrails.slack.com)** - Join our community
- **[GitHub Issues](https://github.com/shakacode/react_on_rails/issues)** - Report bugs

## 📋 Quick Reference

### Essential Commands

```bash
# Start development servers
./bin/dev

# Generate React on Rails files with TypeScript support
bin/rails generate react_on_rails:install --typescript

# Create a new component
bin/rails generate react_on_rails:component MyComponent

# Build for production (use your package manager)
pnpm run build  # or: yarn run build, npm run build
```

### Key File Locations

- **Components (auto-bundling)**: `app/javascript/src/[ComponentName]/ror_components/`
- **Config**: `config/initializers/react_on_rails.rb`
- **Bundler config**: `config/shakapacker.yml`

---

**🎉 Welcome to React on Rails!** You're now ready to build amazing full-stack applications with the best of both Rails and React.
