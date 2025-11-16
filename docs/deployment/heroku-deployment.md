# Heroku Deployment

> **Note:** This guide is based on the working tutorial app at [reactrails.com](https://reactrails.com). While the instructions work, some versions referenced are older. For current Heroku best practices with Rails 7, see [Heroku's Rails 7 Guide](https://devcenter.heroku.com/articles/getting-started-with-rails7).

## Create Your Heroku App

_Assuming you can log in to heroku.com and have logged into your shell for Heroku._

1. Visit [https://dashboard.heroku.com/new](https://dashboard.heroku.com/new) and create an app, say named `my-name-react-on-rails`:

![06](https://cloud.githubusercontent.com/assets/20628911/17465014/1f29bf3c-5cf4-11e6-869f-4215987ae854.png)

Run this command that looks like this from your new Heroku app

```bash
heroku git:remote -a my-name-react-on-rails
```

## Heroku buildpacks

React on Rails requires both a ruby environment (for Rails) and a Node environment (for Webpack), so you will need to have Heroku use multiple buildpacks.

Set heroku to use multiple buildpacks:

```bash
heroku buildpacks:set heroku/ruby
heroku buildpacks:add --index 1 heroku/nodejs
```

For more information, see [Using Multiple Buildpacks for an App](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app)

## Swap out sqlite for postgres

Heroku requires your app to use Postgresql. If you have not set up your app
with Postgresql, you need to change your app settings to use this database.

Run the following command (in Rails 6+):

```bash
rails db:system:change --to=postgresql
```

If for any reason you want to do this process manually, run these two commands:

```bash
bundle remove sqlite3
bundle add pg
```

![07](https://cloud.githubusercontent.com/assets/20628911/17465015/1f2f4042-5cf4-11e6-8287-2fb077550809.png)

Now replace your `database.yml` file with this (assuming your app name is "ror").

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

Then you need to set up Postgres so you can run locally:

```bash
rake db:setup
rake db:migrate
```

![08](https://cloud.githubusercontent.com/assets/20628911/17465016/1f3559f0-5cf4-11e6-8ab4-c5572e4644a5.png)

Optionally you can add this line to your `routes.rb`. That way, your root page will go to the Hello World page for React On Rails.

```ruby
root "hello_world#index"
```

![09](https://cloud.githubusercontent.com/assets/20628911/17465018/1f3b685e-5cf4-11e6-93f8-105fc48517d0.png)

## Configure Puma

Next, configure your app for Puma, per the [instructions on Heroku](https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server).

Create `./Procfile` with the following content. This is what Heroku uses to start your app.

```procfile
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

## Specify Node and Yarn versions

Next, update your `package.json` to specify the version of yarn and node. Add this section:

```json
  "engines": {
    "node": "20.0.0",
    "yarn": "1.22.4"
  },
```

## Deploy

Then after all changes are done don't forget to commit them with git and finally, you can push your app to Heroku!

```bash
git add -A
git commit -m "Changes for Heroku"
git push heroku master
```

Then run:

```bash
heroku open
```

and you will see your live app and you can share this URL with your friends. Congrats!

## assets:precompile

### Shakapacker Webpack configuration

Shakapacker hooks up a new `shakapacker:compile` task to `assets:precompile`, which gets run whenever you run `assets:precompile`.
If you are not using Sprockets, `shakapacker:compile` is automatically aliased to `assets:precompile`.

If you're using the standard `shakacode/shakapacker` configuration for Webpack, then `shakacode/shakapacker`
will automatically modify or create an `assets:precompile` task to build your assets.

Alternatively, you can specify `config.build_production_command` to have
`react_on_rails` invoke a command for you during `assets:precompile`.

```bash
config.build_production_command = "RAILS_ENV=production NODE_ENV=production bin/shakapacker"
```

### Consider Removing Shakapacker's clean task

If you are deploying on Heroku, then you don't need Shakapacker's clean task which
might delete files that you need.

```bash
Rake::Task['shakapacker:clean'].clear
```
