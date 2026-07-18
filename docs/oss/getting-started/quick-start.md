# 15-Minute Quick Start Guide

> **Get your first React component running in Rails in 15 minutes**

> [!NOTE]
> **Summary for AI agents:** Use this page when the user wants the shortest path to a working React on Rails app. For new apps, start with `npx create-react-on-rails-app my-app`; it defaults to React on Rails Pro because Pro is where React 19.2 feature support lives. For adding React to an existing app, use [Install into an Existing Rails App](./installation-into-an-existing-rails-app.md) instead.

This guide will have you rendering React components in your Rails app as quickly as possible. We'll skip the theory for now and focus on getting something working.

## ✅ Prerequisites

Before starting, make sure you have:

- **🚨 React on Rails 17.0.0+** (this guide)
- **Rails 7+** (`gem install rails`)
- **Ruby 3.3+** (required)
- **Node.js 18+** and a package manager (**npm** or **pnpm**)
- **git**
- **PostgreSQL** running locally
- **Foreman or Overmind** (for running `bin/dev`)
- **Basic familiarity** with React and Rails

> 💡 **Already have a Rails app?** Use [Install into an Existing Rails App](./installation-into-an-existing-rails-app.md).

## 📦 Step 1: Create the App (3 minutes)

Create a new React on Rails app:

```bash
npx create-react-on-rails-app my-app
cd my-app
bin/rails db:prepare
```

New apps use React on Rails Pro by default because Pro is where React 19.2 feature support lives. Use
`--template javascript` for JavaScript, `--tailwind` to style the generated example, `--rsc` for the
React Server Components example, or `--standard` only when you intentionally want an
open-source-only scaffold.

To try the latest release candidate, use:

```bash
npx create-react-on-rails-app@rc my-app
```

Take a look at the generated app history when you want to understand what the CLI changed:

```bash
git log --oneline --reverse
```

## 🎯 Step 2: Start the Development Server (1 minute)

> **Note:** Ensure you have `overmind` or `foreman` installed to run `bin/dev`.
>
> - **overmind**: `brew install overmind` (macOS) or see [installation guide](https://github.com/DarthSim/overmind#installation)
> - **foreman**: `gem install foreman` (install globally, not in your project bundle - [details](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman))

Start both Rails and the bundler dev server:

```bash
./bin/dev
```

This starts both:

- Rails server on `http://localhost:3000`
- Bundler dev server for hot reloading

## 🎨 Step 3: See Your Component (2 minutes)

Open your browser and navigate to:

```text
http://localhost:3000
```

The generated home page links to the example pages and the files React on Rails created for you.

🎉 **Congratulations!** You have React running in your Rails app.

## 🔧 Step 4: Edit Your Component (2 minutes)

Let's make a quick change to see hot reloading in action:

1. Open the generated HelloWorld component (`app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx`)
2. Change `<h3>Hello, {name}!</h3>` to `<h3>Hello from React on Rails Pro, {name}!</h3>`
3. Save the file
4. Watch your browser automatically refresh

## 🚀 Step 5: Add Components to Existing Views (5 minutes)

Now let's add a React component to one of your existing Rails views:

### Create a New Component

```bash
# Create a new component directory
mkdir -p app/javascript/src/SimpleCounter/ror_components

# Create the component file
touch app/javascript/src/SimpleCounter/ror_components/SimpleCounter.client.tsx
```

Add this content to `SimpleCounter.client.tsx`:

```tsx
import React, { useState } from 'react';

interface SimpleCounterProps {
  initialCount?: number;
}

const SimpleCounter = ({ initialCount = 0 }: SimpleCounterProps) => {
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

With React on Rails auto-bundling, you don't need manual registration! Just add this to a Rails view, such as the generated home page at `app/views/home/index.html.erb`:

```erb
<h1>My Rails App</h1>

<p>Here's a React component embedded in this Rails view:</p>

<%= react_component("SimpleCounter", props: { initialCount: 5 }, auto_load_bundle: true) %>
```

The generated layouts already include these tags. If you add React on Rails to another layout, make sure the `<head>` section includes:

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

1. **[Complete Tutorial](../getting-started/tutorial.md)** - Build a TypeScript component with hooks and auto-bundling
2. **[Server-Side Rendering](../core-concepts/react-server-rendering.md)** - Optimize for SEO and performance
3. **[Production Deployment](../deployment/README.md)** - Deploy to production

### Advanced Features

1. **[Redux Integration](../building-features/react-and-redux.md)** - Maintain legacy or advanced shared-store integrations
2. **[React Router](../building-features/react-router.md)** - Client-side routing

### Pro Features

:::tip Pro Features
Start at [React on Rails Pro](../../pro/react-on-rails-pro.md) for the canonical route map, or go directly to [Pro pricing and sign up](https://pro.reactonrails.com/). From there you can jump to [React Server Components](../../pro/react-server-components/tutorial.md), [streaming SSR](../../pro/streaming-ssr.md), [fragment caching](../../pro/fragment-caching.md), and the [Node renderer](../../pro/node-renderer.md). ShakaCode Trust-Based Commercial Licensing: no token is required for development, test, CI/CD, or staging.
:::

- **[OSS vs Pro comparison](./oss-vs-pro.md)** - See what Pro adds
- **[React Server Components](../../pro/react-server-components/tutorial.md)** - Add the RSC path when you need it
- **[Pro pricing and sign up](https://pro.reactonrails.com/)** - Current plans and production licenses

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

# Add a new component: create a file under a `ror_components` directory, then
# render it with `<%= react_component("MyComponent") %>` in any Rails view.
# With auto-bundling there's no generator and no manual registration step.
mkdir -p app/javascript/src/MyComponent/ror_components
touch app/javascript/src/MyComponent/ror_components/MyComponent.tsx

# Build for production (use your package manager)
pnpm run build  # or: yarn run build, npm run build
```

### Key File Locations

- **Components (auto-bundling)**: `app/javascript/src/[ComponentName]/ror_components/`
- **Config**: `config/initializers/react_on_rails.rb`
- **Bundler config**: `config/shakapacker.yml`

---

**🎉 Welcome to React on Rails!** You're now ready to build amazing full-stack applications with the best of both Rails and React.
