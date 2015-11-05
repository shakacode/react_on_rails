[![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails) [![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master) [![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails) [![Gem Version](https://badge.fury.io/rb/react_on_rails.svg)](https://badge.fury.io/rb/react_on_rails)

# React on Rails
React on Rails integrates Facebook's [React](https://github.com/facebook/react) front-end framework with Rails. Currently, both React v0.14 and v0.13 are supported. See the Rails on Maui [blog post](http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/) that started it all!

Like the [react-rails](https://github.com/reactjs/react-rails) gem, React on Rails is capable of server-side rendering with fragment caching and is compatible with [turbolinks](https://github.com/rails/turbolinks). Unlike react-rails, which depends heavily on sprockets and jquery-ujs, React on Rails uses [webpack](http://webpack.github.io/) and does not depend on jQuery. While the initial setup is slightly more involved, it allows for advanced functionality such as:

+ [Redux](https://github.com/rackt/redux)
+ [Webpack dev server](https://webpack.github.io/docs/webpack-dev-server.html) with [hot module replacement](https://webpack.github.io/docs/hot-module-replacement-with-webpack.html)
+ [Webpack optimization functionality](https://github.com/webpack/docs/wiki/optimization)
+ **(Coming Soon)** [React Router](https://github.com/rackt/react-router)

See the [react-webpack-rails-tutorial](https://github.com/justin808/react-webpack-rails-tutorial/) for an example of a live implementation and code.

### Including your React Component in your Rails Views
Please see [Getting Started](#getting-started) for how to set up your Rails project for React on Rails if you have not already done so.

+ *Normal Mode (JavaScript is rendered on client):*

  ```erb
  <%= react_component("HelloWorldApp", @some_props) %>
  ```
+ *Server-Side Rendering:*

  ```erb
  <%= react_component("HelloWorldApp", @some_props, prerender: true) %>
  ```

+ The `component_name` parameter here would be a string matching the name you used when globally exposing your React component.
+ `@some_props` can be either a hash or JSON string or {} if you have no props. This will make the data available in your component:

  ```javascript
    this.props.name
  ```

### Client-Side Rendering vs. Server-Side Rendering
In most cases, you should use the provided helper method to render the React component from your Rails views with `prerender: false` (default behavior). In some cases, such as when SEO is vital or many users will not have JavaScript enabled, you can pass the `--server-rendering` option to the generator to configure your application for server-side rendering. Your JavaScript can then be first rendered on the server and passed to the client as HTML.

In the following screenshot you can see the actual HTML rendered for a side-by-side comparison of a React component left as JavaScript for the client to render followed by the same component rendered on the server to HTML along with any console error messages generated:

![Comparison of a normal React Component with its server-rendered version](https://cloud.githubusercontent.com/assets/1118459/10157268/41435186-6624-11e5-9341-6fc4cf35ee90.png)

## Getting Started
1. Add the following to your Gemfile and bundle install:
  
  ```ruby
  gem "react_on_rails"
  gem "therubyracer"
  ```

2. Run the generator with a simple "Hello World" example:

  ```bash
  rails generate react_on_rails:install
  ```

3. NPM install. Make sure you are on a recent version of node, preferably using nvm.

  ```bash
  npm install
  ```

4. Start your Rails server:

  ```bash
  foreman start -f Procfile.dev
  ```

5. Visit [localhost:3000/hello_world](http://localhost:3000/hello_world)

## How it Works
The generator installs your webpack files in the `client` folder. Foreman uses webpack to compile your code and output the bundled results to `app/assets/javascripts/generated`, which are then loaded by sprockets. These generated bundle files have been added to your `.gitignore` for your convenience.

Inside your Rails views, you can now use the `react_component` helper method provided by React on Rails.

### Building the Bundles
Each time you change your client code, you will need to re-generate the bundles. The included Foreman `Procfile.dev` will take care of this for you by watching your JavaScript code files for changes. Simply run `foreman start -f Procfile.dev`.

### Globally Exposing Your React Components
Place your JavaScript code inside of the provided `client/app` folder. Use modules just as you would when using webpack alone. The difference here is that instead of mounting React components directly to an element using `React.render`, you **expose your components globally and then mount them with helpers inside of your Rails views**.

+ *Normal Mode (JavaScript is Rendered on client):*

  ```javascript
  window.HelloWorld = HelloWorldAppClient;
  ```
+ *Server-Side Rendering:*

  ```javascript
  global.HelloWorld = HelloWorldAppServer;
  ```
   

## Generator Options
Run `rails generate react_on_rails:install --help` for descriptions of all available options:

```
Usage:
  rails generate react_on_rails:install [options]

Options:
  -R, [--redux], [--no-redux]                        # Setup Redux files
  -S, [--server-rendering], [--no-server-rendering]  # Configure for server-side rendering of webpack JavaScript
  -L, [--skip-linters], [--no-skip-linters]          # Don't install linter files

Runtime options:
  -f, [--force]                    # Overwrite files that already exist
  -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  -q, [--quiet], [--no-quiet]      # Suppress status output
  -s, [--skip], [--no-skip]        # Skip files that already exist

Description:
    Create react on rails files for install generator.
```

We have a repo showing the results of running the generator with various combinations of options, each combination on its own branch: [Generator Results](https://github.com/shakacode/react_on_rails-generator-results-pre-0/pulls).

### Understanding the Organization of the Generated Client Code
The generated client code follows our organization scheme. Each unique set of functionality, is given its own folder inside of `client/app/bundles`. This encourages for modularity of DOMAINS.

Inside of the generated "HelloWorld" domain you will find the following folders:

+  `startup`: two types of files, one that return a container component and implement any code that differs between client and server code (if using server-rendering), and a `clientGlobals` file that exposes the aforementioned files (as well as a `serverGlobals` file if using server rendering). These globals files are what webpack is using as an entry point.
+ `containers`: "smart components" (components that have functionality and logic that is passed to child "dumb components").
+ `components`: includes "dumb components", or components that simply render their properties and call functions given to them as properties by a parent component. Ultimately, at least one of these dumb components will have a parent container component.

You may also notice the `app/lib` folder. This is for any code that is common between bundles and therefore needs to be shared (for example, middleware).

#### Additional Redux Folders
If you have used the `--redux` generator option, you will notice the familiar additional redux folders in addition to the aforementioned folders. In this organization paradigm, each bundle has its own store. We do not set a global store and then use partial stores based off of that. Again, this is for bundle code modularity and isolation. Note that if you want to reuse redux reducers across domains, then you will want to put the shared reducers under `/client/app/lib`.

### Using Images and Fonts
The generator has amended the folders created in `client/assets/` to Rails's asset path. We would that if you have any existing assets that you want to use with your client code that you should move them to these folders and use webpack as normal.

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
Because the HMR dev server and Rails each load Bootstrap via a different file (explained in the two sections immediately above), any changes to the way components are loaded in one file must also be made to the other file in order to keep styling consistent between the two. For example, if an import is excluded in `_bootstrap-custom.scss`, the same import should be excluded in `bootstrap-sass-config.js` so that styling in the Rails server and the webpack dev server will be the same.

## Rails View Helpers In-Depth
Once the bundled files have been generated in your `app/assets/javascripts/generated` folder and you have exposed your components globally, you will want to run your code in your Rails views using the included helper method.

This is how you actually render the React components you exposed to `window` inside of `clientGlobals` (and `global` inside of `serverGlobals` if you are server rendering).

`react_component(component_name, props = {}, options = {})`
+ **react_component_name:** Can be a React component, created using a ES6 class, or `React.createClass`, or a generator function that returns a React component.
+ **props:** Ruby Hash which contains the properties to pass to the react object
+ **options:**
  + **generator_function:** default is false, set to true if you want to use a generator function rather than a React Component.
  + **prerender:** enable server-side rendering of component. Set to false when debugging!
  + **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise.
  + **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the default configuration of logging_on_server set to true, you'll still see the errors on the server.
+ Any other options are passed to the content tag, including the id

`def server_render_js(js_expression, options = {})`

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.

## Developing with Webpack Dev Server
One of the benefits of using webpack is access to [webpack's dev server](https://webpack.github.io/docs/webpack-dev-server.html) and its [hot module replacement](https://webpack.github.io/docs/hot-module-replacement-with-webpack.html) functionality.

The webpack dev server with HMR will apply changes from the code (or styles!) to the browser as soon as you save whatever file you're working on. You won't need to reload the page, and your data will still be there. Start foreman as normal (it boots up the Rails server *and* the webpack HMR dev server at the same time).

  ```bash
  foreman start -f Procfile.dev
  ```

Open your browser to [localhost:4000](http://localhost:4000). Whenever you make changes to your JavaScript code in the `client` folder, they will automatically show up in the browser. Hot module replacement is already enabled by default.

Note that **React-related error messages are typically significantly more helpful when encountered in the dev server** than the Rails server as they do not include noise added by the React on Rails gem.

### Adding Additional Routes for the Dev Server
As you add more routes to your front-end application, you will need to make the corresponding API for the dev server in `client/server.js`. See our example `server.js` from our [tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/server.js).

## Additional Documentation:

+ [Linters](docs/linters.md)
+ [Manual Configuration](docs/manual_configuration.md)
+ [Node Dependencies and NPM](docs/node_dependencies_and_npm.md)

## Contributing
Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to our version of the [Contributor Covenant](contributor-covenant.org) code of conduct (see [CODE OF CONDUCT](CODE_OF_CONDUCT.md)).

See [Contributing](docs/Contributing.md) to get started.

## License
The gem is available as open source under the terms of the [MIT License](LICENSE).

## Authors
[The Shaka Code team!](http://www.shakacode.com/about/)

1. [Justin Gordon](https://github.com/justin808/)
2. [Samnang Chhun](https://github.com/samnang)
3. [Alex Fedoseev](https://github.com/alexfedoseev)
4. [Rob Wise](https://github.com/robwise)
5. [Blaine Hatab](https://github.com/jbhatab)
6. [Roger Studner](https://github.com/rstudner)
7. [Aaron Van Bokhoven](https://github.com/aaronvb)

And based on the work of the [react-rails gem](https://github.com/reactjs/react-rails)

## About [ShakaCode](http://www.shakacode.com/)

Visit [our forums!](http://forum.shakacode.com)

If you're looking for consulting on a project using React and Rails, email us ([contact@shakacode.com](mailto: contact@shakacode.com))! You can also join our slack room for some free advice.

We're looking for great developers that want to work with Rails + React with a distributed, worldwide team, for our own products, client work, and open source. [More info here](http://www.shakacode.com/about/index.html#work-with-us).
