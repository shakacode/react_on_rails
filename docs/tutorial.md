# Tutorial for React on Rails


This tutorial setups up a new Rails app with **React on Rails**, demonstrating Rails + React + Redux + Server Rendering.

You can find:

* [Source code for this sample app](https://github.com/justin808/test-react-on-rails-3) (for an older version)
* [Live on Heroku](https://shakacode-react-on-rails.herokuapp.com/hello_world)

By the time you read this, the latest may have changed. Be sure to check the versions here:

* https://rubygems.org/gems/react_on_rails
* https://www.npmjs.com/package/react-on-rails

##Seting up environment

Trying out **React on Rails** is super easy, so long as you have the basic prerequisites. This includes the basics for Rails 4.x and node version 5+. I recommend `rvm` and `nvm` to install Ruby and Node. Rails can be installed as ordinary gem.

```
nvm install 5.12            # download and install latest stable Node
nvm alias default 5.12      # make 5.12 default version
nvm list                    # check

rvm install 2.3.1           # download and install latest stable Ruby
rvm list                    # check

gem install rails           # download and install latest stable Rails
```

Than we need to do normal blank Rails app as following:

```
cd <basic directory where you want to create your new Rails app>

rails new test-react-on-rails       # any name you like

cd test-react-on-rails
```

Add **React On Rails** gem to your Gemfile (`vim Gemfile` or `nano Gemfile` or in IDE):

```
gem 'react_on_rails', '~>6'         # use latest gem version > 6
```

put everything under git repository (or rails generate will not work properly)

```
# git command to make a new git repo and commit everything
git init
git add -A
git commit -m "First commit"
```

update dependencies and generate empty app via `react_on_rails:install`. If you haven't done first git commit it will generate error and you just need to commit.

```
bundle
rails generate react_on_rails:install
bundle && npm install
```

and than run server with

```
foreman start -f Procfile.dev
```

Visit http://localhost:3000/hello_world and see your **React On Rails** app running!

### Custom IP & PORT setup (Cloud9 example)

In case you are running some custom setup with different IP or PORT you should also edit Procfile.dev. For example to be able to run on free Cloud9 IDE we are putting IP 0.0.0.0 and PORT 8080

``` Procfile.dev
web: rails s -p 8080 -b 0.0.0.0
```

Than visit  https://your-shared-addr.c9users.io:8080/hello_world 

## RubyMine

It's super important to exclude certain directories from RubyMine or else it will slow to a crawl as it tries to parse all the npm files.

* `app/assets/webpack`
* `client/node_modules`

## Deploying to Heroku

### Create Your Heroku App
*Assuming you can login to heroku.com and have logged into to your shell for heroku.*

1. Visit https://dashboard.heroku.com/new and create an app, say named `my-name-react-on-rails`:

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
bin/rake db:migrate
bin/rake db:setup
```

I'd recommend adding this line to the top of your `routes.rb`. That way, your root page will go to the Hello World page for React On Rails.

```ruby
root "hello_world#index"
```

You can see the changes [here on github](https://github.com/justin808/test-react-on-rails-3/commit/09909433c186566a53f611e8b1cfeca3238f5266).

Then push your app to Heroku!

    git push heroku master

Here's mine:

* [Source code for this sample app](https://github.com/justin808/test-react-on-rails-3)
* [Live on Heroku](https://shakacode-react-on-rails.herokuapp.com/hello_world)

Feedback is greatly appreciated! As are stars on github!
