[![Build Status](https://travis-ci.org/shakacode/react_on_rails.svg?branch=master)](https://travis-ci.org/shakacode/react_on_rails)
[![Coverage Status](https://coveralls.io/repos/shakacode/react_on_rails/badge.svg?branch=master&service=github)](https://coveralls.io/github/shakacode/react_on_rails?branch=master)
[![Dependency Status](https://gemnasium.com/shakacode/react_on_rails.svg)](https://gemnasium.com/shakacode/react_on_rails)
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
1. See sample app in `spec/dummy` for how to set this up. See note below on ensuring you **DO NOT RUN `rails s` and instead     run `foreman start`. 
2. The file used for server rendering is hard coded as `generated/server.js`
   (assets/javascripts/generated/server.js).
3. If you're only doing client rendering, you still *MUST* create an empty version of this file. This
   will soon change so that this is not necessary.
3. The default for rendering right now is `prerender: false`. **NOTE:**  Server side rendering does 
   not work for some components, namely react-router, that use an async setup for server rendering. 
   You can configure the default for prerender in your config. 
4. The API for objects exposed differs from the react-rails gem in that you expose a function that
   returns a react component. We'll be changing that to take either a function or a React component.

# Example Configuration, config/react_on_rails.rb
```ruby
   ReactOnRails.configure do |config|
     config.bundle_js_file = "app/assets/javascripts/generated/server.js" # This is the default
     config.prerender = true # default is false
   end
```

## References
* [Making the helper for server side rendering work with JS created by Webpack] (https://github.com/reactjs/react-rails/issues/301#issuecomment-133098974)
* [Add Demonstration of Server Side Rendering](https://github.com/justin808/react-webpack-rails-tutorial/issues/2)
* [Charlie Marsh's article "Rendering React Components on the Server"](http://www.crmarsh.com/react-ssr/)
* [Node globals](https://nodejs.org/api/globals.html#globals_global)

## Application Installation

Add this line to your application's Gemfile:

```ruby
gem 'react_on_rails'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install react_on_rails

## Usage

PENDING. See `spec/dummy` for the sample app. 

## Development Setup

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

### Linting
All linting is performed from the docker container. You will need docker and docker-compose installed
locally to lint code changes via the lint container. 

[For Mac users install Docker Toolbox](https://www.docker.com/toolbox)
[For Linux user install Docker Compose](https://docs.docker.com/compose/install/)

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
