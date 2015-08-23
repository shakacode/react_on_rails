# ReactRailsServerRendering

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/react_rails_server_rendering`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## References
* [Making the helper for server side rendering work with JS created by Webpack] (https://github.com/reactjs/react-rails/issues/301#issuecomment-133098974)
* [Add Demonstration of Server Side Rendering](https://github.com/justin808/react-webpack-rails-tutorial/issues/2)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'react_rails_server_rendering'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install react_rails_server_rendering

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/react_rails_server_rendering. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

# Server Rendering with ReactJs, Webpack, and Rails

SPIKE with Samnang and Justin on making React server render with Webpack!

# Setup:
1. bundle
2. cd client && npm i
3. Terminal 1: $(npm bin)/webpack --config webpack.server.js -w
4. Terminal 2: $(npm bin)/webpack --config webpack.client.js -w
5. Terminal 3: bin/rails s


# Notes:
1. You can mark the globals to export in one of 2 ways:
   a. Use global.Something = Something (see Global.js)
   b. Declare in webpack config file
2. models/execjs_renderer changes often require a server restart. However, changing the contents
   of the javascript file don't seem matter, so long as webpack recompiles it.

# References
1. [Charlie Marsh's article "Rendering React Components on the Server"](http://www.crmarsh.com/react-ssr/)
2. [Node globals](https://nodejs.org/api/globals.html#globals_global)
