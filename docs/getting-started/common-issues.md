# Common Issues & Quick Fixes

> Quick troubleshooting reference for React on Rails. For in-depth debugging, see the [Troubleshooting Guide](../deployment/troubleshooting.md).

## Diagnostic Command

Before diving into specific issues, run the doctor command:

```bash
bundle exec rake react_on_rails:doctor

# For more detailed output:
VERBOSE=true bundle exec rake react_on_rails:doctor
```

This checks your environment, dependencies, and configuration for common problems.

---

## Component Not Rendering

**Symptoms:** Blank space where component should be, no console errors

### Quick Checklist

1. **Component registered?**
   - With auto-bundling: Component must be in a `ror_components` directory
   - Without auto-bundling: Check for `ReactOnRails.register({ ComponentName })`

2. **Name matches exactly?**

   ```erb
   <%# The name must match exactly (case-sensitive, check for typos) %>
   <%= react_component("MyComponent", props: {}) %>
   ```

3. **Bundle loaded in layout?**

   ```erb
   <%# In app/views/layouts/application.html.erb <head> %>
   <%= javascript_pack_tag %>
   ```

4. **Auto-bundling enabled?**
   Check `config.auto_load_bundle = true` in `config/initializers/react_on_rails.rb`

   > **Note:** The generator sets this automatically in v16.0+, so you shouldn't need to add it manually for new installations.

5. **Check browser console** for JavaScript errors

---

## Hydration Mismatch Errors

**Symptoms:** Console warning about hydration, content flickers on page load

### Common Causes

1. **Using non-deterministic values in render:**

   ```jsx
   import React, { useState, useEffect } from 'react';

   // BAD - different on server vs client
   const MyComponent = () => <div>{Date.now()}</div>;

   // GOOD - move to useEffect
   const MyComponent = () => {
     const [time, setTime] = useState(null);
     useEffect(() => setTime(Date.now()), []);
     return <div>{time}</div>;
   };
   ```

2. **Accessing browser APIs during render:**

   ```jsx
   // BAD
   const width = window.innerWidth;

   // GOOD - guard with typeof check
   const width = typeof window !== 'undefined' ? window.innerWidth : 0;
   ```

3. **Props differ between server and client:**
   - Ensure the exact same props are passed in both renders
   - Check for timezone differences in date formatting

---

## SSR Fails / Server Rendering Errors

**Symptoms:** Error during server render, works fine client-side only

### Debug Steps

```bash
# Run diagnostics
bundle exec rake react_on_rails:doctor

# Check server bundle exists (location may vary based on Shakapacker config)
ls -la public/packs/server-bundle*.js
```

### Common Causes

1. **Component uses browser APIs:**

   ```jsx
   // These don't exist on server - guard them
   if (typeof window !== 'undefined') {
     // Browser-only code
   }
   ```

2. **Missing server bundle configuration:**

   ```ruby
   # config/initializers/react_on_rails.rb
   ReactOnRails.configure do |config|
     config.server_bundle_js_file = "server-bundle.js"
   end
   ```

3. **Async operations in render:**
   - ExecJS doesn't support async/await in server rendering
   - Use React on Rails Pro for async SSR support

---

## "Module not found" / Webpack Errors

**Symptoms:** Build fails, can't resolve imports

### Solutions

```bash
# Clear and reinstall dependencies
rm -rf node_modules
yarn install  # or: npm install, pnpm install

# Rebuild assets
yarn build  # or: npm run build, pnpm build

# Check Shakapacker config
cat config/shakapacker.yml
```

### Common Causes

1. **npm package not installed:**

   ```bash
   yarn add react-on-rails
   # or: npm install react-on-rails
   # or: pnpm add react-on-rails
   ```

2. **Incorrect import path:**
   ```jsx
   // Check the actual file location matches your import
   import MyComponent from '../components/MyComponent';
   ```

---

## "Cannot find module 'react-on-rails'"

**Symptoms:** JavaScript error about missing react-on-rails module

### Solution

The gem and npm package must both be installed:

```bash
# Install npm package
yarn add react-on-rails
# or: npm install react-on-rails
# or: pnpm add react-on-rails
```

---

## Hot Reloading Not Working

**Symptoms:** Changes don't appear without full page refresh

### Checklist

1. **Using bin/dev?**

   ```bash
   # This starts both Rails and webpack-dev-server
   bin/dev
   ```

2. **Check webpack-dev-server is running:**
   - Look for webpack output in terminal
   - Check `http://localhost:3035` responds

3. **Verify HMR configuration in shakapacker.yml:**
   ```yaml
   development:
     dev_server:
       hmr: true
   ```

---

## Assets Not Compiling in Production

**Symptoms:** Missing JavaScript/CSS in production

### Checklist

```bash
# Ensure assets compile
RAILS_ENV=production bundle exec rake assets:precompile

# Check output directory
ls -la public/packs/
```

### Common Causes

1. **Missing NODE_ENV:**

   ```bash
   NODE_ENV=production RAILS_ENV=production rake assets:precompile
   ```

2. **Build dependencies missing in production:**
   - Check `package.json` dependencies vs devDependencies

---

## TypeError: Cannot read property of undefined

**Symptoms:** Runtime error when accessing props

### Common Causes

1. **Props not passed correctly from Rails:**

   ```erb
   <%# Make sure props is a hash %>
   <%= react_component("MyComponent", props: { user: @user.as_json }) %>
   ```

2. **Destructuring undefined props:**
   ```jsx
   // Add default values
   const MyComponent = ({ user = {} }) => {
     return <div>{user.name || 'Anonymous'}</div>;
   };
   ```

---

## Still Stuck?

1. **Check the detailed [Troubleshooting Guide](../deployment/troubleshooting.md)**
2. **Search [GitHub Issues](https://github.com/shakacode/react_on_rails/issues)**
3. **Ask in [GitHub Discussions](https://github.com/shakacode/react_on_rails/discussions)**
4. **Join [React + Rails Slack](https://reactrails.slack.com)**
5. **Professional support**: [react_on_rails@shakacode.com](mailto:react_on_rails@shakacode.com)
