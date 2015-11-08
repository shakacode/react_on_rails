# Manual Installation
Follow these steps if you choose to forgo the generator:

1. Globally expose React in your webpack config like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/webpack.client.base.config.js#L31):

  ```javascript
  module: {
    loaders: [
      // React is necessary for the client rendering:
      { test: require.resolve('react'), loader: 'expose?React' },

      // For React 0.14
      { test: require.resolve('react-dom'), loader: 'expose?ReactDOM' }, // not in the server one
  ```


2. Require `react_on_rails` in your `application.js` like  [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/361f4338ebb39a5d3934b00cb6d6fcf494773000/app/assets/javascripts/application.js#L15). It possibly should come after you require `turbolinks`:

  ```
  //= require react_on_rails
  ```
3. Expose your client globals like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/app/startup/clientGlobals.jsx#L3):

  ```javascript
  import App from './ClientApp';
  window.App = App;
  ```
4. Put your client globals file as webpack entry points like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/webpack.client.rails.config.js#L22). Similar pattern for server rendering.

  ```javascript
  config.entry.app.push('./app/startup/clientGlobals');
  ```

## Additional Steps For Server Rendering (option `prerender` shown below)
See the next section for a sample webpack.server.rails.config.js.

1. Expose your server globals like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/app/startup/serverGlobals.jsx#L7)

  ```javascript
  import App from './ServerApp';
  global.App = App;
  ```
2. Make the server globals file an entry point in your webpack config, like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/webpack.server.rails.config.js#L7)

  ```javascript
  entry: ['./app/startup/serverGlobals'],
  ```
3. Ensure the name of your ouput file (shown [here](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/webpack.server.rails.config.js#L9)) of your server bundle corresponds to the configuration of the gem. The default path is `app/assets/javascripts/generated`. See below for customization of configuration variables.
4. Expose `React` in your webpack config, like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/webpack.server.rails.config.js#L23)

```javascript
{ test: require.resolve('react'), loader: 'expose?React' },

// For React 0.14
{ test: require.resolve('react-dom/server'), loader: 'expose?ReactDOMServer' }, // not in client one, only server
```

### Sample webpack.server.rails.config.js (ONLY for server rendering)
Be sure to check out the latest example version of [client/webpack.server.rails.config.js](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/webpack.server.rails.config.js).

```javascript
// Common webpack configuration for server bundle

module.exports = {

  // the project dir
  context: __dirname,
  entry: ['./app/startup/serverGlobals'],
  output: {
    filename: 'server-bundle.js',
    path: '../app/assets/javascripts/generated',

    // CRITICAL to set libraryTarget: 'this' for enabling Rails to find the exposed modules IF you
    //   use the "expose" webpackfunctionality. See startup/serverGlobals.jsx.
    // NOTE: This is NOT necessary if you use the syntax of global.MyComponent = MyComponent syntax.
    // See http://webpack.github.io/docs/configuration.html#externals for documentation of this option
    //libraryTarget: 'this',
  },
  resolve: {
    extensions: ['', '.webpack.js', '.web.js', '.js', '.jsx', 'config.js'],
  },
  module: {
    loaders: [
      {test: /\.jsx?$/, loader: 'babel-loader', exclude: /node_modules/},

      // React is necessary for the client rendering:
      { test: require.resolve('react'), loader: 'expose?React' },
      { test: require.resolve('react-dom/server'), loader: 'expose?ReactDOMServer' },
    ],
  },
};
```

## What Happens?

Here's what the browser will render with a call to the `react_component` helper.
![2015-09-28_20-24-35](https://cloud.githubusercontent.com/assets/1118459/10157268/41435186-6624-11e5-9341-6fc4cf35ee90.png)

  If you're curious as to what the gem generates for the server and client rendering, see [`spec/dummy/client/app/startup/serverGlobals.jsx`](https://github.com/shakacode/react_on_rails/blob/master/spec/dummy/spec/sample_generated_js/server-generated.js)
  and [`spec/dummy/client/app/startup/ClientReduxApp.jsx`](https://github.com/shakacode/react_on_rails/blob/master/spec/dummy/spec/sample_generated_js/client-generated.js) for examples of this. Note, this is not the code that you are providing. You can see the client code by viewing the page source.

* **props**: [hash | string of json] Properties to pass to the react object. See this example if you're using Jbuilder: [react-webpack-rails-tutorial view rendering props using jBuilder](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/app/views/pages/index.html.erb#L20)

```erb
<%= react_component('App', render(template: "/comments/index.json.jbuilder"),
    generator_function: true, prerender: true) %>
```
* **options:** [hash]
  * **generator_function**: <true/false> default is false, set to true if you want to use a generator function rather than a React Component.
  * **prerender**: <true/false> set to false when debugging!
  * **trace**: <true/false> set to true to print additional debugging information in the browser default is true for development, off otherwise
  * **replay_console**: <true/false> Default is true. False will disable echoing server rendering logs, which can make troubleshooting server rendering difficult.
  * Any other options are passed to the content tag, including the id.

# JavaScript

1. Configure your webpack configuration to create the file used for server rendering if you plan to do server rendering.
2. Follow the examples in `spec/dummy/client/app/startup/clientGlobals.jsx` to expose your react components for client side rendering.

  ```ruby
  import HelloWorld from '../components/HelloWorld';
  window.HelloWorld = HelloWorld;
  ```
3. Follow the examples in `spec/dummy/client/app/startup/serverGlobals.jsx` to expose your react components for server side rendering.

  ```ruby
  import HelloWorld from '../components/HelloWorld';
  global.HelloWorld = HelloWorld;
  ```

## React 0.13 vs. React 0.14
The main difference for using react_on_rails is that you need to add additional lines in the webpack config files:

+ Normal mode (JavaScript is rendered on the client side) webpack config file:

  ```javascript
  { test: require.resolve('react-dom'), loader: 'expose?ReactDOM' },
  ```
+ Server-side rendering webpack config file:

  ```javascript
  { test: require.resolve('react-dom/server'), loader: 'expose?ReactDOMServer' },
  ```
