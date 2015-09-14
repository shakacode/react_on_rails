# React On Rails

Published: https://rubygems.org/gems/react_on_rails

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

# Authors
The Shaka Code team!

1. [Justin Gordon](https://github.com/justin808/)
2. [Samnang Chhun](https://github.com/samnang)
3. [Alex Fedoseev](https://github.com/alexfedoseev)

And based on the work of the [react-rails gem](https://github.com/reactjs/react-rails)

# Key Info
Currently being implemented in 3 production projects (not yet live).

1. https://github.com/justin808/react-webpack-rails-tutorial/ See https://github.com/shakacode/react-webpack-rails-tutorial/pull/84 for how we integrated it!
2. http://www.railsonmaui.com/blog/2014/10/03/integrating-webpack-and-the-es6-transpiler-into-an-existing-rails-project/
3. http://forum.railsonmaui.com
4. Lots of work to do in terms of docs, tests
5. If this project is interesting to you, email me at justin@shakacode.com. We're looking for great
developers that want to work with Rails + React with a distributed, worldwide team.


# Try it out!
Contributions and pull requests welcome!

1. Setup and run the test app. There's no database.
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
5. Open up the browser console and see some tracing.
6. Open up the source for the page and see the server rendered code.
7. If you want to turn off server caching, run the server like:
   `export RAILS_USE_CACHE=N && foreman start`
8. If you click back and forth between the about and react page links, you can see the rails console
   log as well as the browser console to see what's going on with regards to server rendering and
   caching.

# Key Tips
1. See sample app in `spec/dummy` for how to set this up.
2. The file used for server rendering defaults as `generated/server.js`
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

TODO: Check if this is true still
3. If you're only doing client rendering, you still *MUST* create an empty version of this file. This
   will soon change so that this is not necessary.

# Example Configuration, config/react_on_rails.rb
```ruby
ReactOnRails.configure do |config|
  # Client bundles are configured in application.js
  # Server bundle is a single file for all server rendering of components.
  config.server_bundle_js_file = "app/assets/javascripts/generated/server.js" # This is the default

  config.prerender = true # default is false
  config.replay_console = true # Default is true. Be cautious about turning this off.
  config.generator_function = false # default is false, meaning that you expose ReactComponents directly
  config.trace = Rails.env.development? # default is true for development, off otherwise
end

```

## JavaScript Runtime
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

## Installation

Add these linesto your application's Gemfile, sustituting your preferable JavaScript engine.

```ruby
gem "react_on_rails"
gem "therubyracer"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install react_on_rails

## Usage

PENDING. See `spec/dummy` for the sample app.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shakacode/react_on_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Updating New Versions of the Gem
See https://github.com/svenfuchs/gem-release
