# React on Rails Basic Tutorial

This tutorial setups up a new Rails app with **React on Rails**, demonstrating Rails + React + Redux + Server Rendering. It is updated to 6.7.1.

After finishing this tutorial you will get application that can do the following (live on Heroku):

![example](https://cloud.githubusercontent.com/assets/371302/17368567/111cc722-596b-11e6-9b72-ac5967a60e42.gif)

You can find here:
* [Source code for this app in PR, using the --redux option](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/15) and [for Heroku](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/16).
* [Live on Heroku](https://react-on-rails-redux-generator.herokuapp.com/)

By the time you read this, the latest may have changed. Be sure to check the versions here:

* https://rubygems.org/gems/react_on_rails
* https://www.npmjs.com/package/react-on-rails

_Note: some of the screen images below show the "npm" command. react_on_rails 6.6.0 and greater uses `yarn`._

##Setting up the environment

Trying out **React on Rails** is super easy, so long as you have the basic prerequisites. This includes the basics for Rails 4.x and node version 6+. I recommend `rvm` and `nvm` to install Ruby and Node, and [brew](https://brew.sh/) to install [yarn](https://yarnpkg.com/en/docs/install#mac-tab). Rails can be installed as ordinary gem.

```
nvm install node                # download and install latest stable Node
nvm alias default node          # make it default version
nvm list                        # check

brew install yarn               # you can use other installer if desired

rvm install 2.3.1               # download and install latest stable Ruby (update to exact version)
rvm use 2.3.1 --default         # use it and make it default
rvm list                        # check

gem install rails               # download and install latest stable Rails
gem install foreman             # download and install Foreman
```

Then we need to create a fresh Rails application as following:

```
cd <basic directory where you want to create your new Rails app>

rails new test-react-on-rails       # any name you like

cd test-react-on-rails
```

![01](https://cloud.githubusercontent.com/assets/20628911/17464917/3c29e55a-5cf2-11e6-8754-046ba3ee92d9.png)

Add **React On Rails** gem to your Gemfile (`vim Gemfile` or `nano Gemfile` or in IDE):

```
gem 'react_on_rails', '~>7'         # use latest gem version > 7
```

![02](https://cloud.githubusercontent.com/assets/20628911/17464919/3c2d74c2-5cf2-11e6-8704-a84958832fbb.png)

put everything under git repository (or `rails generate` will not work properly)

```
# Here are git commands to make a new git repo and commit everything
git init
git add -A
git commit -m "Initial commit"
```

update dependencies and generate empty app via `react_on_rails:install` or `react_on_rails:install --redux`. You need to first git commit your files before running the generator, or else it will generate an error.

```
bundle
rails generate react_on_rails:install
bundle && yarn
```

![03](https://cloud.githubusercontent.com/assets/20628911/17464918/3c2c1f00-5cf2-11e6-9525-7b2e15659e01.png)

and then run server with

```
foreman start -f Procfile.dev
```

![04](https://cloud.githubusercontent.com/assets/20628911/17464921/3c2fdb40-5cf2-11e6-9343-6afa53593a70.png)

Visit http://localhost:5000/hello_world and see your **React On Rails** app running!
Note, foreman defaults to PORT 5000 unless you set the value of PORT in your environment.

![05](https://cloud.githubusercontent.com/assets/20628911/17464920/3c2e8ae2-5cf2-11e6-9e30-5ec5f9e2cbc6.png)

### Custom IP & PORT setup (Cloud9 example)

In case you are running some custom setup with different IP or PORT you should also edit Procfile.dev. For example to be able to run on free Cloud9 IDE we are putting IP 0.0.0.0 and PORT 8080. The default generated file `Procfile.dev` uses `-p 3000`.

``` Procfile.dev
web: rails s -p 8080 -b 0.0.0.0
```

Then visit https://your-shared-addr.c9users.io:8080/hello_world 

## RubyMine

It's super important to exclude certain directories from RubyMine or else it will slow to a crawl as it tries to parse all the npm files.

* `app/assets/webpack`
* `client/node_modules`

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

![10](https://cloud.githubusercontent.com/assets/20628911/17465017/1f38fbaa-5cf4-11e6-8d86-a3d91e3878e0.png)

## Links
These are updated for 6.7.1:

* [PR for using the generator with the Redux option](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/15)
* [PR showing the changes to deploy to Heroku](https://github.com/shakacode/react_on_rails-test-new-redux-generation/pull/16)
* [Live on Heroku](https://hello-react-on-rails.herokuapp.com/)

Feedback is greatly appreciated! As are stars on github! If you want personalized help, don't hesitate to get in touch with us at [contact@shakacode.com](mailto:contact@shakacode.com).
