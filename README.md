[![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails)  [![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails) [![Code Climate](https://codeclimate.com/github/shakacode/react_on_rails/badges/gpa.svg)](https://codeclimate.com/github/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master)

**For a complete example of this gem, see our live demo at [www.reactrails.com](http://www.reactrails.com). ([Source Code](https://github.com/shakacode/react-webpack-rails-tutorial))**

Aloha from Justin Gordon ([bio](http://www.railsonmaui.com/about)) and the [ShakaCode](http://www.shakacode.com) Team! We're actively looking for new projects. If you like **React on Rails**, please consider contacting me at [justin@shakacode.com](mailto:justin@shakacode.com) if we could potentially help you in any way. Besides consulting on bigger projects, [ShakaCode](http://www.shakacode.com) is doing Skype plus Slack/Github based coaching for React on Rails. [Click here](http://www.shakacode.com/work/index.html) for more information.

We're offering a free half-hour project consultation, on anything from React on Rails to any aspect of web application development for both consumer and enterprise products. In addition to React.js and Rails, we're doing react-native iOS and Android apps!

Whether you have a new project or need help on an existing project, feel free to contact me directly at [justin@shakacode.com](mailto:justin@shakacode.com) and thanks in advance for any referrals!

Your support keeps this project going.

(Want to become a contributor? [Contact us](mailto:contact@shakacode.com) for an Slack team invite! Also, see ["easy" issues](https://github.com/shakacode/react_on_rails/labels/easy) and [issues for the full tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/issues?q=is%3Aissue+is%3Aopen+label%3Aeasy).)

# NEWS
* 2016-08-27: We now have a [Documentation Gitbook](https://shakacode.gitbooks.io/react-on-rails/content/) for improved readability & reference.
* 2016-08-21: v6.1 ships with serveral new features and bug fixes. See the [Changelog](CHANGELOG.md).
* 2016-07-28: If you're doing server rendering, be sure to use mini\_racer! See [issues/428](https://github.com/shakacode/react_on_rails/issues/428). It's supposedly much faster than `therubyracer`.
* *See [NEWS.md](NEWS.md) for more notes over time.*

# React on Rails

**Project Objective**: To provide an opinionated and optimal framework for integrating Ruby on Rails with modern JavaScript tooling and libraries, including [**Webpack**](http://webpack.github.io/), [**Babel**](https://babeljs.io/), [**React**](https://facebook.github.io/react/), [**Redux**](https://github.com/reactjs/redux), [**React-Router**](https://github.com/reactjs/react-router). This differs significantly from typical Rails architecture. When considering what goes into **react_on_rails**, we ask ourselves, is the functionality related to the intersection of using Rails and modern JavaScript? If so, then the functionality belongs right here. In other cases, we're releasing separate npm packages or Ruby gems. If you are interested in implementing React using traditional Rails architecture, see [react-rails](https://github.com/reactjs/react-rails).

React on Rails integrates Facebook's [React](https://github.com/facebook/react) front-end framework with Rails. React v0.14.x and greater is supported, with server rendering. [Redux](https://github.com/reactjs/redux) and [React-Router](https://github.com/reactjs/react-redux) are supported as well, also with server rendering, using either **execJS** or a [Node.js server](https://github.com/shakacode/react_on_rails/blob/master/docs%2Fadditional-reading%2Fnode-server-rendering.md). See the Rails on Maui [blog post](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/) that started it all!

## Table of Contents

+ [Features](#features)
+ [Why Webpack?](#why-webpack)
+ [Getting Started](#getting-started)
    - [Installation Summary](#installation-summary)
    - [Initializer Configuration: config/initializers/react_on_rails.rb](#initializer-configuration)
    - [Including your React Component in your Rails Views](#including-your-react-component-in-your-rails-views)
+ [How it Works](#how-it-works)
    - [Client-Side Rendering vs. Server-Side Rendering](#client-side-rendering-vs-server-side-rendering)
    - [Building the Bundles](#building-the-bundles)
    - [Rails Context](#rails-context)
    - [Globally Exposing Your React Components](#globally-exposing-your-react-components)
    - [ReactOnRails View Helpers API](#reactonrails-view-helpers-api)
    - [ReactOnRails JavaScript API](#reactonrails-javascript-api)
    - [React-Router](#react-router)
    - [Deployment](#deployment)
+ [Integration with Node](#integration-with-node)
+ [Additional Documentation](#additional-documentation)
+ [Contributing](#contributing)
+ [License](#license)
+ [Authors](#authors)
+ [About ShakaCode](#about-shakacode)

---

## Features
Like the [react-rails](https://github.com/reactjs/react-rails) gem, React on Rails is capable of server-side rendering with fragment caching and is compatible with [turbolinks](https://github.com/turbolinks/turbolinks). Unlike react-rails, which depends heavily on sprockets and jquery-ujs, React on Rails uses [webpack](http://webpack.github.io/) and does not depend on jQuery. While the initial setup is slightly more involved, it allows for advanced functionality such as:

+ [Redux](https://github.com/reactjs/redux)
+ [Webpack optimization functionality](https://github.com/webpack/docs/wiki/optimization)
+ [React Router](https://github.com/reactjs/react-router)

See the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) for an example of a live implementation and code.

## Why Webpack?

Webpack is used to generate several JavaScript "bundles" for inclusion in `application.js` or directly in your layout.

This usage of webpack fits neatly and simply into the existing Rails sprockets system and you can include React components on a Rails view with a simple helper.

Compare this to some alternative approaches for SPAs (Single Page Apps) that utilize Webpack and Rails. They will use a separate node server to distribute web pages, JavaScript assets, CSS, etc., and will still use Rails as an API server. A good example of this is our ShakaCode team member Alex's article [
Universal React with Rails: Part I](https://medium.com/@alexfedoseev/isomorphic-react-with-rails-part-i-440754e82a59).

We're definitely not doing that. With react_on_rails, webpack is mainly generating a nice JavaScript file for inclusion into `application.js`. We're going to KISS. And that's all relative given how much there is to get right in an enterprise class web application.

## Getting Started

**For more detailed instructions**, see the [React on Rails Basic Tutorial](docs/tutorial.md).
1. Add the following to your Gemfile and bundle install.

  ```ruby
  gem "react_on_rails", "~> 6"
  ```

2. Commit this to git (you cannot run the generator unless you do this).

3. See help for the generator:

  ```bash
  rails generate react_on_rails:install --help
  ```

4. Run the generator with a simple "Hello World" example (more options below):

  ```bash
  rails generate react_on_rails:install
  ```

5. Bundle and NPM install. Make sure you are on a recent version of node. Please use at least Node v5. Bundle is for adding execJs. You can remove that if you are sure you will not server render.

  ```bash
  bundle && npm install
  ```

6. Start your Rails server:

  ```bash
  foreman start -f Procfile.dev
  ```

7. Visit [localhost:3000/hello_world](http://localhost:3000/hello_world)

### Installation Summary

See the [Installation Overview](docs/basics/installation-overview.md) for a concise set summary of what's in a React on Rails installation.

### Initializer Configuration

Configure the `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [spec/dummy/config/initializers/react_on_rails.rb](spec/dummy/config/initializers/react_on_rails.rb) for a detailed example of configuration, including comments on the different values to configure.

### Including your React Component in your Rails Views

+ *Normal Mode (React component will be rendered on client):*

  ```erb
  <%= react_component("HelloWorldApp", props: @some_props) %>
  ```
+ *Server-Side Rendering (React component is first rendered into HTML on the server):*

  ```erb
  <%= react_component("HelloWorldApp", props: @some_props, prerender: true) %>
  ```

+ The `component_name` parameter is a string matching the name you used to expose your React component globally. So, in the above examples, if you had a React component named "HelloWorldApp," you would register it with the following lines:

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
  
## NPM
All JavaScript in React On Rails is loaded from npm: [react-on-rails](https://www.npmjs.com/package/react-on-rails). To manually install this (you did not use the generator), assuming you have a standard configuration, run this command:

```
cd client && npm i --saveDev react-on-rails
```

That will install the latest version and update your package.json.

## How it Works
The generator installs your webpack files in the `client` folder. Foreman uses webpack to compile your code and output the bundled results to `app/assets/webpack`, which are then loaded by sprockets. These generated bundle files have been added to your `.gitignore` for your convenience.

Inside your Rails views, you can now use the `react_component` helper method provided by React on Rails. You can pass props directly to the react component helper. You can also initialize a Redux store with view or controller helper `redux_store` so that the store can be shared amongst multiple React components. See the docs for `redux_store` below and scan the code inside of the [/spec/dummy](spec/dummy) sample app.

### Client-Side Rendering vs. Server-Side Rendering
In most cases, you should use the `prerender: false` (default behavior) with the provided helper method to render the React component from your Rails views. In some cases, such as when SEO is vital, or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript using [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. We recommend using [mini_racer](https://github.com/discourse/mini_racer) as ExecJS's runtime. The generator will automatically add it to your Gemfile for you (once we complete [#501](https://github.com/shakacode/react_on_rails/issues/501)).

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

This information (`props` and `railsContext`) should be the same regardless of either client or server side rendering.

While you could manually pass the `railsContext` information in as "props", the `rails_context` is a convenience because it's passed consistently to all invocations of generator functions.

So if you register your generator function `MyAppComponent`, it will get called like:

```js
reactComponent = MyAppComponent(props, railsContext);
```
and for a store:

```js
reduxStore = MyReduxStore(props, railsContext);
```

Note, you never make these calls. This is what React on Rails does when either server or client rendering. You'll be defining functions that take these params and return a React component or a Redux Store.

(Note, see below [section](#multiple-react-components-on-a-page-with-one-store) on how to setup redux stores that allow multiple components to talk to the same store.)

The `railsContext` has: (see implementation in file [react_on_rails_helper.rb](app/helpers/react_on_rails_helper.rb), method `rails_context` for the definitive list).

```ruby
  {
    # URL settings
    href: request.original_url,
    location: "#{uri.path}#{uri.query.present? ? "?#{uri.query}": ""}",
    scheme: uri.scheme, # http
    host: uri.host, # foo.com
    port: uri.port,
    pathname: uri.path, # /posts
    search: uri.query, # id=30&limit=5

    # Locale settings
    i18nLocale: I18n.locale,
    i18nDefaultLocale: I18n.default_locale,
    httpAcceptLanguage: request.env["HTTP_ACCEPT_LANGUAGE"],

    # Other
    serverSide: boolean # Are we being called on the server or client? NOTE, if you conditionally
     # render something different on the server than the client, then React will only show the
     # server version!
  }
```

#### Use Cases
##### Needing the current url path for server rendering
Suppose you want to display a nav bar with the current navigation link highlighted by the URL. When you server render the code, you will need to know the current URL/path if that is what you want your logic to be based on. The new `railsContext` has this information so the application of an "active" class can be done server side.

##### Needing the I18n.locale
Suppose you want to server render your react components with localization applied given the current Rails locale. The `railsContext` contains the I18n.locale.

##### Configuring different code for server side rendering
Suppose you want to turn off animation when doing server side rendering. The `serverSide` value is just what you need.

#### Customization of the rails_context
You can customize the values passed in the `railsContext` in your `config/initializers/react_on_rails.rb`. Here's how.

Set the config value for the `rendering_extension`:

```ruby
  config.rendering_extension = RenderingExtension
```

Implement it like this above in the same file. Create a class method on the module called `custom_context` that takes the `view_context` for a param.

See [spec/dummy/config/initializers/react_on_rails.rb](spec/dummy/config/initializers/react_on_rails.rb) for a detailed example.

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

In this case, a prop and value for `somethingUseful` will go into the railsContext passed to all react_component and redux_store calls. You may set any values available in the view rendering context.

### Globally Exposing Your React Components
Place your JavaScript code inside of the provided `client/app` folder. Use modules just as you would when using webpack alone. The difference here is that instead of mounting React components directly to an element using `React.render`, you **expose your components globally and then mount them with helpers inside of your Rails views**.

This is an example of how to expose a component to the `react_component` view helper.

  ```javascript
  // client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx
  import HelloWorld from '../components/HelloWorld';
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.register({ HelloWorld });
  ```

#### Different Server-Side Rendering Code (and a Server Specific Bundle)

You may want different initialization for your server rendered components. For example, if you have animation that runs when a component is displayed, you might need to turn that off when server rendering. However, the `railsContext` will tell you if your JavaScript code is running client side or server side. So code that required a different server bundle previously may no longer require this!

If you do want different code to run, you'd setup a separate webpack compilation file and you'd specify a different, server side entry file. ex. 'serverHelloWorldApp.jsx'. Note, you might be initializing HelloWorld with version specialized for server rendering.

## ReactOnRails View Helpers API
Once the bundled files have been generated in your `app/assets/webpack` folder and you have exposed your components globally, you will want to run your code in your Rails views using the included helper method.

This is how you actually render the React components you exposed to `window` inside of `clientRegistration` (and `global` inside of `serverRegistration` if you are server rendering).

### react_component
```ruby
react_component(component_name,
                props: {},
                prerender: nil,
                trace: nil,
                replay_console: nil,
                raise_on_prerender_error: nil,
                id: nil,
                html_options: {})
```

+ **component_name:** Can be a React component, created using a ES6 class, or `React.createClass`, or a generator function that returns a React component.
+ **options:**
  + **props:** Ruby Hash which contains the properties to pass to the react object, or a JSON string. If you pass a string, we'll escape it for you.
  + **prerender:** enable server-side rendering of component. Set to false when debugging!
  + **id:** Id for the div, will be used to attach the React component. This will get assigned automatically if you do not provide an id. Must be unique.
  + **html_options:** Any other html options to get placed on the added div for the component. For example, you can set a class (or inline style) on the outer div so that it behaves like a span, with styling of `display:inline-block`.
  + **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise. Note, on the client you will so both the railsContext and your props. On the server, you only see the railsContext being logged.
  + **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the default configuration of logging_on_server set to true, you'll still see the errors on the server.
  + **raise_on_prerender_error:** Default is false. True will throw an error on the server side rendering. Your controller will have to handle the error.

### redux_store
#### Controller Extension
Include the module ReactOnRails::Controller in your controller, probably in ApplicationController. This will provide the following controller method, which you can call in your controller actions:

`redux_store(store_name, props: {})`

+ **store_name:** A name for the store. You'll refer to this name in 2 places in your JavaScript:
  1. You'll call `ReactOnRails.registerStore({storeName})` in the same place that you register your components.
  2. In your component definition, you'll call `ReactOnRails.getStore('storeName')` to get the hydrated Redux store to attach to your components.
+ **props:**  Named parameter `props`. ReactOnRails takes care of setting up the hydration of your store with props from the view.

For an example, see [spec/dummy/app/controllers/pages_controller.rb](spec/dummy/app/controllers/pages_controller.rb). Note, this is preferable to using the equivalent view_helper `redux_store` in that you can be assured that the store is initialized before your components.

#### View Helper
`redux_store(store_name, props: {})`

Same API as the controller extension. **HOWEVER**, we recommend the controller extension instead because the Rails executes the template code in the controller action's view file (`erb`, `haml`, `slim`, etc.) before the layout. So long as you call `redux_store` at the beginning of your action's view file, this will work. However, it's an easy mistake to put this call in the wrong place. Calling `redux_store` in the controller action ensures proper load order, regardless of where you call this in the controller action. Note, you won't know of this subtle ordering issue until you server render and you find that your store is not hydrated properly.

`redux_store_hydration_data`

Place this view helper (no parameters) at the end of your shared layout. This tell ReactOnRails where to client render the redux store hydration data. Since we're going to be setting up the stores in the controllers, we need to know where on the view to put the client side rendering of this hydration data, which is a hidden div with a matching class that contains a data props. For an example, see [spec/dummy/app/views/layouts/application.html.erb](spec/dummy/app/views/layouts/application.html.erb).

#### Redux Store Notes
Note, you don't need to separately initialize your redux store. However, it's recommended for the two following use cases:

1. You want to have multiple components that access the same store.
2. You want to place the props to hydrate the client side stores at the very end of your HTML so that the browser can render all earlier HTML first. This is particularly useful if your props will be large.

### Generator Functions
Why would you create a function that returns a React component? For example, you may want the ability to use the passed-in props to initialize a redux store or setup react-router. Or you may want to return different components depending on what's in the props. ReactOnRails will automatically detect a registered generator function.

### server_render_js
`server_render_js(js_expression, options = {})`

+ js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught and console messages handled properly
+ Currently, the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.

## Multiple React Components on a Page with One Store
You may wish to have 2 React components share the same the Redux store. For example, if your navbar is a React component, you may want it to use the same store as your component in the main area of the page. You may even want multiple React components in the main area, which allows for greater modularity. In addition, you may want this to work with Turbolinks to minimize reloading the JavaScript. A good example of this would be something like a notifications counter in a header. As each notification is read in the body of the page, you would like to update the header. If both the header and body share the same Redux store, then this is trivial. Otherwise, we have to rely on other solutions, such as the header polling the server to see how many unread notifications exist.

Suppose the Redux store is called `appStore`, and you have 3 React components that each needs to connect to a store: `NavbarApp`, `CommentsApp`, and `BlogsApp`. I named them with `App` to indicate that they are the registered components.

You will need to make a function that can create the store you will be using for all components and register it via the `registerStore` method. Note, this is a **storeCreator**, meaning that it is a function that takes (props, location) and returns a store:

```js
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

## ReactOnRails JavaScript API
See [ReactOnRails JavaScript API](docs/api/javascript-api.md).

#### Using Rails built-in CSRF protection in JavaScript

Rails has built-in protection for Cross-Site Request Forgery (CSRF), see [Rails Documentation](http://guides.rubyonrails.org/security.html#cross-site-request-forgery-csrf). To nicely utilize this feature in JavaScript requests, React on Rails is offerring two helpers that can be used as following for POST, PULL or DELETE requests:

```
import ReactOnRails from 'react-on-rails';

// reads from DOM csrf token generated by Rails in <%= csrf_meta_tags %>
csrfToken = ReactOnRails.authenticityToken();

// compose Rails specific request header as following { X-CSRF-Token: csrfToken, X-Requested-With: XMLHttpRequest }
header = ReactOnRails.authenticityHeaders(otherHeader);
```

If you are using [jquery-ujs](https://github.com/rails/jquery-ujs) for AJAX calls, than these helpers are not needed because the [jquery-ujs](https://github.com/rails/jquery-ujs) library updates header automatically, see [jquery-ujs documentation](https://robots.thoughtbot.com/a-tour-of-rails-jquery-ujs#cross-site-request-forgery-protection).

## React Router
[React Router](https://github.com/reactjs/react-router) is supported, including server side rendering! See:

1. [React on Rails docs for react-router](docs/additional-reading/react-router.md)
1. Examples in [spec/dummy/app/views/react_router](spec/dummy/app/views/react_router) and follow to the JavaScript code in the [spec/dummy/client/app/startup/ServerRouterApp.jsx](spec/dummy/client/app/startup/ServerRouterApp.jsx).

## Deployment
* Version 6.0 puts the necessary precompile steps automatically in the rake precompile step. You can, however, disable this by setting certain values to nil in the [config/initializers/react_on_rails.rb](spec/dummy/config/initializers/react_on_rails.rb).
  * `config.symlink_non_digested_assets_regex`: Set to nil to turn off the setup of non-js assets.
  * `npm_build_production_command`: Set to nil to turn off the precompilation of the js assets.
* See the [Heroku Deployment](docs/additional-reading/heroku-deployment.md) doc for specifics regarding Heroku.
* If you're using the node server for server rendering, you may want to do your own AWS install. We'll have more docs on this in the future.

## Integration with Node
Node.js can be used as the backend for server-side rendering instead of [execJS](https://github.com/rails/execjs). Before you try this, consider the tradeoff of extra complexity with your deployments versus *potential* performance gains. We've found that using ExecJS with [mini_racer](https://github.com/discourse/mini_racer) to be "fast enough" so far. That being said, we've heard of other large websites using Node.js for better server rendering performance. See [Node.js for Server Rendering](docs/additional-reading/node-server-rendering.md) for more information.

## Additional Documentation 
**Try out our new [Documentation Gitbook](https://shakacode.gitbooks.io/react-on-rails/content/) for improved readability & reference!**
+ **Rails**
  + [Rails Assets](docs/additional-reading/rails-assets.md)
  + [Rails View Rendering from Inline JavaScript](docs/additional-reading/rails_view_rendering_from_inline_javascript.md)
  + [RSpec Configuration](docs/additional-reading/rspec-configuration.md)
  + [Turbolinks](docs/additional-reading/turbolinks.md)

+ **Javascript**
  + [Node Dependencies and NPM](docs/additional-reading/node-dependencies-and-npm.md)
  + [Babel](docs/additional-reading/babel.md)
  + [React Router](docs/additional-reading/react-router.md)
  + [React & Redux](docs/additional-reading/react-and-redux.md)
  + [Webpack](docs/additional-reading/webpack.md)
  + [Webpack Configuration](docs/additional-reading/webpack.md)
  + [Webpack Cookbook](https://christianalfoni.github.io/react-webpack-cookbook/index.html)
  + [Developing with the Webpack Dev Server](docs/additional-reading/webpack-dev-server.md)
  + [Node Server Rendering](docs/additional-reading/node-server-rendering.md)
  + [Server Rendering Tips](docs/additional-reading/server-rendering-tips.md)

+ **Development**
  + [React on Rails Basic Installation Tutorial](docs/tutorial.md) ([live demo](https://hello-react-on-rails.herokuapp.com))
  + [Installation Overview](docs/basics/installation-overview.md)
  + [Migration from react-rails](docs/basics/migrating-from-react-rails.md)
  + [Recommended Project Structure](docs/additional-reading/recommended-project-structure.md)
  + [Generator Tips](docs/basics/generator.md)
  + [Hot Reloading of Assets For Rails Development](docs/additional-reading/hot-reloading-rails-development.md)
  + [Heroku Deployment](docs/additional-reading/heroku-deployment.md)
  + [Updating Dependencies](docs/additional-reading/updating-dependencies.md)

+ **API**
  + [JavaScript API](docs/api/javascript-api.md)
  + [Ruby API](docs/api/ruby-api.md)
  + [Setting up Hot Reloading during Rails Development, API docs](docs/api/ruby-api-hot-reload-view-helpers.md)

+ **[CONTRIBUTING](CONTRIBUTING.MD)**
  + [Generator Testing](docs/contributor-info/generator-testing.md)
  + [Linting](docs/contributor-info/linters.md)
  + [Releasing](docs/contributor-info/releasing.md)

+ **Misc**
  + [Tips](docs/additional-reading/tips.md)
  + [Changelog](CHANGELOG.md)
  + [Projects](PROJECTS.md)
  + [Shaka Code Style](docs/coding-style/style.md)
  + [React on Rails, Slides](http://www.slideshare.net/justingordon/react-on-rails-v4032)
  + [Code of Conduct](docs/misc/code_of_conduct.md)
  + [The React on Rails Doctrine](https://medium.com/@railsonmaui/the-react-on-rails-doctrine-3c59a778c724)

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
+ Node 5.5 or greater

## Contributing
Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to our version of the [Contributor Covenant Code of Conduct](docs/misc/code_of_conduct.md)).

See [Contributing](CONTRIBUTING.md) to get started.

## License
The gem is available as open source under the terms of the [MIT License](docs/LICENSE).

## Authors
[The Shaka Code team!](http://www.shakacode.com/about/)

The origins of the project began with the need to do a rich JavaScript interface for ShakaCode's client [Madrone](http://madroneco.com/) and the choice to use Webapck and Rails, as described in [Fast Rich Client Rails Development With Webpack and the ES6 Transpiler](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/).

The gem project started with [Justin Gordon](https://github.com/justin808/) pairing with [Samnang Chhun](https://github.com/samnang) to figure out how to do server rendering with Webpack plus Rails. [Alex Fedoseev](https://github.com/alexfedoseev) then joined in. [Rob Wise](https://github.com/robwise), [Aaron Van Bokhoven](https://github.com/aaronvb), and [Andy Wang](https://github.com/yorzi) did the bulk of the generators. Many others have [contributed](https://github.com/shakacode/react_on_rails/graphs/contributors).

We owe much gratitude to the work of the [react-rails gem](https://github.com/reactjs/react-rails).

# FINAL NOTES
* See [Projects](PROJECTS.md) using and [KUDOS](./KUDOS.md) for React on Rails. Please submit yours! Please edit either page or [email us](mailto:contact@shakacode.com) and we'll add your info. We also **love stars** as it helps us attract new users and contributors.
* Follow [@railsonmaui](https://twitter.com/railsonmaui) and [@shakacode](https://twitter.com/shakacode) on Twitter for updates on releases. We've also got a forum category dedicated to [react_on_rails](http://forum.shakacode.com/c/rails/ReactOnRails).

---

Aloha from Justin Gordon ([bio](http://www.railsonmaui.com/about)) and the [ShakaCode](http://www.shakacode.com) Team! We're actively looking for new projects. If you like **React on Rails**, please consider contacting me at [justin@shakacode.com](mailto:justin@shakacode.com) if we could potentially help you in any way. Besides consulting on bigger projects, [ShakaCode](http://www.shakacode.com) is doing Skype plus Slack/Github based coaching for React on Rails. [Click here](http://www.shakacode.com/work/index.html) for more information.

We're offering a free half-hour project consultation, on anything from React on Rails to any aspect of web application development for both consumer and enterprise products. In addition to React.js and Rails, we're doing react-native iOS and Android apps!

Whether you have a new project or need help on an existing project, feel free to contact me directly at [justin@shakacode.com](mailto:justin@shakacode.com) and thanks in advance for any referrals!

Your support keeps this project going.
