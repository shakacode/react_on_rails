# React on Rails Basic Tutorial

-----

**November 11, 2020**: See the example repo of [React on Rails Tutorial With SSR, HMR fast refresh, and TypeScript](https://github.com/shakacode/react_on_rails_tutorial_with_ssr_and_hmr_fast_refresh) for a new way to setup the creation of your SSR bundle with `rails/webpacker`. This file will be update shortly. Most of it is still relevant.

-----

*Updated for Ruby 2.7.1, Rails 6.0.3.1, and React on Rails v12.0.0*

This tutorial guides you through setting up a new or existing Rails app with **React on Rails**, demonstrating Rails + React + Redux + Server Rendering.

After finishing this tutorial you will get an application that can do the following (live on Heroku):

![example](https://cloud.githubusercontent.com/assets/371302/17368567/111cc722-596b-11e6-9b72-ac5967a60e42.gif)

You can find here:
* [Source code for this app in PR, using the --redux option](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/17) and [for Heroku](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/18).
* [Live on Heroku](https://react-on-rails-redux-gen-8-0-0.herokuapp.com/)

By the time you read this, the latest may have changed. Be sure to check the versions here:

* https://rubygems.org/gems/react_on_rails
* https://www.npmjs.com/package/react-on-rails

_Note: some of the screen images below show the "npm" command. react_on_rails 6.6.0 and greater uses `yarn`._

## Setting up your environment

Trying out **React on Rails** is super easy, so long as you have the basic prerequisites. This includes the basics for Rails 6.x and node version 13+. I recommend `rvm` and `nvm` to install Ruby and Node, and [brew](https://brew.sh/) to install [yarn](https://yarnpkg.com/en/docs/install#mac-tab). Rails can be installed as an ordinary gem.

```
nvm install node                # download and install latest stable Node
nvm alias default node          # make it default version
nvm list                        # check

brew install yarn               # you can use other installer if desired
rvm install 2.7                 # download and install latest stable Ruby (update to exact version)
rvm use 2.7 --default           # use it and make it default
rvm list                        # check

gem install rails               # download and install latest stable Rails
gem install foreman             # download and install Foreman
```

## Create a new Ruby on Rails App
Then we need to create a fresh Rails application with webpacker react support as following.

First be sure to run `rails -v` and check you are using Rails 5.1.3 or above. If you are using an older version of Rails, you'll need to install webpacker with react per the instructions [here](https://github.com/rails/webpacker).

```
cd <directory where you want to create your new Rails app>

# Any name you like for the rails app
# Skip javascript so will add that next and get the current version 
rails new --skip-sprockets -J --skip-turbolinks test-react-on-rails-v12-no-sprockets

cd test-react-on-rails
bundle
```

## Add the webpacker gem

```
bundle add webpacker                 
bundle add react_on_rails
```

## Run the webpacker generator

```
bundle exec rails webpacker:install
bundle exec rails webpacker:install:react
```

Let's commit everything before installing React on Rails.

```
# Here are git commands to make a new git repo and commit everything.
# Newer versions of Rails create the git repo by default.
git add -A
git commit -m "Initial commit"
```

## Add the **React On Rails** gem to your `Gemfile`:

To avoid issues regarding inconsistent gem and npm versions, you should specify the exact versions
of both the gem and npm package. In other words, don't use the `^` or `~` in the version specifications.

```
gem 'react_on_rails', '12.0.0'         # prefer exact gem version to match npm version
```

Note: The latest released React On Rails version is considered stable. Please use the latest 
version to ensure you get all the security patches and the best support.

Run `bundle` and commit the changes.

```
bundle

git commit -am "Added React on Rails Gem"
```

Install React on Rails: `rails generate react_on_rails:install`. You need to first git commit your files before running the generator, or else it will generate an error.

Note, using `redux` is no longer recommended as the basic installer uses React Hooks. 
If you want the redux install: `rails generate react_on_rails:install --redux`

```
rails generate react_on_rails:install
```

Then run server with a static client bundle. Static means that the bundle is saved in your
public/webpack/packs directory.

```
foreman start -f Procfile.dev
```

## To run with the webpack-dev-server:
```
foreman start -f Procfile.dev-hmr
```

Visit [http://localhost:3000/hello_world](http://localhost:3000/hello_world) and see your **React On Rails** app running!

# HMR vs. React Hot Reloading

First, check that the `hmr` and the `inline` options are `true` in your `config/webpacker.yml` file.

The basic setup will have HMR working with the default webpacker setup. The basic
[HMR](https://webpack.js.org/concepts/hot-module-replacement/), without a special
React setup, will cause a full page refresh each time you save a file. 

## Deploying to Heroku

### Create Your Heroku App
*Assuming you can login to heroku.com and have logged into to your shell for heroku.*

1. Visit [https://dashboard.heroku.com/new](https://dashboard.heroku.com/new) and create an app, say named `my-name-react-on-rails`:

![06](https://cloud.githubusercontent.com/assets/20628911/17465014/1f29bf3c-5cf4-11e6-869f-4215987ae854.png)

Run this command that looks like this from your new heroku app

    heroku git:remote -a my-name-react-on-rails

Set heroku to use multiple buildpacks:

    heroku buildpacks:set heroku/ruby
    heroku buildpacks:add --index 1 heroku/nodejs


### Swap out sqlite for postgres by doing the following:

Run these two commands:

```
bundle remove sqlite3
bundle add pg
```

![07](https://cloud.githubusercontent.com/assets/20628911/17465015/1f2f4042-5cf4-11e6-8287-2fb077550809.png)

### Replace your `database.yml` file with this (assuming your app name is "ror").

```yml
default: &default
  adapter: postgresql
  username:
  password:
  host: localhost

development:
  <<: *default
  database: ror_development

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: ror_test

production:
  <<: *default
  database: ror_production
```

Then you need to setup postgres so you can run locally:

```
rake db:setup
rake db:migrate
```

![08](https://cloud.githubusercontent.com/assets/20628911/17465016/1f3559f0-5cf4-11e6-8ab4-c5572e4644a5.png)

I'd recommend adding this line to the top of your `routes.rb`. That way, your root page will go to the Hello World page for React On Rails.

```ruby
root "hello_world#index"
```

![09](https://cloud.githubusercontent.com/assets/20628911/17465018/1f3b685e-5cf4-11e6-93f8-105fc48517d0.png)

Next, configure your app for Puma, per the [instructions on Heroku](https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server).

Create `/Procfile`. This is what Heroku uses to start your app.

`Procfile`
```
web: bundle exec puma -C config/puma.rb
```

Note, newer versions of Rails create this file automatically. However, the [docs on Heroku](https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#config) have something a bit different, so please make it conform to those docs. As of 2020-06-04, the docs looked like this:

`config/puma.rb`
```rb
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
```

Next, update your `package.json` to specify the version of yarn and node. Add this section:

```json
  "engines": {
    "node": "13.9.0",
    "yarn": "1.22.4"
  },
```

Then after all changes are done don't forget to commit them with git and finally you can push your app to Heroku!

```
git add -A
git commit -m "Changes for Heroku"
git push heroku master
```

Then run:

```
heroku open
```

and you will see your live app and you can share this URL with your friends. Congrats!

## Turning on Server Rendering

You can turn on server rendering by simply changing the `prerender` option to `true`:

```erb
<%= react_component("HelloWorld", props: @hello_world_props, prerender: true) %>
```

If you want to test this out with HMR, then you also need to add this line to your
`config/intializers/react_on_rails.rb`

```ruby
  config.same_bundle_for_client_and_server = true
```

More likely, you will create a different build file for server rendering. However, if you want to
use the same file from the webpack-dev-server, you'll need to add that line.

Then push to Heroku:

```
git add -A
git commit -m "Enable server rendering"
git push heroku master
```

When you look at the source code for the page (right click, view source in Chrome), you can see the difference between non-server rendering, where your DIV containing your React looks like this:

```html
<div id="HelloWorld-react-component-b7ae1dc6-396c-411d-886a-269633b3f604"></div>
```

versus with server rendering:

```html
<div id="HelloWorld-react-component-d846ce53-3b82-4c4a-8f32-ffc347c8444a"><div data-reactroot=""><h3>Hello, <!-- -->Stranger<!-- -->!</h3><hr/><form><label for="name">Say hello to:</label><input type="text" id="name" value="Stranger"/></form></div></div>
```

For more details on server rendering, see:

  + [Client vs. Server Rendering](./basics/client-vs-server-rendering.md)
  + [React Server Rendering](./basics/react-server-rendering.md)

## Moving from the Rails default `/app/javascript` to the recommended `/client` structure

ShakaCode recommends that you use `/client` for your client side app. This way a non-Rails, front-end developer can be at home just by opening up the `/client` directory.


1. Move the directory:

```
mv app/javascript client
```

2. Edit your `/config/webpacker.yml` file. Change the `default/source_path`:

```yml
  source_path: client
```

## Using HMR with the rails/webpacker setup

Start the app using `foreman start -f Procfile.dev-hmr`.

When you change a JSX file and save, the browser will automatically refresh!

So you get some basics from HMR with no code changes. If you want to go further, take a look at these links:

* https://github.com/rails/webpacker/blob/master/docs/webpack-dev-server.md
* https://webpack.js.org/configuration/dev-server/
* https://webpack.js.org/concepts/hot-module-replacement/

React on Rails will automatically handle disabling server rendering if there is only one bundle file created by the Webpack development server by rails/webpacker.


### Custom IP & PORT setup (Cloud9 example)

In case you are running some custom setup with different IP or PORT you should also edit Procfile.dev. For example to be able to run on free Cloud9 IDE we are putting IP 0.0.0.0 and PORT 8080. The default generated file `Procfile.dev` uses `-p 3000`.

``` Procfile.dev
web: rails s -p 8080 -b 0.0.0.0
```

Then visit https://your-shared-addr.c9users.io:8080/hello_world 

## RubyMine

It's super important to exclude certain directories from RubyMine or else it will slow to a crawl as it tries to parse all the npm files.

* Generated files, per the settings in your `config/webpacker.yml`, which default to `public/packs` and `public/packs-test`
* `node_modules`




## Conclusion

* Browse the docs either on the [gitbook](https://shakacode.gitbooks.io/react-on-rails/content/) or in the [docs directory on github](https://github.com/shakacode/react_on_rails/tree/master/docs)

Feedback is greatly appreciated! As are stars on github! 

If you want personalized help, don't hesitate to get in touch with us at [contact@shakacode.com](mailto:contact@shakacode.com). We offer [React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki) and consulting so you can focus on your app and not on how to make Webpack plus Rails work optimally.
