# 15-Minute Quick Start Guide

> **Get your first React component running in Rails in 15 minutes**

This guide will have you rendering React components in your Rails app as quickly as possible. We'll skip the theory for now and focus on getting something working.

## ✅ Prerequisites

Before starting, make sure you have:

- **🚨 React on Rails 16.0+** (this guide)
- **🚨 Shakapacker 6+** (7+ recommended for React on Rails 16)
- **Rails 7+** application (Rails 5.2+ supported)
- **Ruby 3.0+** (required)
- **Node.js 18+** and **Yarn**
- **Basic familiarity** with React and Rails

> 💡 **Don't have a Rails app?** Run `rails new my_react_app` first.

## 📦 Step 1: Install React on Rails (3 minutes)

Add the React on Rails gem and run its installer:

```bash
# Add the gem
bundle add react_on_rails --strict

# Commit your changes (required for generator)
git add . && git commit -m "Add react_on_rails gem"

# Run the installer
bin/rails generate react_on_rails:install
```

Take a look at the files created by the generator.

- jsx files created
- Shakapacker install
- React component files in `client/`
- A sample controller and view
- Webpack configuration

## 🎯 Step 2: Start the Development Server (1 minute)

Start both Rails and the Webpack dev server:

```bash
./bin/dev
```

This starts both:

- Rails server on `http://localhost:3000`
- Webpack dev server for hot reloading

## 🎨 Step 3: See Your Component (2 minutes)

Open your browser and navigate to:

```
http://localhost:3000/hello_world
```

You should see a page with a React component saying "Hello World"!

🎉 **Congratulations!** You have React running in your Rails app.

## 🔧 Step 4: Edit Your Component (2 minutes)

Let's make a quick change to see hot reloading in action:

1. Open `app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx`
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
touch app/javascript/src/SimpleCounter/ror_components/SimpleCounter.jsx
```

Add this content to `SimpleCounter.jsx`:

```jsx
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

Note, your layout needs to include this in the <head>:

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

1. **[Basic Configuration](../getting-started.md)** - Understand the setup
2. **[View Helpers API](../api/view-helpers-api.md)** - Learn all the options for `react_component`
3. **[Hot Module Replacement](../guides/hmr-and-hot-reloading-with-the-webpack-dev-server.md)** - Optimize your dev workflow

### Dive Deeper

1. **[Complete Tutorial](../guides/tutorial.md)** - Build a full app with Redux
2. **[Server-Side Rendering](../guides/react-server-rendering.md)** - Optimize for SEO and performance
3. **[Production Deployment](../guides/deployment.md)** - Deploy to production

### Advanced Features

1. **[Redux Integration](../javascript/react-and-redux.md)** - Manage application state
2. **[React Router](../javascript/react-router.md)** - Client-side routing
3. **[Code Splitting](../javascript/code-splitting.md)** - Optimize bundle size

## 🆘 Need Help?

- **[Troubleshooting Guide](../troubleshooting/README.md)** - Common issues and solutions
- **[React + Rails Slack](https://reactrails.slack.com)** - Join our community
- **[GitHub Issues](https://github.com/shakacode/react_on_rails/issues)** - Report bugs

## 📋 Quick Reference

### Essential Commands

```bash
# Start development servers
./bin/dev

# Generate React on Rails files
bin/rails generate react_on_rails:install

# Create a new component
bin/rails generate react_on_rails:component MyComponent

# Build for production
yarn run build
```

### Key File Locations

- **Components**: `client/app/bundles/[ComponentName]/components/`
- **Registration**: `client/app/bundles/[ComponentName]/startup/registration.js`
- **Packs**: `app/javascript/packs/`
- **Config**: `config/initializers/react_on_rails.rb`
- **Webpack**: `config/shakapacker.yml`

---

**🎉 Welcome to React on Rails!** You're now ready to build amazing full-stack applications with the best of both Rails and React.
