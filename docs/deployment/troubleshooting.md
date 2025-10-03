# Troubleshooting Guide

Having issues with React on Rails? This guide covers the most common problems and their solutions.

## 🔍 Quick Diagnosis

### Is your issue with...?

| Problem Area         | Quick Check                                 | Go to Section                                |
| -------------------- | ------------------------------------------- | -------------------------------------------- |
| **Installation**     | Generator fails or components don't appear  | [Installation Issues](#-installation-issues) |
| **Compilation**      | Webpack errors, build failures              | [Build Issues](#-build-issues)               |
| **Runtime**          | Components not rendering, JavaScript errors | [Runtime Issues](#-runtime-issues)           |
| **Server Rendering** | SSR not working, hydration mismatches       | [SSR Issues](#-server-side-rendering-issues) |
| **Performance**      | Slow builds, large bundles, memory issues   | [Performance Issues](#-performance-issues)   |

## 🚨 Installation Issues

### "Generator fails with uncommitted changes"

**Error:** `You have uncommitted changes. Please commit or stash them.`

**Solution:**

```bash
git add .
git commit -m "Add react_on_rails gem"
bin/rails generate react_on_rails:install
```

**Why:** The generator needs clean git state to show you exactly what it changed.

### "Node/Yarn not found"

**Error:** `Yarn executable was not detected` or `Node.js not found`

**Solution:**

- Install Node.js 20+ from [nodejs.org](https://nodejs.org)
- Install Yarn: `npm install -g yarn`
- Or use system package manager: `brew install node yarn`

## 🔧 Build Issues

### "Module not found: Can't resolve 'react-on-rails'"

**Error in browser console or webpack output**

**Solution:**

```bash
# Make sure the NPM package is installed
yarn add react-on-rails

# If using local development with yalc
cd react_on_rails/
yalc publish
cd your_app/
yalc add react-on-rails
```

### "Webpack compilation failed"

**Check these common causes:**

1. **Syntax errors** in your React components
2. **Missing dependencies** in package.json
3. **Incorrect imports** (check file paths and extensions)

**Debug steps:**

```bash
# Run webpack directly to see detailed errors
bin/webpack
# Or in development mode
bin/webpack --mode development
```

### "ExecJS::RuntimeUnavailable"

**Error:** JavaScript runtime not available

**Solution:**

```bash
# Add to your Gemfile
gem 'execjs'
gem 'mini_racer', platforms: :ruby

# Or use Node.js runtime
export EXECJS_RUNTIME=Node
```

## ⚡ Runtime Issues

### "Component not rendering"

**Symptoms:** Empty div or no output where component should be

**Check list:**

1. **Component registered?**

   ```javascript
   import ReactOnRails from 'react-on-rails';
   import MyComponent from './MyComponent';
   ReactOnRails.register({ MyComponent });
   ```

2. **Bundle included in view?**

   ```erb
   <%= javascript_pack_tag 'my-bundle' %>
   <%= react_component('MyComponent') %>
   ```

3. **Component exported correctly?**
   ```javascript
   // Use default export
   export default MyComponent;
   // Not named export for registration
   ```

### "ReferenceError: window is not defined"

**Error during server-side rendering**

**Solution:** Check your component for browser-only code:

```javascript
// ❌ Bad - will break SSR
const width = window.innerWidth;

// ✅ Good - check if window exists
const width = typeof window !== 'undefined' ? window.innerWidth : 1200;

// ✅ Better - use useEffect hook
useEffect(() => {
  const width = window.innerWidth;
  // Use width here
}, []);
```

### "Props not updating"

**Symptoms:** Component shows initial props but doesn't update

**Common causes:**

1. **Caching** - Rails fragment caching may cache React components
2. **Turbo/Turbolinks** - Page navigation isn't re-initializing React
3. **Development mode** - Hot reloading not working

**Solutions:**

```erb
<!-- Disable caching for development -->
<% unless Rails.env.development? %>
  <% cache do %>
    <%= react_component('MyComponent', props: @props) %>
  <% end %>
<% else %>
  <%= react_component('MyComponent', props: @props) %>
<% end %>
```

## 🖥️ Server-Side Rendering Issues

### "Server rendering not working"

**Check:**

1. **Prerender enabled?**

   ```erb
   <%= react_component('MyComponent', props: @props, prerender: true) %>
   ```

2. **JavaScript runtime available?**

   ```bash
   # Add to Gemfile if missing
   gem 'mini_racer'
   ```

3. **No browser-only code in component?** (see "window is not defined" above)

### "Hydration mismatch warnings"

**Symptoms:** React warnings about server/client content differences

**Common causes:**

- Different props between server and client render
- Browser-only code affecting initial render
- Date/time differences between server and client

**Debug:**

```javascript
// Add this to see what props are being used
console.log('Server props:', props);
console.log('Client render time:', new Date());
```

## 🐌 Performance Issues

### "Slow webpack builds"

**Solutions:**

1. **Enable caching:**

   ```yaml
   # config/shakapacker.yml
   development:
     cache_manifest: true
   ```

2. **Use webpack-dev-server:**

   ```bash
   ./bin/dev  # Uses Procfile.dev with webpack-dev-server
   ```

3. **Check for large dependencies:**
   ```bash
   yarn why package-name
   webpack-bundle-analyzer public/packs/manifest.json
   ```

### "Large bundle sizes"

**Solutions:**

1. **Code splitting:**

   ```javascript
   // Use dynamic imports
   const MyComponent = lazy(() => import('./MyComponent'));
   ```

2. **Check bundle analysis:**

   ```bash
   ANALYZE=true bin/webpack
   ```

3. **Remove unused dependencies:**
   ```bash
   yarn remove unused-package
   ```

## 🛠️ Advanced Debugging

### Enable verbose logging

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.logging_on_server = true
  config.server_render_method = 'NodeJS' # for better error messages
end
```

### Debug webpack configuration

```bash
# See the final webpack config
bin/webpack --config-dump
```

### Check component registration

```javascript
// In browser console
console.log(ReactOnRails.getComponents());
```

## 🆘 Still Stuck?

### Before asking for help, gather this info

- React on Rails version (`bundle list react_on_rails`)
- Rails version (`rails -v`)
- Ruby version (`ruby -v`)
- Node version (`node -v`)
- Error messages (full stack trace)
- Relevant code snippets

### Get community help

- **[GitHub Issues](https://github.com/shakacode/react_on_rails/issues)** - Bug reports and feature requests
- **[GitHub Discussions](https://github.com/shakacode/react_on_rails/discussions)** - Questions and help
- **[React + Rails Slack](https://reactrails.slack.com)** - Real-time community support

### Professional support

- **[ShakaCode](https://www.shakacode.com)** offers consulting and support services
- **[React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/)** includes priority support

---

**💡 Tip:** Most issues are solved by ensuring your setup matches the [Quick Start Guide](../quick-start/README.md) exactly.
