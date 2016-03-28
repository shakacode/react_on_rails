[![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails)  [![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Code Climate](https://codeclimate.com/github/shakacode/react_on_rails/badges/gpa.svg)](https://codeclimate.com/github/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master)

# NEWS
* [New slides on React on Rails](http://www.slideshare.net/justingordon/react-on-rails-v4032).
* Always see the [CHANGELOG.md](./CHANGELOG.md) for the latest project changes.
* 2016-03-17: **4.0.3** Shipped! Includes using the new Heroku buildpack steps, several smaller changes detailed in the [CHANGELOG.md](./CHANGELOG.md). 
* 2016-03-14: **4.0.0** Highlights
  * Better support for hot reloading of assets from Rails with new helpers and updates to the sample testing app, [spec/dummy](spec/dummy).
  * Better support for Turbolinks 5.
  * Controller rendering of shared redux stores and ability to render store data at bottom of HTML page.
  * See [#311](https://github.com/shakacode/react_on_rails/pull/311/files).
  * Some breaking changes! See [CHANGELOG.md](./CHANGELOG.md) for details.
* 2016-02-28: We added a [Projects page](PROJECTS.md). Please edit the page your project or [email us](mailto:contact@shakacode.com) and we'll add you. We also love stars as it helps us attract new users and contributors. [jbhatab](https://github.com/jbhatab) is leading an effort to ease the onboarding process for newbies with simpler project generators. See [#245](https://github.com/shakacode/react_on_rails/issues/245).
* *See [NEWS.md](NEWS.md) for the full news history.*

# NOTES
* React on Rails does not yet have *generator* support for building new apps that use CSS modules and hot reloading via the Rails server as is demonstrated in the [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). *We do support this, but we don't generate the code.* If you did generate a fresh app from react_on_rails and want to move to CSS Modules, then see [PR 175: Babel 6 / CSS Modules / Rails hot reloading](https://github.com/shakacode/react-webpack-rails-tutorial/pull/175). Note, while there are probably fixes after this PR was accepted, this has the majority of the changes. See [the tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/#news) for more information. For more information on how to setup hot reloading in a Rails app, see [Hot Reloading of Assets For Rails Development](docs/additional-reading/hot-reloading-rails-development.md).
* [ShakaCode](http://www.shakacode.com) is doing Skype plus Slack/Github based coaching for "React on Rails". [Click here](http://www.shakacode.com/work/index.html) for more information.
* Be sure to read our article [The React on Rails Doctrine](https://medium.com/@railsonmaui/the-react-on-rails-doctrine-3c59a778c724).

# React on Rails

**Project Objective**: To provide an opinionated and optimal framework for integrating **Ruby on Rails** with modern JavaScript tooling and libraries, including [**Webpack**](http://webpack.github.io/), [**Babel**](https://babeljs.io/), [**React**](https://facebook.github.io/react/), [**Redux**](https://github.com/reactjs/redux), [**React-Router**](https://github.com/reactjs/react-router). This differs significantly from typical Rails. When considering what goes into **react_on_rails**, we ask ourselves, is the functionality related to the intersection of using Rails and with modern JavaScript? If so, then the functionality belongs right here. In other cases, we're releasing separate npm packages or Ruby gems. If you are interested in implementing React using traditional Rails architecture, see [react-rails](https://github.com/reactjs/react-rails).

React on Rails integrates Facebook's [React](https://github.com/facebook/react) front-end framework with Rails. React v0.14.x is supported, with server rendering. [Redux](https://github.com/reactjs/redux) and [React-Router](https://github.com/reactjs/react-redux) are supported as well, also with server rendering. See the Rails on Maui [blog post](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/) that started it all!

Be sure to see:
* [React on Rails, Slides](http://www.slideshare.net/justingordon/react-on-rails-v4032)
* [The React on Rails Doctrine](https://medium.com/@railsonmaui/the-react-on-rails-doctrine-3c59a778c724)
* [React Webpack Rails Tutorial Code](https://github.com/shakacode/react-webpack-rails-tutorial) along with the live example at [www.reactrails.com](http://www.reactrails.com).
* [Projects](PROJECTS.md) using React on Rails. Please submit yours!
* On Twitter, follow [@railsonmaui](https://twitter.com/railsonmaui) and [@shakacode](https://twitter.com/shakacode) for updates on releases.

## Including your React Component in your Rails Views
Please see [Getting Started](#getting-started) for how to set up your Rails project for React on Rails to understand how `react_on_rails` can see your ReactComponents.

+ *Normal Mode (React component will be rendered on client):*

  ```erb
  <%= react_component("HelloWorldApp", props: @some_props) %>
  ```
+ *Server-Side Rendering (React component is first rendered into HTML on the server):*

  ```erb
  <%= react_component("HelloWorldApp", props: @some_props, prerender: true) %>
  ```

+ The `component_name` parameter is a string matching the name you used to globally expose your React component. So, in the above examples, if you had a React component named "HelloWorldApp," you would register it with the following lines:

  ```js
  import ReactOnRails from 'react-on-rails';
  import HelloWorldApp from './HelloWorldApp';
  ReactOnRails.register({ HelloWorldApp });
  ```

  Exposing your component in this way is how React on Rails is able to reference your component from a Rails view. You can expose as many components as you like, as long as their names do not collide. See below for the details of how you expose your components via the react_on_rails webpack configuration.

+ `@some_props` can be either a hash or JSON string. This is an optional argument assuming you do not need to pass any options (if you want to pass options, such as `prerender: true`, but you do not want to pass any properties, simply pass an empty hash `{}`). This will make the data available in your component:

  ```ruby
    # Rails View
    <%= react_component("HelloWorldApp", props: { name: "Stranger" }) %>
  ```

  ```javascript
    // inside your React component
    this.props.name // "Stranger"
  ```

## Documentation

+ [Features](#features)
+ [Why Webpack?](#why-webpack)
+ [Getting Started](#getting-started)
    - [Installation Summary](#installation-summary)
    - [Initializer Configuration: config/initializers/react_on_rails.rb](#initializer-configuration) 
+ [How it Works](#how-it-works)
    - [Client-Side Rendering vs. Server-Side Rendering](#client-side-rendering-vs-server-side-rendering)
    - [Building the Bundles](#building-the-bundles)
    - [Rails Context)(#rails-context)
    - [Globally Exposing Your React Components](#globally-exposing-your-react-components)
    - [ReactOnRails View Helpers API](#reactonrails-view-helpers-api)
    - [ReactOnRails JavaScript API](#reactonrails-javascript-api)
    - [Hot Reloading View Helpers](#hot-reloading-view-helpers)
    - [React-Router](#react-router)
+ [Generator](#generator)
    - [Understanding the Organization of the Generated Client Code](#understanding-the-organization-of-the-generated-client-code)
    - [Redux](#redux)
      - [Multiple React Components on a Page with One Store](#multiple-react-components-on-a-page-with-one-store)
    - [Using Images and Fonts](#using-images-and-fonts)
    - [Bootstrap Integration](#bootstrap-integration)
        + [Bootstrap via Rails Server](#bootstrap-via-rails-server)
        + [Bootstrap via Webpack HMR Dev Server](#bootstrap-via-webpack-hmr-dev-server)
        + [Keeping Custom Bootstrap Configurations Synced](#keeping-custom-bootstrap-configurations-synced)
        + [Skip Bootstrap Integration](#skip-bootstrap-integration)
    - [Linters](#linters)
        + [JavaScript Linters](#javascript-linters)
        + [Ruby Linters](#ruby-linters)
        + [Running the Linters](#running-the-linters)
+ [Developing with the Webpack Dev Server](#developing-with-the-webpack-dev-server)
+ [Adding Additional Routes for the Dev Server](#adding-additional-routes-for-the-dev-server)
+ [Migrate From react-rails](#migrate-from-react-rails)
+ [Additional Reading](#additional-reading)
+ [Contributing](#contributing)
+ [License](#license)
+ [Authors](#authors)
+ [About ShakaCode](#about-shakacode)

---

## Features
Like the [react-rails](https://github.com/reactjs/react-rails) gem, React on Rails is capable of server-side rendering with fragment caching and is compatible with [turbolinks](https://github.com/turbolinks/turbolinks). Unlike react-rails, which depends heavily on sprockets and jquery-ujs, React on Rails uses [webpack](http://webpack.github.io/) and does not depend on jQuery. While the initial setup is slightly more involved, it allows for advanced functionality such as:

+ [Redux](https://github.com/reactjs/redux)
+ [Webpack dev server](https://webpack.github.io/docs/webpack-dev-server.html) with [hot module replacement](https://webpack.github.io/docs/hot-module-replacement-with-webpack.html)
+ [Webpack optimization functionality](https://github.com/webpack/docs/wiki/optimization)
+ [React Router](https://github.com/reactjs/react-router)

See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.

## Why Webpack?

Webpack is used for 2 purposes:

1. Generate several JavaScript "bundles" for inclusion in `application.js`.
2. Providing the Webpack Dev Server for quick prototyping of components without needing to refresh your browser to see updates.

This usage of webpack fits neatly and simply into the existing Rails sprockets system and you can include React components on a Rails view with a simple helper.

Compare this to some alternative approaches for SPAs (Single Page Apps) that utilize Webpack and Rails. They will use a separate node server to distribute web pages, JavaScript assets, CSS, etc., and will still use Rails as an API server. A good example of this is our ShakaCode team member Alex's article [
Universal React with Rails: Part I](https://medium.com/@alexfedoseev/isomorphic-react-with-rails-part-i-440754e82a59).

We're definitely not doing that. With react_on_rails, webpack is mainly generating a nice JavaScript file for inclusion into `application.js`. We're going to KISS. And that's all relative given how much there is to get right in an enterprise class web application.

## Getting Started
1. Add the following to your Gemfile and bundle install:

  ```ruby
  gem "react_on_rails", "~> 4"
  ```

2. See help for the generator:

  ```bash
  rails generate react_on_rails:install --help
  ```

2. Run the generator with a simple "Hello World" example (more options below):

  ```bash
  rails generate react_on_rails:install
  ```

3. NPM install. Make sure you are on a recent version of node. Please use at least Node v5.

  ```bash
  npm install
  ```

4. Start your Rails server:

  ```bash
  foreman start -f Procfile.dev
  ```

5. Visit [localhost:3000/hello_world](http://localhost:3000/hello_world)

### Installation Summary

See the [Installation Overview](docs/additional-reading/installation-overview.md) for a concise set summary of what's in a React on Rails installation.

### Initializer Configuration

Configure the `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [spec/dummy/config/initializers/react_on_rails.rb](spec/dummy/config/initializers/react_on_rails.rb) for a detailed example of configuration, including comments on the different values to configure.

## NPM
All JavaScript in React On Rails is loaded from npm: [react-on-rails](https://www.npmjs.com/package/react-on-rails). To manually install this (you did not use the generator), assuming you have a standard configuration, run this command:

```
cd client && npm i --saveDev react-on-rails
```

That will install the latest version and update your package.json.

## How it Works
The generator installs your webpack files in the `client` folder. Foreman uses webpack to compile your code and output the bundled results to `app/assets/webpack`, which are then loaded by sprockets. These generated bundle files have been added to your `.gitignore` for your convenience.

Inside your Rails views, you can now use the `react_component` helper method provided by React on Rails. You can pass props directly to the react component helper. You can also initialize a Redux store with view helper `redux_store` so that the store can be shared amongst multiple React components. Your best bet is to scan the code inside of the [/spec/dummy](spec/dummy) sample app.

### Client-Side Rendering vs. Server-Side Rendering
In most cases, you should use the `prerender: false` (default behavior) with the provided helper method to render the React component from your Rails views. In some cases, such as when SEO is vital or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript using [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. We recommend using [therubyracer](https://github.com/cowboyd/therubyracer) as ExecJS's runtime. The generator will automatically add it to your Gemfile for you.

Note that **server-rendering requires globally exposing your components by setting them to `global`, not `window`** (as is the case with client-rendering). If using the generator, you can pass the `--server-rendering` option to configure your application for server-side rendering.

In the following screenshot you can see the 3 parts of React on Rails rendering:

1. A hidden HTML div that contains the properties of the React component, such as the registered name and any props. A JavaScript function runs after the page loads to convert take this data and build initialize React components.
2. The wrapper div `<div id="HelloWorld-react-component-0">` specifies the div where to place the React rendering. It encloses the server-rendered HTML for the React component
3. Additional JavaScript is placed to console log any messages, such as server rendering errors. Note, these server side logs can be configured to only be sent to the server logs.

**Note**: If server rendering is not used (prerender: false), then the major difference is that the HTML rendered for the React component only contains the outer div: `<div id="HelloWorld-react-component-0"/>`. The first specification of the React component is just the same.

![Comparison of a normal React Component with its server-rendered version](https://cloud.githubusercontent.com/assets/1118459/12607542/a959d5c8-c48a-11e5-8187-2433d543ccaa.png)

### Building the Bundles
Each time you change your client code, you will need to re-generate the bundles (the webpack-created JavaScript files included in application.js). The included Foreman `Procfile.dev` will take care of this for you by watching your JavaScript code files for changes. Simply run `foreman start -f Procfile.dev`.

On Heroku deploys, the `lib/assets.rake` file takes care of running webpack during deployment. If you have used the provided generator, these bundles will automatically be added to your `.gitignore` in order to prevent extraneous noise from re-generated code in your pull requests. You will want to do this manually if you do not use the provided generator.

### Rails Context
When you use a "generator function" to create react components or you used shared redux stores, you get 2 params passed to your function:

1. Props that you pass in the view helper of either `react_component` or `redux_store`
2. Rails contextual information, such as the current pathname. You can customize this in your config file.

This information should be the same regardless of either client or server side rendering.

While you could manually pass this information in as "props", the rails_context is a convenience because it's pass consistently to all invocations of generator functions.

So if you register your generator function `MyAppComponent`, it will get called like:

```js
reactComponent = MyAppComponent(props, railsContext);
```
and for a store:

```js
reduxStore = MyReduxStore(props, railsContext);
```

The `railsContext` has: (see implementation in file react_on_rails_helper.rb for method rails_context for the definitive list).

```ruby
  {
    # URL settings
    href: request.original_url,
    location: "#{uri.path}#{uri.query.present? ? "?#{uri.query}": ""}",
    scheme: uri.scheme, # http
    host: uri.host, # foo.com
    pathname: uri.path, # /posts
    search: uri.query, # id=30&limit=5

    # Locale settings
    i18nLocale: I18n.locale,
    i18nDefaultLocale: I18n.default_locale,
    httpAcceptLanguage: request.env["HTTP_ACCEPT_LANGUAGE"]
  }
```

#### Use Cases
##### Needing the current url path for server rendering
Suppose you want to display a nav bar with the current navigation link highlighted by the URL. When you server render the code, you will need to know the current URL/path if that is what you want your logic to be based on. This could be added to props, or ReactOnRails can add this automatically as another param to the generator function (or maybe an additional object, where we'll consider other additional bits of system info from Rails, like maybe the locale, later).

##### Needing the I18n.locale
Suppose you want to server render your react components with a the current Rails locale. We need to pass the I18n.locale to the view rendering.


#### Customization of the rails_context
You can customize the values passed in the rails_context in your `config/initializers/react_on_rails.rb`


Set the class for the `rendering_extension`:

```ruby
  config.rendering_extension = RenderingExtension
```

Implement it like this above in the same file. Create a class method on the module called `custom_context` that takes the `view_context` for a param.

```ruby
module RenderingExtension

  # Return a Hash that contains custom values from the view context that will get merged with
  # the standard rails_context values and passed to all calls to generator functions used by the
  # react_component and redux_store view helpers
  def self.custom_context(view_context)
    {
     somethingUseful: view_context.session[:something_useful]
    }
  end
end
```

In this case, a prop and value for `somethingUseful` will go into the railsContext passed to all react_component and redux_store calls.

Since you can't access the rails session from JavaScript (or other values available in the view rendering context), this might useful.

### Globally Exposing Your React Components
Place your JavaScript code inside of the provided `client/app` folder. Use modules just as you would when using webpack alone. The difference here is that instead of mounting React components directly to an element using `React.render`, you **expose your components globally and then mount them with helpers inside of your Rails views**.

+ *Normal Mode (JavaScript is Rendered on client):*

  If you are not server rendering, `clientRegistration.jsx` will have

  ```javascript
  import HelloWorld from '../components/HelloWorld';
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.register({ HelloWorld });
  ```
+ *Server-Side Rendering:*

  If you are server rendering, `serverRegistration.jsx` will have this. Note, you might be initializing HelloWorld with version specialized for server rendering.

  ```javascript
  import HelloWorld from '../components/HelloWorld';
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.register({ HelloWorld });
  ```

  In general, you may want different initialization for your server rendered components.

See below section on how to setup redux stores that allow multiple components to talk to the same store.

## ReactOnRails View Helpers API
Once the bundled files have been generated in your `app/assets/webpack` folder and you have exposed your components globally, you will want to run your code in your Rails views using the included helper method.

This is how you actually render the React components you exposed to `window` inside of `clientRegistration` (and `global` inside of `serverRegistration` if you are server rendering).

### react_component
`react_component(component_name, options = {})`

+ **component_name:** Can be a React component, created using a ES6 class, or `React.createClass`, or a generator function that returns a React component.
+ **options:**
  + **props:** Ruby Hash which contains the properties to pass to the react object, or a JSON string. If you pass a string, we'll escape it for you.
  + **prerender:** enable server-side rendering of component. Set to false when debugging!
  + **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise.
  + **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the default configuration of logging_on_server set to true, you'll still see the errors on the server.
  + **raise_on_prerender_error:** Default is false. True will throw an error on the server side rendering. Your controller will have to handle the error.
+ Any other options are passed to the content tag, including the id

### redux_store
#### Controller Extension
Include the module ReactOnRails::Controller in your controller, probably in ApplicationController. This will provide the following controller method, which you can call in your controller actions:

`redux_store(store_name, props: {})`

+ **store_name:** A name for the store. You'll refer to this name in 2 places in your JavaScript:
  1. You'll call `ReactOnRails.registerStore({storeName})` in the same place that you register your components.
  2. In your component definition, you'll call `ReactOnRails.getStore('storeName')` to get the hydrated Redux store to attach to your components.
+ **props:**  Named parameter `props`. ReactOnRails takes care of setting up the hydration of your store with props from the view.

For an example, see [spec/dummy/app/controllers/pages_controller.rb](spec/dummy/app/controllers/pages_controller.rb).

#### View Helper
`redux_store_hydration_data`

Place this view helper (no parameters) at the end of your shared layout. This tell ReactOnRails where to client render the redux store hydration data. Since we're going to be setting up the stores in the controllers, we need to know where on the view to put the client side rendering of this hydration data, which is a hidden div with a matching class that contains a data props. For an example, see [spec/dummy/app/views/layouts/application.html.erb](spec/dummy/app/views/layouts/application.html.erb).

#### Redux Store Notes
Note, you don't need to separately initialize your redux store. However, it's recommended for the two following use cases:

1. You want to have multiple components that access the same store.
2. You want to place the props to hydrate the client side stores at the very end of your HTML, so the browser can render all earlier HTML first. This is particularly useful if your props will be large.

### Generator Functions
Why would you create a function that returns a React component? For example, you may want the ability to use the passed-in props to initialize a redux store or setup react-router. Or you may want to return different components depending on what's in the props. ReactOnRails will automatically detect a registered generator function.

### server_render_js
`server_render_js(js_expression, options = {})`

+ js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught and console messages handled properly
+ Currently the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.

## ReactOnRails JavaScript API
The best source of docs is the main [ReactOnRails.js](node_package/src/ReactOnRails.js) file. Here's a quick summary. No guarantees that this won't be outdated!

```js
  /**
   * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
   * find you components for rendering.
   * @param components (key is component name, value is component)
   */
  register(components)

  /**
   * Allows registration of store generators to be used by multiple react components on one Rails
   * view. store generators are functions that take one arg, props, and return a store. Note that
   * the setStore API is different in tha it's the actual store hydrated with props.
   * @param stores (key is store name, value is the store generator)
   */
  registerStore(stores)

  /**
   * Allows retrieval of the store by name. This store will be hydrated by any Rails form props. 
   * Pass optional param throwIfMissing = false if you want to use this call to get back null if the
   * store with name is not registered.
   * @param name
   * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if 
   *        there is no store with the given name.
   * @returns Redux Store, possibly hydrated
   */
  getStore(name, throwIfMissing = true )

  /**
   * Set options for ReactOnRails, typically before you call ReactOnRails.register
   * Available Options:
   * `traceTurbolinks: true|false Gives you debugging messages on Turbolinks events
   */
  setOptions(options)
```

## Hot Reloading View Helpers
The `env_javascript_include_tag` and `env_stylesheet_link_tag` support the usage of a webpack dev server for providing the JS and CSS assets during development mode. See the [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/) for a working example.

The key options are `static` and `hot` which specify what you want for static vs. hot. Both of these params are optional, and support either a single value, or an array.

static vs. hot is picked based on whether ENV["REACT_ON_RAILS_ENV"] == "HOT"

```erb
 <%= env_stylesheet_link_tag(static: 'application_static',
                             hot: 'application_non_webpack',
                             media: 'all',
                             'data-turbolinks-track' => true)  %>

 <!-- These do not use turbolinks, so no data-turbolinks-track -->
 <!-- This is to load the hot assets. -->
 <%= env_javascript_include_tag(hot: ['http://localhost:3500/vendor-bundle.js',
                                      'http://localhost:3500/app-bundle.js']) %>

 <!-- These do use turbolinks -->
 <%= env_javascript_include_tag(static: 'application_static',
                                hot: 'application_non_webpack',
                                'data-turbolinks-track' => true) %>
```
                                
See application.html.erb for usage example and [application.html.erb](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/app%2Fviews%2Flayouts%2Fapplication.html.erb)

**env_javascript_include_tag(args = {})**

Helper to set CSS assets depending on if we want static or "hot", which means from the Webpack dev server.

In this example, application_non_webpack is simply a CSS asset pipeline file which includes styles not placed in the webpack build.

We don't need styles from the webpack build, as those will come via the JavaScript include tags.

The key options are `static` and `hot` which specify what you want for static vs. hot. Both of
these params are optional, and support either a single value, or an array.

```erb
 <%= env_stylesheet_link_tag(static: 'application_static',
                             hot: 'application_non_webpack',
                             media: 'all',
                             'data-turbolinks-track' => true)  %>
```

**env_stylesheet_link_tag(args = {})**

## Generator
The `react_on_rails:install` generator combined with the example pull requests of generator runs will get you up and running efficiently. There's a fair bit of setup with integrating Webpack with Rails. Defaults for options are such that the default is for the flag to be off. For example, the default for `-R` is that `redux` is off, and the default of `-b` is that `skip-bootstrap` is off.

Run `rails generate react_on_rails:install --help` for descriptions of all available options:

```
Usage:
  rails generate react_on_rails:install [options]

Options:
  -R, [--redux], [--no-redux]                          # Install Redux gems and Redux version of Hello World Example
  -S, [--server-rendering], [--no-server-rendering]    # Add necessary files and configurations for server-side rendering
  -j, [--skip-js-linters], [--no-skip-js-linters]      # Skip installing JavaScript linting files
  -L, [--ruby-linters], [--no-ruby-linters]            # Install ruby linting files, tasks, and configs
  -H, [--heroku-deployment], [--no-heroku-deployment]  # Install files necessary for deploying to Heroku
  -b, [--skip-bootstrap], [--no-skip-bootstrap]        # Skip installing files for bootstrap support

Runtime options:
  -f, [--force]                    # Overwrite files that already exist
  -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  -q, [--quiet], [--no-quiet]      # Suppress status output
  -s, [--skip], [--no-skip]        # Skip files that already exist

Description:
    Create react on rails files for install generator.
```

For a clear example of what each generator option will do, see our generator results repo: [Generator Results](https://github.com/shakacode/react_on_rails-generator-results/blob/master/README.md). Each pull request shows a git "diff" that highlights the changes that the generator has made. Another good option is to create a simple test app per the [Tutorial](docs/tutorial.md).

### Understanding the Organization of the Generated Client Code
The generated client code follows our organization scheme. Each unique set of functionality, is given its own folder inside of `client/app/bundles`. This encourages for modularity of *domains*.

Inside of the generated "HelloWorld" domain you will find the following folders:

+  `startup`: two types of files, one that return a container component and implement any code that differs between client and server code (if using server-rendering), and a `clientRegistration` file that exposes the aforementioned files (as well as a `serverRegistration` file if using server rendering). These registration files are what webpack is using as an entry point.
+ `containers`: "smart components" (components that have functionality and logic that is passed to child "dumb components").
+ `components`: includes "dumb components", or components that simply render their properties and call functions given to them as properties by a parent component. Ultimately, at least one of these dumb components will have a parent container component.

You may also notice the `app/lib` folder. This is for any code that is common between bundles and therefore needs to be shared (for example, middleware).

### Redux
If you have used the `--redux` generator option, you will notice the familiar additional redux folders in addition to the aforementioned folders. The Hello World example has also been modified to use Redux.

Note the organizational paradigm of "bundles". These are like application domains and are used for grouping your code into webpack bundles, in case you decide to create different bundles for deployment. This is also useful for separating out logical parts of your application. The concept is that each bundle will have it's own Redux store. If you have code that you want to reuse across bundles, including components and reducers, place them under `/client/app/lib`.

### Using Images and Fonts
The generator has amended the folders created in `client/assets/` to Rails's asset path. We recommend that if you have any existing assets that you want to use with your client code, you should move them to these folders and use webpack as normal. This allows webpack's development server to have access to your assets, as it will not be able to see any assets in the default Rails directories which are above the `/client` directory.

Alternatively, if you have many existing assets and don't wish to move them, you could consider creating symlinks from client/assets that point to your Rails assets folders inside of `app/assets/`. The assets there will then be visible to both Rails and webpack.

### Bootstrap Integration
React on Rails ships with Twitter Bootstrap already integrated into the build. Note that the generator removes `require_tree` in both the application.js and application.css.scss files. This is to ensure the correct load order for the bootstrap integration, and is usually a good idea in general. You will therefore need to explicitly require your files.

How the Bootstrap library is loaded depends upon whether one is using the Rails server or the HMR development server.

#### Bootstrap via Rails Server
In the former case, the Rails server loads `bootstrap-sprockets`, provided by the `bootstrap-sass` ruby gem (added automatically to your Gemfile by the generator) via the `app/assets/stylesheets/_bootstrap-custom.scss` partial.

This allows for using Bootstrap in your regular Rails stylesheets. If you wish to customize any of the Bootstrap variables, you can do so via the `client/assets/stylesheets/_pre-bootstrap.scss` partial.

#### Bootstrap via Webpack HMR Dev Server
When using the webpack dev server, which does not go through Rails, bootstrap is loaded via the [bootstrap-sass-loader](https://github.com/shakacode/bootstrap-sass-loader) which uses the `client/bootstrap-sass-config.js` file.

#### Keeping Custom Bootstrap Configurations Synced
Because the webpack dev server and Rails each load Bootstrap via a different file (explained in the two sections immediately above), any changes to the way components are loaded in one file must also be made to the other file in order to keep styling consistent between the two. For example, if an import is excluded in `_bootstrap-custom.scss`, the same import should be excluded in `bootstrap-sass-config.js` so that styling in the Rails server and the webpack dev server will be the same.

#### Skip Bootstrap Integration
Bootstrap integration is enabled by default, but can be disabled by passing the `--skip-bootstrap` flag (alias `-b`). When you don't need Bootstrap in your existing project, just skip it as needed.

### Linters
The React on Rails generator can add linters and their recommended accompanying configurations to your project. There are two classes of linters: ruby linters and JavaScript linters.

##### JavaScript Linters
JavaScript linters are **enabled by default**, but can be disabled by passing the `--skip-js-linters` flag (alias `j`) , and those that run in Node have been added to `client/package.json` under `devDependencies`.

##### Ruby Linters
Ruby linters are **disabled by default**, but can be enabled by passing the `--ruby-linters` flag when generating. These linters have been added to your Gemfile in addition to the appropriate Rake tasks.

We really love using all the linters! Give them a try.

#### Running the Linters
To run the linters (runs all linters you have installed, even if you installed both Ruby and Node):

```bash
rake lint
```

Run this command to see all the linters available

```bash
rake -T lint
```

**Here's the list:**
```bash
rake lint               # Runs all linters
rake lint:eslint        # eslint
rake lint:js            # JS Linting
rake lint:jscs          # jscs
rake lint:rubocop[fix]  # Run Rubocop lint in shell
rake lint:ruby          # Run ruby-lint as shell
rake lint:scss          # See docs for task 'scss_lint'
```

## Multiple React Components on a Page with One Store
You may wish to have 2 React components share the same the Redux store. For example, if your navbar is a React component, you may want it to use the same store as your component in the main area of the page. You may even want multiple React components in the main area, which allows for greater modularity. In addition, you may want this to work with Turbolinks to minimize reloading the JavaScript. A good example of this would be something like an a notifications counter in a header. As each notifications is read in the body of the page, you would like to update the header. If both the header and body share the same Redux store, then this is trivial. Otherwise, we have to rely on other solutions, such as the header polling the server to see how many unread notifications exist.

Suppose the Redux store is called `appStore`, and you have 3 React components that each need to connect to a store: `NavbarApp`, `CommentsApp`, and `BlogsApp`. I named them with `App` to indicate that they are the registered components.

You will need to make a function that can create the store you will be using for all components and register it via the `registerStore` method. Note, this is a **storeCreator**, meaning that it is a function that takes (props, location) and returns a store:

```
function appStore(props, railsContext) {
  // Create a hydrated redux store, using props and the railsContext (object with 
  // Rails contextual information).
  return myAppStore;
}

ReactOnRails.registerStore({
  appStore
});
```

When registering your component with React on Rails, you can get the store via `ReactOnRails.getStore`:

```js
// getStore will initialize the store if not already initialized, so creates or retrieves store
const appStore = ReactOnRails.getStore("appStore");
return (
  <Provider store={appStore}>
    <CommentsApp />
  </Provider>
);
```

From your Rails view, you can use the provided helper `redux_store(store_name, props)` to create a fresh version of the store (because it may already exist if you came from visiting a previous page). Note, for this example, since we're initializing this from the main layout, we're using a generic name of `@react_props`. This means in this case that Rails controllers would set `@react_props` to the properties to hydrate the Redux store.

**app/views/layouts/application.html.erb**
```erb
...
<%= redux_store("appStore", props: @react_props) %>;
<%= react_component("NavbarApp") %>
yield
...
```

Components are created as [stateless function(al) components](https://facebook.github.io/react/docs/reusable-components.html#stateless-functions). Since you can pass in initial props via the helper `redux_store`, you do not need to pass any props directly to the component. Instead, the component hydrates by connecting to the store.

**_comments.html.erb**
```erb
<%= react_component("CommentsApp") %>
```

**_blogs.html.erb**
```erb
<%= react_component("BlogsApp") %>
```

*Note:* You will not be doing any partial updates to the Redux store when loading a new page. When the page content loads, React on Rails will rehydrate a new version of the store with whatever props are placed on the page.

## React Router
[React Router](https://github.com/reactjs/react-router) is supported, including server side rendering! See:
  
1. [React on Rails docs for react-router](docs/additional-reading/react-router.md)
1. Examples in [spec/dummy/app/views/react_router](spec/dummy/app/views/react_router) and follow to the JavaScript code in the [spec/dummy/client/app/startup/ServerRouterApp.jsx](spec/dummy/client/app/startup/ServerRouterApp.jsx). 

## Developing with the Webpack Dev Server
One of the benefits of using webpack is access to [webpack's dev server](https://webpack.github.io/docs/webpack-dev-server.html) and its [hot module replacement](https://webpack.github.io/docs/hot-module-replacement-with-webpack.html) functionality.

The webpack dev server with HMR will apply changes from the code (or styles!) to the browser as soon as you save whatever file you're working on. You won't need to reload the page, and your data will still be there. Start foreman as normal (it boots up the Rails server *and* the webpack HMR dev server at the same time).

  ```bash
  foreman start -f Procfile.dev
  ```

Open your browser to [localhost:3000](http://localhost:3000). Whenever you make changes to your JavaScript code in the `client` folder, they will automatically show up in the browser. Hot module replacement is already enabled by default.

Note that **React-related error messages are typically significantly more helpful when encountered in the dev server** than the Rails server as they do not include noise added by the React on Rails gem.

### Adding Additional Routes for the Dev Server
As you add more routes to your front-end application, you will need to make the corresponding API for the dev server in `client/server.js`. See our example `server.js` from our [tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client%2Fserver-express.js).

## Migrate From react-rails
If you are using [react-rails](https://github.com/reactjs/react-rails) in your project, it is pretty simple to migrate to [react_on_rails](https://github.com/shakacode/react_on_rails).

- Remove the 'react-rails' gem from your Gemfile.

- Remove the generated lines for react-rails in your application.js file.

```
//= require react
//= require react_ujs
//= require components
```

- Follow our getting started guide: https://github.com/shakacode/react_on_rails#getting-started.

Note: If you have components from react-rails you want to use, then you will need to port them into react_on_rails which uses webpack instead of the asset pipeline.

## Additional Reading
+ [React on Rails, Slides](http://www.slideshare.net/justingordon/react-on-rails-v4032)
+ [The React on Rails Doctrine](https://medium.com/@railsonmaui/the-react-on-rails-doctrine-3c59a778c724)
+ [Installation Overview](docs/additional-reading/installation-overview.md) 
+ [Babel](docs/additional-reading/babel.md)
+ [Heroku Deployment](docs/additional-reading/heroku-deployment.md)
+ [Manual Installation](docs/additional-reading/manual-installation.md)
+ [Hot Reloading of Assets For Rails Development](docs/additional-reading/hot-reloading-rails-development.md)
+ [Node Dependencies and NPM](docs/additional-reading/node-dependencies-and-npm.md)
+ [React Router](docs/additional-reading/react-router.md)
+ [RSpec Configuration](docs/additional-reading/rspec_configuration.md)
+ [Server Rendering Tips](docs/additional-reading/server_rendering_tips.md)
+ [Rails View Rendering from Inline JavaScript](docs/additional-reading/rails_view_rendering_from_inline_javascript.md)
+ [Tips](docs/additional-reading/tips.md)
+ [Tutorial for v2.0](docs/tutorial-v2.md), deployed [here](https://shakacode-react-on-rails.herokuapp.com/).
+ [Turbolinks](docs/additional-reading/turbolinks.md)
+ [Webpack Configuration](docs/additional-reading/webpack.md)
+ [Webpack Cookbook](https://christianalfoni.github.io/react-webpack-cookbook/index.html)
+ [Changelog](CHANGELOG.md)
+ [Projects](PROJECTS.md)

## Demos
+ [www.reactrails.com](http://www.reactrails.com) with the source at [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/).
+ [spec app](spec/dummy): Great simple examples used for our tests.
  ```
  cd spec/dummy
  bundle && npm i
  foreman start
  ```

## Dependencies
+ Ruby 2.1 or greater
+ Rails 3.2 or greater
+ Node 5.5 or great

## Contributing
Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to our version of the [Contributor Covenant Code of Conduct](docs/code_of_conduct.md)).

See [Contributing](docs/contributor-info/contributing.md) to get started.

## License
The gem is available as open source under the terms of the [MIT License](docs/LICENSE).

## Authors
[The Shaka Code team!](http://www.shakacode.com/about/)

The origins of the project began with the need to do a rich JavaScript interface for ShakaCode's client [Madrone](http://madroneco.com/) and the choice to use Webapck and Rails, as described in [Fast Rich Client Rails Development With Webpack and the ES6 Transpiler](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/).

The gem project started with [Justin Gordon](https://github.com/justin808/) pairing with [Samnang Chhun](https://github.com/samnang) to figure out how to do server rendering with Webpack plus Rails. [Alex Fedoseev](https://github.com/alexfedoseev) then joined in. [Rob Wise](https://github.com/robwise), [Aaron Van Bokhoven](https://github.com/aaronvb), and [Andy Wang](https://github.com/yorzi) did the bulk of the generators. Many others have [contributed](https://github.com/shakacode/react_on_rails/graphs/contributors).

We owe much gratitude to the work of the [react-rails gem](https://github.com/reactjs/react-rails). We've also been inspired by the [react_webpack_rails gem](https://github.com/netguru/react_webpack_rails).


## About [ShakaCode](http://www.shakacode.com/)

Visit [our forums!](http://forum.shakacode.com). We've got a [category dedicated to react_on_rails](http://forum.shakacode.com/c/rails/reactonrails).

If you're looking for consulting on a project using React and Rails, email us ([contact@shakacode.com](mailto: contact@shakacode.com))! You can also join our slack room for some free advice.

We're looking for great developers that want to work with Rails + React with a distributed, worldwide team, for our own products, client work, and open source. [More info here](http://www.shakacode.com/about/index.html#work-with-us).
