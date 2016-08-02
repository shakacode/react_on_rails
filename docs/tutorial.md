# Tutorial for React on Rails


This tutorial setups up a new Rails app with **React on Rails**, demonstrating Rails + React + Redux + Server Rendering.

You can find:

* [Source code for this sample app](https://github.com/justin808/test-react-on-rails-3) (for an older version)
* [Live on Heroku](https://shakacode-react-on-rails.herokuapp.com/hello_world)

By the time you read this, the latest may have changed. Be sure to check the versions here:

* https://rubygems.org/gems/react_on_rails
* https://www.npmjs.com/package/react-on-rails

##Seting up environment

Trying out **React on Rails** is super easy, so long as you have the basic prerequisites. This includes the basics for Rails 4.x and node version 5+. I recommend `rvm` and `nvm` to install Ruby and Node.

```
# update to latest stable version number of Node
nvm install 5.12
nvm list

# update to latest stable version number of Ruby
rvm install 2.3.1
rvm list
```

Than we need to do normal blank Rails app as following:

```
cd <basic directory where you want to create your new Rails app>

# any name you like
rails new test-react-on-rails

cd test-react-on-rails

# git command to make a new git repo and commit everything
git init
git add -A
git commit -m "First commit"
```

Add **React On Rails** gem to your Gemfile (`vim Gemfile` or `nano Gemfile`):

```
gem 'react_on_rails', '~>6'
```

update dependencies and generate empty app via `react_on_rails:install`. If you haven't done first git commit it will generate error and you just need to commit.

```
bundle
rails generate react_on_rails:install
bundle && npm install
```

and run server with

```
foreman start -f Procfile.dev
```

Visit http://localhost:5000/hello_world and see your **React On Rails** app running!

With this setup, you can make changes to your JS or CSS and the browser will hot reload the changes (no page refresh required).

I'm going to add this line to client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx:

```html
<h1>Welcome to React On Rails!</h1>
```

<img src="http://forum.shakacode.com/uploads/default/original/1X/d20719a52541e95ddd968a95192d3247369c3bf6.png" width="498" height="500">

If you save the browser will be updated automatically.

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
