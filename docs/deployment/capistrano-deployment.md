# Capistrano Deployment

First, make sure ReactOnRails is working in the development environment.

Add the following to your Gemfile:

```ruby
group :development do
  gem 'capistrano-yarn'
end
```

Then run Bundler to ensure Capistrano is downloaded and installed:

```bash
bundle install
```

Add the following to your Capfile:

```ruby
require 'capistrano/yarn'
```

If the deployment is taking too long or getting stuck at `assets:precompile` stage, it is probably because of memory. Webpack consumes a lot of memory, so if possible, try increasing the RAM of your server.
