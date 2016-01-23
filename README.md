[![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master) [![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails) [![npm version](https://badge.fury.io/js/react-on-rails.svg)](https://badge.fury.io/js/react-on-rails)

# NEWS

* 2.0 has shipped! Please grab the latest and let us know if you see any issues! [Migration steps from 1.x](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#migration-steps).
* It does not yet have *generator* support for building new apps that use CSS modules and hot reloading via the Rails server as is demonstrated in the [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). *We do support this, but we don't generate the code.* If you did generate a fresh app from react_on_rails and want to move to CSS Modules, then see [PR 175: Babel 6 / CSS Modules / Rails hot reloading](https://github.com/shakacode/react-webpack-rails-tutorial/pull/175). Note, while there are probably fixes after this PR was accepted, this has the majority of the changes. See [the tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/#news) for more information. Ping us if you want to help!

# React on Rails

**Project Objective**: To provide an opinionated and optimal framework for integrating **Ruby on Rails** with modern JavaScript tooling and libraries, including [**Webpack**](http://webpack.github.io/), [**Babel**](https://babeljs.io/), [**React**](https://github.com/rackt/react-router), [**Redux**](https://github.com/rackt/redux), [**React-Router**](https://github.com/rackt/react-router). This differs significantly from typical Rails. When considering what goes into **react_on_rails**, we ask ourselves, is the functionality related to the intersection of using Rails and with modern JavaScript? If so, then the functionality belongs right here. In other cases, we're releasing separate npm packages or Ruby gems. If you are interested in implementing React using traditional Rails architecture, see [react-rails](https://github.com/reactjs/react-rails).

React on Rails integrates Facebook's [React](https://github.com/facebook/react) front-end framework with Rails. React v0.14.x is supported, with server rendering. [Redux](https://github.com/rackt/redux) and [React-Router](https://github.com/rackt/react-redux) are supported as well. See the Rails on Maui [blog post](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/) that started it all!

Be sure to see the [React Webpack Rails Tutorial Code](https://github.com/shakacode/react-webpack-rails-tutorial) along with the live example at [www.reactrails.com](http://www.reactrails.com).

## Including your React Component in your Rails Views
Please see [Getting Started](#getting-started) for how to set up your Rails project for React on Rails to understand how `react_on_rails` can see your ReactComponents.

+ *Normal Mode (React component will be rendered on client):*

  ```erb
  <%= react_component("HelloWorldApp", @some_props) %>
  ```
+ *Server-Side Rendering (React component is first rendered into HTML on the server):*

  ```erb
  <%= react_component("HelloWorldApp", @some_props, prerender: true) %>
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
    <%= react_component("HelloWorldApp", { name: "Stranger" })
  ```

  ```javascript
    // inside your React component
    this.props.name // "Stranger"
  ```

## Documentation

+ [Features](#features)
+ [Why Webpack?](#why-webpack)
+ [Getting Started](#getting-started)
+ [How it Works](#how-it-works)
    - [Client-Side Rendering vs. Server-Side Rendering](#client-side-rendering-vs-server-side-rendering)
    - [Building the Bundles](#building-the-bundles)
    - [Globally Exposing Your React Components](#globally-exposing-your-react-components)
    - [Rails View Helpers In-Depth](#rails-view-helpers-in-depth)
    - [Redux](#redux)
    - [React-Router](#react-router)
+ [Generator](#generator)
    - [Understanding the Organization of the Generated Client Code](#understanding-the-organization-of-the-generated-client-code)
    - [Redux](#redux)
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
Like the [react-rails](https://github.com/reactjs/react-rails) gem, React on Rails is capable of server-side rendering with fragment caching and is compatible with [turbolinks](https://github.com/rails/turbolinks). Unlike react-rails, which depends heavily on sprockets and jquery-ujs, React on Rails uses [webpack](http://webpack.github.io/) and does not depend on jQuery. While the initial setup is slightly more involved, it allows for advanced functionality such as:

+ [Redux](https://github.com/rackt/redux)
+ [Webpack dev server](https://webpack.github.io/docs/webpack-dev-server.html) with [hot module replacement](https://webpack.github.io/docs/hot-module-replacement-with-webpack.html)
+ [Webpack optimization functionality](https://github.com/webpack/docs/wiki/optimization)
+ [React Router](https://github.com/rackt/react-router)

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
  gem "react_on_rails", "~> 2.0.0"
  ```

2. See help for the generator:

  ```bash
  rails generate react_on_rails:install --help
  ```

2. Run the generator with a simple "Hello World" example (more options below):

  ```bash
  rails generate react_on_rails:install
  ```

3. NPM install. Make sure you are on a recent version of node, preferably using nvm. We've heard some reports that you need at least Node v5.

  ```bash
  npm install
  ```

4. Start your Rails server:

  ```bash
  foreman start -f Procfile.dev
  ```

5. Visit [localhost:3000/hello_world](http://localhost:3000/hello_world)

## NPM
All JavaScript in React On Rails is loaded from npm: [react-on-rails](https://www.npmjs.com/package/react-on-rails). To manually install this (you did not use the generator), assuming you have a standard configuration, run this command:

```
cd client && npm i --saveDev react-on-rails
```

That will install the latest version and update your package.json.

## How it Works
The generator installs your webpack files in the `client` folder. Foreman uses webpack to compile your code and output the bundled results to `app/assets/javascripts/generated`, which are then loaded by sprockets. These generated bundle files have been added to your `.gitignore` for your convenience.

Inside your Rails views, you can now use the `react_component` helper method provided by React on Rails.

### Client-Side Rendering vs. Server-Side Rendering
In most cases, you should use the `prerender: false` (default behavior) with the provided helper method to render the React component from your Rails views. In some cases, such as when SEO is vital or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript using [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. We recommend using [therubyracer](https://github.com/cowboyd/therubyracer) as ExecJS's runtime. The generator will automatically add it to your Gemfile for you.

Note that **server-rendering requires globally exposing your components by setting them to `global`, not `window`** (as is the case with client-rendering). If using the generator, you can pass the `--server-rendering` option to configure your application for server-side rendering.

In the following screenshot you can see the 3 parts of react_on_rails rendering:

1. Inline JavaScript to "client-side" render the React component.
2. The wrapper div `<div id="HelloWorld-react-component-0">` enclosing the server-rendered HTML for the React component
3. Additional JavaScript to console log any messages, such as server rendering errors.

**Note**: If server rendering is not used (prerender: false), then the major difference is that the HTML rendered contains *only* the outer div: `<div id="HelloWorld-react-component-0"/>`

![Comparison of a normal React Component with its server-rendered version](https://cloud.githubusercontent.com/assets/1118459/10157268/41435186-6624-11e5-9341-6fc4cf35ee90.png)

### Building the Bundles
Each time you change your client code, you will need to re-generate the bundles (the webpack-created JavaScript files included in application.js). The included Foreman `Procfile.dev` will take care of this for you by watching your JavaScript code files for changes. Simply run `foreman start -f Procfile.dev`.

On Heroku deploys, the `lib/assets.rake` file takes care of running webpack during deployment. If you have used the provided generator, these bundles will automatically be added to your `.gitignore` in order to prevent extraneous noise from re-generated code in your pull requests. You will want to do this manually if you do not use the provided generator.

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

### Rails View Helpers In-Depth
Once the bundled files have been generated in your `app/assets/javascripts/generated` folder and you have exposed your components globally, you will want to run your code in your Rails views using the included helper method.

This is how you actually render the React components you exposed to `window` inside of `clientRegistration` (and `global` inside of `serverRegistration` if you are server rendering).

#### react_component
`react_component(component_name, props = {}, options = {})`

+ **component_name:** Can be a React component, created using a ES6 class, or `React.createClass`, or a generator function that returns a React component.
+ **props:** Ruby Hash which contains the properties to pass to the react object, or a JSON string. If you pass a string, we'll escape it for you.
+ **options:**
  + **prerender:** enable server-side rendering of component. Set to false when debugging!
  + **router_redirect_callback:** Use this option if you want to provide a custom handler for redirects on server rendering. If you don't specify this, we'll simply change the rendered output to a script that sets window.location to the new route. Set this up exactly like a generator_function. Your function will will take one parameter, containing all the values that react-router gives on a redirect request, such as pathname, search, etc.
  + **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise.
  + **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the default configuration of logging_on_server set to true, you'll still see the errors on the server.
  + **raise_on_prerender_error:** Default is false. True will throw an error on the server side rendering. Your controller will have to handle the error.
+ Any other options are passed to the content tag, including the id

#### Generator Functions
Why would you create a function that returns a React compnent? For example, you may want the ability to use the passed-in props to initialize a redux store or setup react-router. Or you may want to return different components depending on what's in the props. ReactOnRails will automatically detect a registered generator function.

#### server_render_js
`server_render_js(js_expression, options = {})`

+ js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught and console messages handled properly
+ Currently the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.

## Generator
The `react_on_rails:install` generator combined with the example pull requests of generator runs will get you up and running efficiently. There's a fair bit of setup with integrating Webpack with Rails. Defaults for options are such that the default is for the flag to be off. For example, the default for `-R` is that `redux` is off, and the default of `-b` means that `skip-bootstrap` is off.

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

For a clear example of what each generator option will do, see our generator results repo: [Generator Results](https://github.com/shakacode/react_on_rails-generator-results/blob/master/README.md). Each pull request shows a git "diff" that highlights the changes that the generator has made. Another good option is to create a simple test app per the [Tutorial for v2.0](docs/tutorial-v2.md).

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

#### Bootstrap via Webpack Dev Server
When using the webpack dev server, which does not go through Rails, bootstrap is loaded via the [bootstrap-sass-loader](https://github.com/shakacode/bootstrap-sass-loader) which uses the `client/bootstrap-sass-config.js` file.

#### Keeping Custom Bootstrap Configurations Synced
Because the webpack dev server and Rails each load Bootstrap via a different file (explained in the two sections immediately above), any changes to the way components are loaded in one file must also be made to the other file in order to keep styling consistent between the two. For example, if an import is excluded in `_bootstrap-custom.scss`, the same import should be excluded in `bootstrap-sass-config.js` so that styling in the Rails server and the webpack dev server will be the same.

#### Skip Bootstrap Integration
Bootstrap integration is enabled by default, but can be disabled by passing the `--skip-bootstrap` flag (alias `-b`). When you don't need Bootstrap in your existing project, just skip it as needed.

### Linters
The React on Rails generator can add linters and their recommended accompanying configurations to your project. There are two classes of linters: ruby linters and JavaScript linters.

##### JavaScript Linters
JavaScript linters are **enabled by default**, but can be disabled by passing the `--skip-js-linters` flag (alias `j`) , and those that run in Node have been add to `client/package.json` under `devDependencies`.

##### Ruby Linters
Ruby linters are **disabled by default**, but can be enabled by passing the `--ruby-linters` flag when generating. These linters have been added to your Gemfile in addition to the the appropriate Rake tasks.

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

## Developing with the Webpack Dev Server
One of the benefits of using webpack is access to [webpack's dev server](https://webpack.github.io/docs/webpack-dev-server.html) and its [hot module replacement](https://webpack.github.io/docs/hot-module-replacement-with-webpack.html) functionality.

The webpack dev server with HMR will apply changes from the code (or styles!) to the browser as soon as you save whatever file you're working on. You won't need to reload the page, and your data will still be there. Start foreman as normal (it boots up the Rails server *and* the webpack HMR dev server at the same time).

  ```bash
  foreman start -f Procfile.dev
  ```

Open your browser to [localhost:4000](http://localhost:4000). Whenever you make changes to your JavaScript code in the `client` folder, they will automatically show up in the browser. Hot module replacement is already enabled by default.

Note that **React-related error messages are typically significantly more helpful when encountered in the dev server** than the Rails server as they do not include noise added by the React on Rails gem.

### Adding Additional Routes for the Dev Server
As you add more routes to your front-end application, you will need to make the corresponding API for the dev server in `client/server.js`. See our example `server.js` from our [tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/server.js).

## Migrate From react-rails
If you are using [react-rails](https://github.com/reactjs/react-rails) in your project, it is pretty simple to migrate to [react_on_rails](https://github.com/shakacode/react_on_rails).

1. Remove the 'react-rails' gem from your Gemfile.

2. Remove the generated generated lines for react-rails in your application.js file. 

```
//= require react
//= require react_ujs
//= require components
```

3. Follow our getting started guide: https://github.com/shakacode/react_on_rails#getting-started.

Note: If you have components from react-rails you want to use, then you will need to port them into react_on_rails which uses webpack instead of the asset pipeline.


## Additional Reading
+ [Generated Client Code](docs/additional_reading/generated_client_code.md)
+ [Heroku Deployment](docs/additional_reading/heroku_deployment.md)
+ [Manual Installation](docs/additional_reading/manual_installation.md)
+ [Node Dependencies and NPM](docs/additional_reading/node_dependencies_and_npm.md)
+ [Optional Configuration](docs/additional_reading/optional_configuration.md)
+ [React Router](docs/additional_reading/react_router.md)
+ [Server Rendering Tips](docs/additional_reading/server_rendering_tips.md)
+ [Tips](docs/additional_reading/tips.md)
+ [Webpack Configuration](docs/additional_reading/webpack.md)
+ [Webpack Cookbook](https://christianalfoni.github.io/react-webpack-cookbook/index.html)

## Contributing
Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to our version of the [Contributor Covenant](contributor-covenant.org) code of conduct (see [CODE OF CONDUCT](docs/code_of_conduct.md)).

See [Contributing](docs/contributing.md) to get started.

## License
The gem is available as open source under the terms of the [MIT License](docs/LICENSE).

## Authors
[The Shaka Code team!](http://www.shakacode.com/about/)

The project started with [Justin Gordon](https://github.com/justin808/) pairing with [Samnang Chhun](https://github.com/samnang) to figure out how to do server rendering with Webpack plus Rails. [Alex Fedoseev](https://github.com/alexfedoseev) then joined in. [Rob Wise](https://github.com/robwise), [Aaron Van Bokhoven](https://github.com/aaronvb), and [Andy Wang](https://github.com/yorzi) did the bulk of the generators.

We owe much gratitude to the work of the [react-rails gem](https://github.com/reactjs/react-rails). We've also been inspired by the [react_webpack_rails gem](https://github.com/netguru/react_webpack_rails).

## About [ShakaCode](http://www.shakacode.com/)

Visit [our forums!](http://forum.shakacode.com). We've got a [category dedicated to react_on_rails](http://forum.shakacode.com/c/rails/reactonrails).

If you're looking for consulting on a project using React and Rails, email us ([contact@shakacode.com](mailto: contact@shakacode.com))! You can also join our slack room for some free advice.

We're looking for great developers that want to work with Rails + React with a distributed, worldwide team, for our own products, client work, and open source. [More info here](http://www.shakacode.com/about/index.html#work-with-us).
