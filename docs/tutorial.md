# React on Rails Basic Tutorial

This tutorial guides you through setting up a new or existing Rails app with **React on Rails**, demonstrating Rails + React + Redux + Server Rendering. It is updated to 10.0.2.

After finishing this tutorial you will get an application that can do the following (live on Heroku):

![example](https://cloud.githubusercontent.com/assets/371302/17368567/111cc722-596b-11e6-9b72-ac5967a60e42.gif)

You can find here:
* [Source code for this app in PR, using the --redux option](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/17) and [for Heroku](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/18).
* [Live on Heroku](https://react-on-rails-redux-gen-8-0-0.herokuapp.com/)

By the time you read this, the latest may have changed. Be sure to check the versions here:

* https://rubygems.org/gems/react_on_rails
* https://www.npmjs.com/package/react-on-rails

_Note: some of the screen images below show the "npm" command. react_on_rails 6.6.0 and greater uses `yarn`._

## Setting up the environment

Trying out **React on Rails** is super easy, so long as you have the basic prerequisites. This includes the basics for Rails 5.x and node version 6+. I recommend `rvm` and `nvm` to install Ruby and Node, and [brew](https://brew.sh/) to install [yarn](https://yarnpkg.com/en/docs/install#mac-tab). Rails can be installed as an ordinary gem.

```
nvm install node                # download and install latest stable Node
nvm alias default node          # make it default version
nvm list                        # check

brew install yarn               # you can use other installer if desired

rvm install 2.4.1               # download and install latest stable Ruby (update to exact version)
rvm use 2.4.1 --default         # use it and make it default
rvm list                        # check

gem install rails               # download and install latest stable Rails
gem install foreman             # download and install Foreman
```

Then we need to create a fresh Rails application with webpacker react support as following.

First be sure to run `rails -v` and check you are using Rails 5.1.3 or above. If you are using an older version of Rails, you'll need to install webpacker with react per the instructions [here](https://github.com/rails/webpacker).

```
cd <directory where you want to create your new Rails app>

# any name you like for the rails app
rails new test-react-on-rails --webpack=react 

cd test-react-on-rails
```

Note: if you are installing React On Rails in an existing app or an app that uses Rails pre 5.1.3, you will need to run these two commands as well:

```
bundle exec rails webpacker:install
bundle exec rails webpacker:install:react
```

Add the **React On Rails** gem to your Gemfile:

```
gem 'react_on_rails', '10.0.2'         # prefer exact gem version to match npm version
```

Note: Latest released React On Rails version is considered stable. Please use the latest version to ensure you get all the security patches and the best support.

Run `bundle` and commit the git repository (or `rails generate` will not work properly)


```
bundle

# Here are git commands to make a new git repo and commit everything.
# Newer versions of Rails create the git repo by default.
git add -A
git commit -m "Initial commit"
```

Install React on Rails: `rails generate react_on_rails:install` or `rails generate react_on_rails:install --redux`. You need to first git commit your files before running the generator, or else it will generate an error.

```
rails generate react_on_rails:install
bundle && yarn
```

and then run server with

```
foreman start -f Procfile.dev
```

Visit http://localhost:3000/hello_world and see your **React On Rails** app running!
Note, foreman defaults to PORT 5000 unless you set the value of PORT in your environment or in the Procfile.

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

## Deploying to Heroku

### Create Your Heroku App
*Assuming you can login to heroku.com and have logged into to your shell for heroku.*

1. Visit https://dashboard.heroku.com/new and create an app, say named `my-name-react-on-rails`:

![06](https://cloud.githubusercontent.com/assets/20628911/17465014/1f29bf3c-5cf4-11e6-869f-4215987ae854.png)

Run this command that looks like this from your new heroku app

    heroku git:remote -a my-name-react-on-rails

Set heroku to use multiple buildpacks:

    heroku buildpacks:set heroku/ruby
    heroku buildpacks:add --index 1 heroku/nodejs


### Swap out sqlite for postgres by doing the following:

1. Delete the line with `sqlite` and replace it with:

```ruby
   gem 'pg'
```

![07](https://cloud.githubusercontent.com/assets/20628911/17465015/1f2f4042-5cf4-11e6-8287-2fb077550809.png)


2. Replace your `database.yml` file with this (assuming your app name is "ror").

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
bundle
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

`Procfile`
```
web: bundle exec puma -C config/puma.rb
```

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

Then after all changes are done don't forget to commit them with git and finally you can push your app to Heroku!

```
git add -A
git commit -m "Latest changes"
git push heroku master
```

Feedback is greatly appreciated! As are stars on github! If you want personalized help, don't hesitate to get in touch with us at [contact@shakacode.com](mailto:contact@shakacode.com).
