# 15-Minute Quick Start Guide

> **Get your first React component running in Rails in 15 minutes**

This guide will have you rendering React components in your Rails app as quickly as possible. We'll skip the theory for now and focus on getting something working.

## ✅ Prerequisites

Before starting, make sure you have:

- **Rails 7+** application
- **Ruby 3.0+**
- **Node.js 18+** and **Yarn**
- **Basic familiarity** with React and Rails

> 💡 **Don't have a Rails app?** Run `rails new my_react_app` first.

## 🚀 Step 1: Install Shakapacker (2 minutes)

React on Rails uses Shakapacker to manage your React code. Install it:

```bash
# Add Shakapacker to your Gemfile
bundle add shakapacker --strict

# Run the installer
bin/rails shakapacker:install
```

You should see new files created: `config/shakapacker.yml`, `app/javascript/`, and more.

## 📦 Step 2: Install React on Rails (3 minutes)

Add the React on Rails gem and run its installer:

```bash
# Add the gem
bundle add react_on_rails --strict

# Commit your changes (required for generator)
git add . && git commit -m "Add react_on_rails gem"

# Run the installer
bin/rails generate react_on_rails:install
```

This creates:

- React component files in `client/`
- A sample controller and view
- Webpack configuration

## 🎯 Step 3: Start the Development Server (1 minute)

Start both Rails and the Webpack dev server:

```bash
./bin/dev
```

This runs both:

- Rails server on `http://localhost:3000`
- Webpack dev server with hot reloading

> 💡 **New file?** The installer created `bin/dev` which starts both servers using Foreman.

## 🎉 Step 4: See Your First Component (1 minute)

Open your browser and visit:

**http://localhost:3000/hello_world**

You should see a React component saying "Hello World" with Rails props!

## 🔍 Step 5: Understand What Happened (5 minutes)

Let's look at what was created:

### The Rails View (`app/views/hello_world/index.html.erb`)

```erb
<h1>Hello World</h1>
<%= react_component("HelloWorld", props: @hello_world_props) %>
```

### The React Component (`client/app/components/HelloWorld.jsx`)

```jsx
import React from 'react';
import PropTypes from 'prop-types';

const HelloWorld = (props) => (
  <div>
    <h3>Hello, {props.name}!</h3>
    <p>Say hello to React and Rails!</p>
  </div>
);

HelloWorld.propTypes = {
  name: PropTypes.string.isRequired,
};

export default HelloWorld;
```

### The Registration (`client/app/packs/hello-world-bundle.js`)

```javascript
import ReactOnRails from 'react-on-rails';
import HelloWorld from '../components/HelloWorld';

ReactOnRails.register({
  HelloWorld,
});
```

## ✨ Step 6: Make It Your Own (3 minutes)

Try editing the React component:

1. **Open** `client/app/components/HelloWorld.jsx`
2. **Change** the message to something personal
3. **Save** the file
4. **Watch** the browser update automatically (hot reloading!)

Try changing the props from Rails:

1. **Open** `app/controllers/hello_world_controller.rb`
2. **Modify** the `@hello_world_props` hash
3. **Refresh** the browser to see the changes

## 🎊 Congratulations!

You now have React components running in Rails with:

- ✅ Hot reloading for fast development
- ✅ Data passing from Rails to React
- ✅ Proper component registration
- ✅ Development and production builds

## 🚶‍♂️ What's Next?

Now that you have the basics working, choose your next step:

### Learn the Fundamentals

- **[How React on Rails Works](../guides/fundamentals/how-it-works.md)** - Understand the architecture
- **[Server-Side Rendering](../guides/fundamentals/server-rendering.md)** - Enable SSR for better SEO
- **[Props and Data Flow](../guides/fundamentals/props.md)** - Master data passing

### Add More Features

- **[Redux Integration](../guides/state-management/redux.md)** - Add global state management
- **[React Router](../guides/routing/react-router.md)** - Enable client-side routing
- **[Styling](../guides/styling/README.md)** - CSS, Sass, and CSS-in-JS options

### Go to Production

- **[Deployment Guide](../guides/deployment/README.md)** - Deploy to Heroku, AWS, etc.
- **[Performance Optimization](../guides/performance/README.md)** - Optimize bundle size and loading

## 🆘 Having Issues?

If something isn't working:

1. **Check** the [Common Issues](../troubleshooting/common-issues.md) guide
2. **Search** [GitHub Issues](https://github.com/shakacode/react_on_rails/issues)
3. **Ask** on [GitHub Discussions](https://github.com/shakacode/react_on_rails/discussions)

**Most common issue:** Make sure you committed your changes before running the generator!

---

**⏱️ Time:** ~15 minutes | **Next:** [Core Concepts](../guides/fundamentals/README.md) | **Help:** [Troubleshooting](../troubleshooting/README.md)
