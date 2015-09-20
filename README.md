[![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails)
[![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master)
[![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails)
# React On Rails

Gem Published: https://rubygems.org/gems/react_on_rails

See [Action Plan for v1.0](https://github.com/shakacode/react_on_rails/issues/1)

Feedback and pull-requests encouraged! Thanks in advance!

Supports:

1. Rails
2. Webpack
3. React
4. Redux
5. Turbolinks
6. Server side rendering with fragment caching
7. react-router for client side rendering (and maybe server side eventually)

# Links
1. https://github.com/justin808/react-webpack-rails-tutorial/ See https://github.com/shakacode/react-webpack-rails-tutorial/pull/84 for how we integrated it!
2. http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/
3. http://forum.railsonmaui.com
5. If this project is interesting to you, email me at justin@shakacode.com. We're looking for great
developers that want to work with Rails + React with a distributed, worldwide team, for our own
products, client work, and open source.

## Application Installation

Add these lines to your application's Gemfile, sustituting your preferable JavaScript engine.

```ruby
gem "react_on_rails"
gem "therubyracer"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install react_on_rails

## Usage

*See section below titled "Try it out"*

### Helper Method
The main API is a helper:

```ruby
  react_component(component_name, props = {}, options = {})
```
  
Params are:
```  
react_component_name: can be a React component, created using a ES6 class, or
  React.createClass, or a
    `generator function` that returns a React component
      using ES6
         let MyReactComponentApp = (props) => <MyReactComponent {...props}/>;
      or using ES5
         var MyReactComponentApp = function(props) { return <YourReactComponent {...props}/>; }
   Exposing the react_component_name is necessary to both a plain ReactComponent as well as
     a generator:
   For client rendering, expose the react_component_name on window:
     window.MyReactComponentApp = MyReactComponentApp;
   For server rendering, export the react_component_name on global:
     global.MyReactComponentApp = MyReactComponentApp;
   See spec/dummy/client/app/startup/serverGlobals.jsx and
     spec/dummy/client/app/startup/ClientApp.jsx for examples of this
props: Ruby Hash which contains the properties to pass to the react object

 options:
   generator_function: <true/false> default is false, set to true if you want to use a
                       generator function rather than a React Component.
   prerender: <true/false> set to false when debugging!
   trace: <true/false> set to true to print additional debugging information in the browser
          default is true for development, off otherwise
   replay_console: <true/false> Default is true. False will disable echoing server rendering
                   logs, which can make troubleshooting server rendering difficult.
```

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
   for client side rendering.
   ```ruby
   import HelloWorld from '../components/HelloWorld';
   global.HelloWorld = HelloWorld;
   ```

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
end
```

# Try it out in the simple sample app
Contributions and pull requests welcome!

1. Setup and run the test app in `spec/dummy`. Note, there's no database.
  ```bash
  cd spec/dummy
  bundle
  npm i
  foreman start
  ```
2. Caching is turned for development mode. Open the console and run `Rails.cache.clear` to clear
  the cache. Note, even if you stop the server, you'll still have the cache entries around.
3. Visit http://localhost:3000
4. Notice that the first time you hit the page, you'll see a message that server is rendering.
   See `spec/dummy/app/views/pages/index.html.erb:17` for the generation of that message.
5. Look at the layouts in `spec/dummy/app/views/pages` for samples of usage.
5. Open up the browser console and see some tracing.
6. Open up the source for the page and see the server rendered code.
7. If you want to turn off server caching, run the server like:
   `export RAILS_USE_CACHE=N && foreman start`
8. If you click back and forth between the about and react page links, you can see the rails console
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

TODO: Check if this is true still: If you're only doing client rendering, you still *MUST* create an empty version of this file. This
will soon change so that this is not necessary.

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


## Development Setup for Gem Contributors

### Initial Setup
After checking out the repo, making sure you have rvm and nvm setup (setup ruby and node), 
cd to `spec/dummy` and run `bin/setup` to install dependencies.  
You can also run `bin/console` for an interactive prompt that will allow you to experiment. 

### Starting the Dummy App
To run the test app, it's **CRITICAL** to not just run `rails s`. You have to run `foreman start`. 
If you don't do this, then `webpack` will not generate a new bundle, 
and you will be seriously confused when you change JavaScript and the app does not change. 

### Install and Release
To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, 
update the version number in `version.rb`, and then run `bundle exec rake release`, 
which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### RSpec Testing
Run `rake` for testing the gem and `spec/dummy`. Otherwise, the `rspec` command only works for testing within `spec/dummy`.

If you run `rspec` at the top level, you'll see this message: `require': cannot load such file -- rails_helper (LoadError)`

### Debugging
Start the sample app like this for some debug printing:
```bash
TRACE_REACT_ON_RAILS=true && foreman start
```

### Linting
All linting is performed from the docker container. You will need docker and docker-compose installed
locally to lint code changes via the lint container. 

* [Install Docker Toolbox for Mac](https://www.docker.com/toolbox)
* [Install Docker Compose for Linux](https://docs.docker.com/compose/install/)

Once you have docker and docker-compose running locally, run `docker-compose build lint`. This will build
the `reactonrails_lint` docker image and docker-compose `lint` container. The inital build is slow,
but after the install, startup is very quick.

### Linting Commands
Run `rake -D docker` to see all docker linting commands for rake. `rake docker` will run all linters.
For individual rake linting commands please refer to `rake -D docker` for the list.
You can run specfic linting for directories or files by using `docker-compose run lint rubocop (file path or directory)`, etc.
`docker-compose run lint /bin/bash` sets you up to run from the container command line. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shakacode/react_on_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Updating New Versions of the Gem

See https://github.com/svenfuchs/gem-release

# Authors
The Shaka Code team!

1. [Justin Gordon](https://github.com/justin808/)
2. [Samnang Chhun](https://github.com/samnang)
3. [Alex Fedoseev](https://github.com/alexfedoseev)

And based on the work of the [react-rails gem](https://github.com/reactjs/react-rails)
