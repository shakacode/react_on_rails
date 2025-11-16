# Shakapacker (Rails/Webpacker) React Integration Options

You only _need_ props hydration if you need SSR. However, there's no good reason to
have your app make a second round trip to the Rails server to get initialization props.

**Server-Side Rendering (SSR)** results in Rails rendering HTML for your React components. The main reasons to use SSR are better SEO and pages display more quickly.

These gems provide advanced integration of React with [shakacode/shakapacker](https://github.com/shakacode/shakapacker):

| Gem                                                                     | Props Hydration | Server-Side-Rendering (SSR) | SSR with HMR | SSR with React-Router | SSR with Code Splitting | Node SSR |
| ----------------------------------------------------------------------- | --------------- | --------------------------- | ------------ | --------------------- | ----------------------- | -------- |
| [shakacode/react_on_rails](https://github.com/shakacode/react_on_rails) | ✅              | ✅                          | ✅           | ✅                    | ✅                      | ✅       |
| [react-rails](https://github.com/reactjs/react-rails)                   | ✅              | ✅                          |              |                       |                         |          |
| [webpacker-react](https://github.com/renchap/webpacker-react)           | ✅              |                             |              |                       |                         |          |

Note, Node SSR for React on Rails requires [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/).

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

```
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

## HMR and React Hot Reloading

Before turning HMR on, consider upgrading to the latest stable gems and packages:
https://github.com/shakacode/shakapacker#upgrading

Configure `config/shakapacker.yml` file:

```yaml
development:
  extract_css: false
  dev_server:
    hmr: true
    inline: true
```

This basic configuration alone will have HMR working with the default Shakapacker setup. However, a code save will trigger a full page refresh each time you save a file.

Webpack's HMR allows the replacement of modules for React in-place without reloading the browser. To do this, you have two options:

1. Steps below for the [github.com/pmmmwh/react-refresh-webpack-plugin](https://github.com/pmmmwh/react-refresh-webpack-plugin).
1. Deprecated steps below for using the [github.com/gaearon/react-hot-loader](https://github.com/gaearon/react-hot-loader).

### React Refresh Webpack Plugin

[github.com/pmmmwh/react-refresh-webpack-plugin](https://github.com/pmmmwh/react-refresh-webpack-plugin)

You can see an example commit of adding this [here](https://github.com/shakacode/react_on_rails_demo_ssr_hmr/commit/7e53803fce7034f5ecff335db1f400a5743a87e7).

1. Add react refresh packages:
   `yarn add @pmmmwh/react-refresh-webpack-plugin react-refresh -D`
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
   yarn add --dev react-hot-loader @hot-loader/react-dom
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
