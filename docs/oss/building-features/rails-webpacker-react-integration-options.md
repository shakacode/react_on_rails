# Shakapacker (Rails/Webpacker) React Integration Options

> **Looking for a comparison of React on Rails with alternatives like Inertia.js, Hotwire, and react-rails?** See [Comparison with Alternatives](../getting-started/comparison-with-alternatives.md).

You only _need_ props hydration if you need SSR. However, there's no good reason to
have your app make a second round trip to the Rails server to get initialization props.

**Server-Side Rendering (SSR)** results in Rails rendering HTML for your React components. The main reasons to use SSR are better SEO and pages display more quickly.

These gems provide advanced integration of React with [shakacode/shakapacker](https://github.com/shakacode/shakapacker):

| Gem                                                                     | Props Hydration | Server-Side-Rendering (SSR) | SSR with HMR | SSR with React-Router | SSR with Code Splitting | Node SSR |
| ----------------------------------------------------------------------- | --------------- | --------------------------- | ------------ | --------------------- | ----------------------- | -------- |
| [shakacode/react_on_rails](https://github.com/shakacode/react_on_rails) | ✅              | ✅                          | ✅           | ✅                    | ✅                      | ✅       |
| [react-rails](https://github.com/reactjs/react-rails)                   | ✅              | ✅                          |              |                       |                         |          |
| [webpacker-react](https://github.com/renchap/webpacker-react)           | ✅              |                             |              |                       |                         |          |

Note, Node SSR for React on Rails requires [React on Rails Pro](../../pro/react-on-rails-pro.md).

---

As mentioned, you don't _need_ to use a gem to integrate Rails with React.

If you're not concerned with view helpers to pass props or server rendering, you can do it yourself:

```erb
<%# views/layouts/application.html.erb %>

<%= content_tag :div,
  id: "hello-react",
  data: {
    message: 'Hello!',
    name: 'David'
}.to_json do %>
<% end %>
```

```js
// app/javascript/packs/hello_react.js

const Hello = (props) => (
  <div className="react-app-wrapper">
    <img src={clockIcon} alt="clock" />
    <h5 className="hello-react">
      {props.message} {props.name}!
    </h5>
  </div>
);

// Render component with data
document.addEventListener('DOMContentLoaded', () => {
  const node = document.getElementById('hello-react');
  const data = JSON.parse(node.getAttribute('data'));

  ReactDOM.render(<Hello {...data} />, node);
});
```

---

## Suppress warning related to Can't resolve 'react-dom/client' in React < 18

You may see a warning like this when building a Webpack bundle using any version of React below 18:

```text
Module not found: Error: Can't resolve 'react-dom/client' in ....
```

It can be safely [suppressed](https://webpack.js.org/configuration/other-options/#ignorewarnings) in your Webpack configuration. The following is an example of this suppression in `config/webpack/commonWebpackConfig.js`:

```js
const { webpackConfig: baseClientWebpackConfig, merge } = require('shakapacker');

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

const ignoreWarningsConfig = {
  ignoreWarnings: [/Module not found: Error: Can't resolve 'react-dom\/client'/],
};

const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions, ignoreWarningsConfig);

module.exports = commonWebpackConfig;
```

---

## Legacy Webpacker / Webpack 4 migration shims

If you are on Webpacker 5 / Webpack 4, whether you are migrating from `react-rails` or upgrading an existing React on Rails app, prefer upgrading to Shakapacker first when you can.

:::caution

These shims are not covered by React on Rails CI. Treat them as a temporary bridge for apps still on Webpacker 5 /
Webpack 4, and verify your full app locally before relying on them.

:::

Webpack 4 does not support the `exports` field in `package.json`, so subpath imports such as `react-on-rails/client` resolve to a literal file path that does not exist; the package root import falls back to the `main` field (`lib/ReactOnRails.full.js`). The `react-on-rails/client` subpath export has been present since [React on Rails 14.2.0](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#1420---2025-03-03), so any Webpacker 5 / Webpack 4 app on 14.2.0 or newer may need these shims. Additionally, the built files in `lib/` use modern JavaScript syntax, such as optional chaining and nullish coalescing, that Webpack 4's default parser does not support; you may need Babel to transpile those files after fixing the import path.

Keep each shim explicit and narrow:

1. Import the package root from application packs:

   **When to apply:** Only change imports that currently point to `react-on-rails/client`.

   ```diff
   - import ReactOnRails from 'react-on-rails/client';
   + import ReactOnRails from 'react-on-rails';
   ```

   The root import uses the full build and may log a browser console warning about bundled server-rendering code. It also includes a small amount of extra server-rendering code (the SSR capability module) in the client bundle compared to the `react-on-rails/client` entry point. That trade-off is expected for this temporary shim; remove the shim and return to the current client entry point after upgrading to Shakapacker/Webpack 5 or newer.

2. Ensure Babel can parse modern syntax used by current packages. Add these plugins to your existing Babel config without replacing existing presets or plugins:

   **When to apply:** Only add these plugins if Webpack 4 fails to parse modern syntax; first check whether your
   existing `@babel/preset-env` targets already cover optional chaining and nullish coalescing.

   If you want to confirm whether your `@babel/preset-env` targets already include optional chaining and
   nullish coalescing, set `debug: true` on the `@babel/preset-env` options and check the build output for
   `optional-chaining` and `nullish-coalescing-operator` in the "Using plugins" list. Use the `transform-*` package
   names when your pinned Babel stack provides them; if a legacy Babel stack cannot resolve those packages, use the
   equivalent `proposal-*` package names that match your installed `@babel/core`. If the transforms already appear in
   the preset output, you can skip the standalone packages; when in doubt, install them because they are no-ops if
   `preset-env` already transforms the syntax.

   ```bash
   yarn add -D @babel/plugin-transform-optional-chaining @babel/plugin-transform-nullish-coalescing-operator
   # or: npm install -D @babel/plugin-transform-optional-chaining @babel/plugin-transform-nullish-coalescing-operator
   # or: pnpm add -D @babel/plugin-transform-optional-chaining @babel/plugin-transform-nullish-coalescing-operator
   # or: bun add -D @babel/plugin-transform-optional-chaining @babel/plugin-transform-nullish-coalescing-operator
   ```

   If a legacy stack reports peer dependency warnings for the `transform-*` package names, use the equivalent
   `@babel/plugin-proposal-optional-chaining` and `@babel/plugin-proposal-nullish-coalescing-operator` packages
   that match your pinned `@babel/core`.

   Add the plugins to the top-level `plugins` array, not inside an `env`-conditional block. The diff below
   applies to `babel.config.js`; for `babel.config.json`, add the same plugin strings to the equivalent JSON
   object instead.

   ```diff
   // babel.config.js
   module.exports = {
     presets: [
       // keep existing presets
     ],
     plugins: [
   +   '@babel/plugin-transform-optional-chaining',
   +   '@babel/plugin-transform-nullish-coalescing-operator',
       // keep existing plugins
     ],
   };
   ```

3. Transpile the React on Rails package files from `node_modules` so Webpack 4 can parse them consistently. `babel-loader` ships with Webpacker 5, so no extra loader install is needed.

   **When to apply:** Add this loader if Webpack 4 reports parse errors from `node_modules/react-on-rails`.
   Step 2's Babel plugins only affect `node_modules/react-on-rails` after this loader rule is in place, so Step 2
   and Step 3 work together to transpile the package.

   Before touching `config/webpack/environment.js`, confirm these prerequisites:
   - Use a project-wide `babel.config.js` or `babel.config.json`. Package-scoped `.babelrc` files and `package.json#babel` settings will not apply when Babel processes files inside `node_modules/react-on-rails`.
   - If your app only has `.babelrc`, move that config into `babel.config.js` before adding this rule.
   - Confirm Step 2 is in place, either through the standalone optional chaining and nullish coalescing plugins or through existing `@babel/preset-env` targets that already include those transforms.
   - If your `@babel/preset-env` config uses `modules: false`, add a `babel.config.js` `overrides` entry that applies `@babel/plugin-transform-modules-commonjs` to `node_modules/react-on-rails`; otherwise Webpack 4 can still fail on the package's ESM files.
   - If your Webpacker stack pins Babel dependencies, choose plugin versions compatible with your installed `@babel/core`.

   For a `modules: false` setup, keep that setting for the rest of your app and add a narrow override:

   ```bash
   yarn add -D @babel/plugin-transform-modules-commonjs
   # or: npm install -D @babel/plugin-transform-modules-commonjs
   # or: pnpm add -D @babel/plugin-transform-modules-commonjs
   # or: bun add -D @babel/plugin-transform-modules-commonjs
   ```

   ```js
   // babel.config.js
   module.exports = {
     presets: [
       [
         '@babel/preset-env',
         {
           // keep existing options
           modules: false,
         },
       ],
     ],
     overrides: [
       {
         test: /node_modules[\\/]react-on-rails[\\/]/,
         plugins: ['@babel/plugin-transform-modules-commonjs'],
       },
     ],
   };
   ```

   `rootMode: 'upward'` tells Babel to walk up from `node_modules/react-on-rails` to the project root so it
   can find your project-wide `babel.config.js` or `babel.config.json`. In a monorepo where the Rails app
   lives in a subdirectory, confirm that Babel resolves the app config you expect. You can run
   `npx --package @babel/cli babel --show-config-for <file>` to inspect the resolved config; if Babel picks up an ancestor config
   unexpectedly, set `configFile` in the `babel-loader` options to point directly at your app's config.

   Webpacker 5's default JavaScript rule excludes `node_modules`, so files from `react-on-rails` will not reach
   `babel-loader` unless you add a separate package-scoped rule. Keep the new rule narrow instead of removing the
   global `node_modules` exclusion from Webpacker's default loader.

   ```diff
   // config/webpack/environment.js
   // Webpacker 5 uses '@rails/webpacker', not 'shakapacker'.
   const { environment } = require('@rails/webpacker');

   + environment.loaders.append('react-on-rails-js', {
   +   test: /\.[cm]?js$/,
   +   include: /node_modules[\\/]react-on-rails[\\/]/,
   +   use: [
   +     {
   +       loader: 'babel-loader',
   +       options: {
   +         cacheDirectory: true,
   +         rootMode: 'upward',
   +       },
   +     },
   +   ],
   + });

   module.exports = environment;
   ```

   If you see parse errors from `react-on-rails` files after changing the Babel config, clear the `babel-loader`
   cache (typically `node_modules/.cache/babel-loader/` in the project root) and re-run the build.

   If your `environment.js` already has other configuration, add the `loaders.append` block before the existing `module.exports` line.

   Keep this rule scoped to `node_modules/react-on-rails`; broad `node_modules` transpilation can slow legacy builds and introduce unrelated Babel differences. After you upgrade the app to Shakapacker/Webpack 5 or newer, remove the shim and use the package entry points documented for current installs.

4. If your test suite uses Jest directly, remember that Jest does not use this Webpack loader. Add
   `react-on-rails` to `transformIgnorePatterns` in `jest.config.js` so Jest also transpiles React on Rails.

   **When to apply:** Only add this Jest config if your project runs Jest directly.

   If you do not have existing `transformIgnorePatterns`, npm, yarn, and bun projects can use the single package lookahead:

   ```js
   // jest.config.js
   module.exports = {
     // keep existing config
     transformIgnorePatterns: ['node_modules/(?!react-on-rails)'],
   };
   ```

   For pnpm projects, use the two-pattern form so Jest also handles pnpm's `.pnpm` store path:

   ```js
   // jest.config.js
   module.exports = {
     // keep existing config
     transformIgnorePatterns: [
       '<rootDir>/node_modules/\\.pnpm/(?!(react-on-rails)@)',
       'node_modules/(?!\\.pnpm|react-on-rails)',
     ],
   };
   ```

   If you already have `transformIgnorePatterns` entries, merge `react-on-rails` into the existing lookahead
   rather than replacing the whole setting:

   ```js
   // jest.config.js
   // Before: transformIgnorePatterns: ['node_modules/(?!\\.pnpm|other-esm-package)']
   // After (add react-on-rails to the existing lookahead group):
   module.exports = {
     // keep existing config
     transformIgnorePatterns: [
       '<rootDir>/node_modules/\\.pnpm/(?!(react-on-rails|other-esm-package)@)',
       'node_modules/(?!\\.pnpm|react-on-rails|other-esm-package)',
     ],
   };
   ```

---

## HMR and React Hot Reloading

Before turning HMR on, consider upgrading to the latest stable gems and packages:
https://github.com/shakacode/shakapacker#upgrading

Configure `config/shakapacker.yml` file:

```yaml
development:
  extract_css: false
  dev_server:
    hmr: true
```

This basic configuration alone will have HMR working with the default Shakapacker setup. However, a code save will trigger a full page refresh each time you save a file.

Webpack's HMR allows the replacement of modules for React in-place without reloading the browser. To do this, you have two options:

1. Steps below for the [github.com/pmmmwh/react-refresh-webpack-plugin](https://github.com/pmmmwh/react-refresh-webpack-plugin).
1. Deprecated steps below for using the [github.com/gaearon/react-hot-loader](https://github.com/gaearon/react-hot-loader).

### React Refresh Webpack Plugin

[github.com/pmmmwh/react-refresh-webpack-plugin](https://github.com/pmmmwh/react-refresh-webpack-plugin)

You can see an example commit in the maintained SSR + HMR tutorial repo that
[adds React Refresh](https://github.com/shakacode/react-on-rails-demo-ssr-hmr/commit/7e53803fce7034f5ecff335db1f400a5743a87e7).

1. Add react refresh packages:
   ```bash
   yarn add -D @pmmmwh/react-refresh-webpack-plugin react-refresh
   # or: npm install -D @pmmmwh/react-refresh-webpack-plugin react-refresh
   # or: pnpm add -D @pmmmwh/react-refresh-webpack-plugin react-refresh
   ```
2. Update `babel.config.js` adding
   ```js
   plugins: [
     process.env.WEBPACK_DEV_SERVER && 'react-refresh/babel',
     // other plugins
   ```
3. Update `config/webpack/development.js`, only including the plugin if running the WEBPACK_DEV_SERVER

   ```js
   const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
   const environment = require('./environment');

   const isWebpackDevServer = process.env.WEBPACK_DEV_SERVER;

   //plugins
   if (isWebpackDevServer) {
     environment.plugins.append('ReactRefreshWebpackPlugin', new ReactRefreshWebpackPlugin({}));
   }
   ```

---

### React Hot Loader (Deprecated)

1. Add the `react-hot-loader` and ` @hot-loader/react-dom` npm packages.

   ```bash
   yarn add -D react-hot-loader @hot-loader/react-dom
   # or: npm install -D react-hot-loader @hot-loader/react-dom
   # or: pnpm add -D react-hot-loader @hot-loader/react-dom
   ```

2. Update your babel config, `babel.config.js`. Add the plugin `react-hot-loader/babel`
   with the option `safetyNet: false`:

   ```js
   {
     plugins: [
       [
         'react-hot-loader/babel',
         {
           safetyNet: false,
         },
       ],
     ],
   }
   ```

3. Add changes like this to your entry points:

   ```diff
   // app/javascript/app.jsx

   import React from 'react';
   + import { hot } from 'react-hot-loader/root';

   const App = () => <SomeComponent(s) />

   - export default App;
   + export default hot(App);
   ```

4. Adjust your Webpack configuration for development so that `sourceMapContents` option for the SASS loader is `false`:

   ```diff
   // config/webpack/development.js

   process.env.NODE_ENV = process.env.NODE_ENV || 'development'

   const environment = require('./environment')

   // allows for editing sass/scss files directly in browser
   + if (!module.hot) {
   +   environment.loaders.get('sass').use.find(item => item.loader === 'sass-loader').options.sourceMapContents = false
   + }
   +
   module.exports = environment.toWebpackConfig()
   ```

5. Adjust your `config/webpack/environment.js`:

   ```diff
   // config/webpack/environment.js

   // ...

   // Fixes: React-Hot-Loader: react-🔥-dom patch is not detected. React 16.6+ features may not work.
   // https://github.com/gaearon/react-hot-loader/issues/1227#issuecomment-482139583
   + environment.config.merge({ resolve: { alias: { 'react-dom': '@hot-loader/react-dom' } } });

   module.exports = environment;
   ```
