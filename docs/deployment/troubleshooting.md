# Troubleshooting Guide

Having issues with React on Rails? This guide covers the most common problems and their solutions.

## 🔍 Quick Diagnosis

### Is your issue with...?

| Problem Area         | Quick Check                                 | Go to Section                                                |
| -------------------- | ------------------------------------------- | ------------------------------------------------------------ |
| **Installation**     | Generator fails or components don't appear  | [Installation Issues](#-installation-issues)                 |
| **Compilation**      | Webpack errors, build failures              | [Build Issues](#-build-issues)                               |
| **Runtime**          | Components not rendering, JavaScript errors | [Runtime Issues](#-runtime-issues)                           |
| **CSS Modules**      | Styles undefined, SSR CSS crashes           | [CSS Modules Issues](#-css-modules-issues)                   |
| **Styling (FOUC)**   | Unstyled content flash, layout jumps        | [Flash of Unstyled Content](#flash-of-unstyled-content-fouc) |
| **Server Rendering** | SSR not working, hydration mismatches       | [SSR Issues](#-server-side-rendering-issues)                 |
| **Performance**      | Slow builds, large bundles, memory issues   | [Performance Issues](#-performance-issues)                   |

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

### "Flash of Unstyled Content (FOUC)"

There are two common causes of FOUC in React on Rails applications:

#### Type 1: SSR with `auto_load_bundle`

**Symptoms:** Page briefly shows unstyled content before CSS loads, particularly with SSR and `auto_load_bundle`

**Root Cause:** When using `auto_load_bundle = true` with server-side rendering, `react_component` calls trigger `append_stylesheet_pack_tag` during body rendering, but these appends must execute BEFORE the `stylesheet_pack_tag` in the `<head>`.

**Solution:** Use the `content_for :body_content` pattern to ensure appends happen before the head renders.

**See:** [FOUC Prevention Guide](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#2-css-not-loading-fouc---flash-of-unstyled-content) for detailed solutions and examples.

**Quick fix:**

```erb
<% content_for :body_content do %>
  <%= react_component "MyComponent", prerender: true %>
<% end %>
<!DOCTYPE html>
<html>
<head>
  <%= stylesheet_pack_tag(media: 'all') %>
</head>
<body>
  <%= yield :body_content %>
</body>
</html>
```

#### Type 2: Tailwind/Utility-First CSS Frameworks

**Symptoms:** Layout appears broken or jumps on initial page load—sidebars collapse, flex containers stack vertically, backgrounds are white instead of colored.

**Root Cause:** When using Tailwind CSS (or similar utility-first frameworks), your layout HTML contains CSS classes like `flex`, `h-screen`, `bg-slate-100` that have no effect until the CSS bundle loads. The browser renders the raw HTML structure without any styling.

**Example of problematic layout:**

```erb
<!-- These classes do nothing until Tailwind CSS loads -->
<div class="flex flex-row h-screen w-screen">
  <div class="flex flex-col bg-slate-100 min-w-[400px]">
    <!-- sidebar -->
  </div>
  <div class="flex-1 overflow-y-auto">
    <!-- main content -->
  </div>
</div>
```

**Solution:** Inline critical CSS for layout-affecting properties in the `<head>` before your main stylesheet loads. Use stable semantic selectors (not Tailwind utility class names) so the critical CSS doesn't drift when you add or remove utility classes.

**Step 1:** Add semantic classes to your layout's structural elements (alongside existing Tailwind classes):

```erb
<body class="app-body bg-white">
<div class="app-shell flex flex-row h-screen w-screen">
  <div class="app-sidebar flex flex-col overflow-y-auto p-5 bg-slate-100 ...">
    <!-- sidebar content -->
  </div>
  <div class="app-main flex-1 overflow-x-hidden overflow-y-auto">
    <div class="app-main-content p-5">
      <!-- main content -->
    </div>
  </div>
</div>
```

**Step 2:** Create a critical styles partial (e.g., `app/views/layouts/_critical_styles.html.erb`) targeting those semantic selectors:

```erb
<%#
  Critical CSS for preventing FOUC. Uses semantic selectors so it doesn't
  need to change when Tailwind utility classes are added or removed.
  Only update when the fundamental layout structure changes.
%>
<style data-critical-styles>
  .app-body { background-color: #fff; }
  .app-shell { display: flex; flex-direction: row; height: 100vh; width: 100vw; }
  .app-sidebar {
    display: flex; flex-direction: column; overflow-y: auto; padding: 1.25rem;
    background-color: #f1f5f9; border-style: solid;
    border-right-width: 2px; border-color: #334155;
    min-width: 400px; max-width: 400px;
  }
  .app-main { flex: 1 1 0%; overflow-x: hidden; overflow-y: auto; }
  .app-main-content { padding: 1.25rem; }
</style>
```

**Step 3:** Include it in your layout's `<head>` before the stylesheet:

```erb
<head>
  <%= render "layouts/critical_styles" %>
  <%= stylesheet_pack_tag('application', media: 'all') %>
</head>
```

**Guidelines for critical CSS:**

- **Use semantic selectors** - `.app-shell`, `.app-sidebar`, etc. instead of mirroring Tailwind class names
- **Keep it minimal** - Only define the layout shell (not component styles)
- **Focus on layout-affecting properties** - `display`, `flex`, `width`, `height`, `position`
- **Include visible defaults** - Background colors and borders that prevent jarring changes
- **Add `data-critical-styles`** - Makes it easy to test that critical styles appear before the bundle

## 🎨 CSS Modules Issues

### "CSS modules returning undefined" (Shakapacker 9+)

**Symptoms:**

- `import css from './Component.module.scss'` returns `undefined`
- SSR crashes: `Cannot read properties of undefined (reading 'className')`
- Build warning: `export 'default' (imported as 'css') was not found`

**Root Cause:** Shakapacker 9 changed the default CSS Modules configuration from default exports to named exports (`namedExport: true`).

**Solution:** Configure CSS loader to use default exports:

```javascript
// config/webpack/commonWebpackConfig.js
const { generateWebpackConfig } = require('shakapacker');

const commonWebpackConfig = () => {
  const baseWebpackConfig = generateWebpackConfig();

  baseWebpackConfig.module.rules.forEach((rule) => {
    if (rule.use && Array.isArray(rule.use)) {
      const cssLoader = rule.use.find((loader) => {
        const loaderName = typeof loader === 'string' ? loader : loader?.loader;
        return loaderName?.includes('css-loader');
      });

      if (cssLoader?.options?.modules) {
        cssLoader.options.modules.namedExport = false;
        cssLoader.options.modules.exportLocalsConvention = 'camelCase';
      }
    }
  });

  return baseWebpackConfig;
};
```

**See:** [Rspack Migration Guide](../migrating/migrating-from-webpack-to-rspack.md) for complete configuration details.

### "CSS modules work in dev but fail in SSR"

**Cause:** Server-side config overwrites CSS modules settings instead of merging them.

**Solution:** Preserve existing CSS modules configuration:

```javascript
// ❌ Wrong
cssLoader.options.modules = { exportOnlyLocals: true };

// ✅ Correct
cssLoader.options.modules = {
  ...cssLoader.options.modules,
  exportOnlyLocals: true,
};
```

### "Intermittent CSS failures with Rspack"

**Cause:** CSS extraction not properly filtered from server bundle. Rspack uses different loader paths than Webpack.

**Solution:** Filter both Webpack and Rspack CSS extract loaders:

```javascript
rule.use = rule.use.filter((item) => {
  const testValue = typeof item === 'string' ? item : item?.loader;
  return !(
    testValue?.match(/mini-css-extract-plugin/) ||
    testValue?.includes('cssExtractLoader') || // Rspack path
    testValue === 'style-loader'
  );
});
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

**💡 Tip:** Most issues are solved by ensuring your setup matches the [Quick Start Guide](../getting-started/quick-start.md) exactly.
