# Capistrano Deployment
Make sure ReactOnRails is working in development environment.

Add the following to development your Gemfile and bundle install.
``` ruby
group :development do
  gem 'capistrano-yarn'
end
```
Then run Bundler to ensure Capistrano is downloaded and installed.
``` sh
$ bundle install
```
Add the following in your Capfile.
``` ruby
require 'capistrano/yarn'
```
If the deployment is taking too long or getting stuck at assets:precompile stage, it probably is because of memory. Webpack consumes a lot of memory so if possible, try increasing the RAM of your server.
