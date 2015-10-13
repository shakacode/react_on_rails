[![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails)
[![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master)
[![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails)
# React On Rails

**Gem Published:** https://rubygems.org/gems/react_on_rails

**Current Version:** 1.0.0.pre

**Live example, including server rendering + redux:** http://www.reactrails.com/

Sponsored by [ShakaCode.com](http://www.shakacode.com/)

See [Action Plan for v1.0](https://github.com/shakacode/react_on_rails/issues/1). We're ready v1.0!

Feedback and pull-requests encouraged! Thanks in advance! We've got a private slack channel to discuss react + webpack + rails. [Email us for an invite contact@shakacode.com](mailto: contact@shakacode.com).

Supports:

1. Rails
2. Webpack
3. React, both v0.14 and v0.13.
4. Redux
5. Turbolinks
6. Server side rendering with fragment caching
7. react-router for client side rendering (and server side very soon)

## OPEN ISSUES
1. Almost all the open issues are nice to haves like more tests.
2. If you want to work on any of the open issues, please comment on the issue. My team is mentoring anybody that's trying to help with the issues.
3. Longer term, we hope to put in many conveniences into this gem, in terms of Webpack + Rails integration. We're open to suggestions.

## Links
1. See https://github.com/shakacode/react-webpack-rails-tutorial/ for how to integrate it!
2. http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/
3. http://forum.shakacode.com
4. If you're looking for consulting on a project using React and Rails, [email us! contact@shakacode.com](mailto: contact@shakacode.com)? You can first join our slack room for some free advice.
5. We're looking for great developers that want to work with Rails + React with a distributed, worldwide team, for our own
products, client work, and open source. [More info here](http://www.shakacode.com/about/index.html#work-with-us).

## How is different than the [react-rails gem](https://github.com/reactjs/react-rails)?
1. `react_on_rails` depends on [webpack](http://webpack.github.io/). `react-rails` integrates closely with sprockets and
    helps you integrate JSX and the react code into a Rails project.
2. Likewise, using Webpack as shown in the [react-webpack-rails-tutorial](https://github.com/justin808/react-webpack-rails-tutorial/)
   does involve some extra setup. However, we feel that tight and simple integration with the node ecosystem is more than
   worth any minor setup costs.
3. `react-rails` depends on `jquery-ujs` for client side rendering. `react_on_rails` has it's own JS code that does not
   depend on jquery.

## Installation Checklist
1. Include the gems `react_on_rails` and `therubyracer` like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/361f4338ebb39a5d3934b00cb6d6fcf494773000/Gemfile#L42) and run `bundle`. Note, you can sustitute your preferable JavaScript engine.
  
  ```ruby
  gem "react_on_rails"
  gem "therubyracer"
  ```
1. Globally expose React in your webpack config like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/webpack.client.base.config.js#L31):
  
  ```javascript
    module: {
      loaders: [
        // React is necessary for the client rendering:
        {test: require.resolve('react'), loader: 'expose?React'},
    ```
1. Require `react_on_rails` in your `application.js` like  [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/361f4338ebb39a5d3934b00cb6d6fcf494773000/app/assets/javascripts/application.js#L15). It possibly should come after you require `turbolinks`:
  
  ```
  //= require react_on_rails
  ```
1. Expose your client globals like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/app/startup/clientGlobals.jsx#L3):
  
   ```javascript
   import App from './ClientApp';
   window.App = App;
   ```
1. Put your client globals file as webpack entry points like [this](https://github.com/shakacode/react-webpack-rails-tutorial/blob/537c985dc82faee333d80509343ca32a3965f9dd/client/webpack.client.rails.config.js#L22). Similar pattern for server rendering.
  
  ```javascript
  config.entry.app.push('./app/startup/clientGlobals');
  ```
1. See customization of configuration options below.  

### Additional Steps For Server Rendering (option `prerender` shown below)
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

#### Sample webpack.server.rails.config.js (ONLY for server rendering)
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

## Usage

*See section below titled "Try it out"*

### Helper Method
The main API is a helper:

```ruby
  <%= react_component(component_name, props = {}, options = {}) %>
```
  
Params are:

* **react_component_name**: [string] can be a React component, created using a ES6 class, or React.createClass,
  or a `generator function` that returns a React component
   
  using ES6
  ```javascript
  let MyReactComponentApp = (props) => <MyReactComponent {...props}/>;
  ```       
     
  or using ES5
  ```javascript
  var MyReactComponentApp = function(props) { return <YourReactComponent {...props}/>; }
  ```
  Exposing the react_component_name is necessary to both a plain ReactComponent as well as
     a generator:
   For client rendering, expose the react_component_name on window:
   
  ```javascript
  window.MyReactComponentApp = MyReactComponentApp;
  ```       
  For server rendering, export the react_component_name on global:
  ```javascript
  global.MyReactComponentApp = MyReactComponentApp;
  ```       
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

## JavaScript

1. Configure your webpack configuration to create the file used for server rendering if you plan to
   do server rendering.
2. Follow the examples in `spec/dummy/client/app/startup/clientGlobals.jsx` to expose your react components
   for client side rendering.
   ```ruby   
   import HelloWorld from '../components/HelloWorld';
   window.HelloWorld = HelloWorld;
   ```   
3. Follow the examples in `spec/dummy/client/app/startup/serverGlobals.jsx` to expose your react components
   for server side rendering.
   ```ruby
   import HelloWorld from '../components/HelloWorld';
   global.HelloWorld = HelloWorld;
   ```
   
## Server Rendering Tips

- Your code can't reference `document`. Server side JS execution does not have access to `document`, so jQuery and some
  other libs won't work in this environment. You can debug this by putting in `console.log`
  statements in your code.
- You can conditionally avoid running code that references document by passing in a boolean prop to your top level react
  component. Since the passed in props Hash from the view helper applies to client and server side code, the best way to
  do this is to use a generator function.

You might do something like this in some file for your top level component:
```javascript
global.App = () => <MyComponent serverSide={true} />;
```

The point is that you have separate files for top level client or server side, and you pass some extra option indicating that rendering is happening server sie.

## Optional Configuration   

Create a file `config/react_on_rails.rb` to override any defaults. If you don't specify this file,
the default options are below.

The `server_bundle_js_file` must correspond to the bundle you want to use for server rendering.

```ruby
# Shown below are the defaults for configuration
ReactOnRails.configure do |config|
  # Client bundles are configured in application.js
  # Server bundle is a single file for all server rendering of components.
  config.server_bundle_js_file = "app/assets/javascripts/generated/server.js" # This is the default

  # Below options can be overriden by passing to the helper method.
  config.prerender = false # default is false
  config.generator_function = false # default is false, meaning that you expose ReactComponents directly
  config.trace = Rails.env.development? # default is true for development, off otherwise

  # For server rendering. This can be set to false so that server side messages are discarded.
  config.replay_console = true # Default is true. Be cautious about turning this off.
  config.logging_on_server = true # Default is true. Logs server rendering messags to Rails.logger.info
  
  # Settings for the pool of renderers:
  config.server_renderer_pool_size  ||= 1  # ExecJS doesn't allow more than one on MRI
  config.server_renderer_timeout    ||= 20 # seconds
end
```

You can configure your pool of JS virtual machines and specify where it should load code:

- On MRI, use `therubyracer` for the best performance (see [discussion](https://github.com/reactjs/react-rails/pull/290))
- On MRI, you'll get a deadlock with `pool_size` > 1
- If you're using JRuby, you can increase `pool_size` to have real multi-threaded rendering.

# Try it out in the simple sample app
Contributions and pull requests welcome!

1. Setup and run the test app in `spec/dummy`. Note, there's no database.
  ```bash
  cd spec/dummy
  bundle
  npm i
  foreman start
  ```
3. Visit http://localhost:3000
4. Notice that the first time you hit the page, you'll see a message that server is rendering.
   See `spec/dummy/app/views/pages/index.html.erb:17` for the generation of that message.
5. Look at the layouts in `spec/dummy/app/views/pages` for samples of usage.
5. Open up the browser console and see some tracing.
6. Open up the source for the page and see the server rendered code.
7. If you want to turn on server caching for development, run the server like:
   `export RAILS_USE_CACHE=YES && foreman start`
2. If you're testing with caching, you'll need to open the console and run `Rails.cache.clear` to clear
  the cache. Note, even if you stop the server, you'll still have the cache entries around.
8. If you click back and forth between the react page links, you can see the rails console
   log as well as the browser console to see what's going on with regards to server rendering and
   caching.

# Key Tips
1. See sample app in `spec/dummy` for how to set this up. See note below on ensuring you 
   **DO NOT RUN `rails s` and instead     run `foreman start`. 
2. Test out the different options and study the JSX samples in `spec/dummy/client/app/startup`.
3. Experiment with changing the settings on the `render_component` helper calls in the ERB files.
2. The file used for server rendering is hard coded as `generated/server.js`
   (assets/javascripts/generated/server.js).
3. The default for rendering right now is `prerender: false`. **NOTE:**  Server side rendering does
   not work for some components, namely react-router, that use an async setup for server rendering.
   You can configure the default for prerender in your config.
4. You can expose either a React component or a function that returns a React component. If you 
   wish to create a React component via a function, rather than simply props, then you need to set 
   the property "generator" on that function to true. When that is done, the function is invoked 
   with a single parameter of "props", and that function should return a React element.
5. Be sure you can first render your react component client only before you try to debug server
   rendering!
4. Open up the HTML source and take a look at the generated HTML and the JavaScript to see what's
   going on under the covers. Not that when server rendering is turned on, then you'll see the
   server rendered react components. When server rendering is turned off, then you'll only see
   the `div` element where the inline JavaScript will render the component. You might also notice
   how the props you pass (a Ruby Hash) becomes inline JavaScript on the HTML page.

## JavaScript Runtime Configuration
See this [discussion on JavaScript performance](https://github.com/shakacode/react_on_rails/issues/21).
The net result is that you want to add this line to your Gemfile to get therubyracer as your default
JavaScript engine.

```ruby
gem "therubyracer"
```

## References
* [Making the helper for server side rendering work with JS created by Webpack] (https://github.com/reactjs/react-rails/issues/301#issuecomment-133098974)
* [Add Demonstration of Server Side Rendering](https://github.com/justin808/react-webpack-rails-tutorial/issues/2)
* [Charlie Marsh's article "Rendering React Components on the Server"](http://www.crmarsh.com/react-ssr/)
* [Node globals](https://nodejs.org/api/globals.html#globals_global)

### Generated JavaScript

1. See spec/dummy/spec/sample_generated_js/server-generated.js to see the JavaScript for typical server rendering.
2. See spec/dummy/spec/sample_generated_js/client-generated.js to see the JavaScript for typical client rendering.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shakacode/react_on_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

More [tips on contributing here](docs/Contributing.md)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

# Authors

[The Shaka Code team!](http://www.shakacode.com/about/)

1. [Justin Gordon](https://github.com/justin808/)
2. [Samnang Chhun](https://github.com/samnang)
3. [Alex Fedoseev](https://github.com/alexfedoseev)

And based on the work of the [react-rails gem](https://github.com/reactjs/react-rails)
