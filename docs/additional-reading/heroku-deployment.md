# Heroku Deployment
The generator has created the necessary files and gems for deployment to Heroku. If you have installed manually, you will need to provide these files yourself:

+ `Procfile`: used by Heroku and Foreman to start the Puma server
+ `12factor` gem: required by Heroku
+ `'puma'` gem: recommended Heroku webserver
+ `config/puma.rb`: Puma webserver config file
+ `lib/tasks/assets.rake`: This rake task file is provided by the generator regardless of whether the user chose Heroku Deployment as an option. It is highlighted here because it is helpful to understand that this task is what generates your JavaScript bundles in production.

## How to Deploy

React on Rails requires both a ruby environment (for Rails) and a Node environment (for Webpack), so you will need to have Heroku use multiple buildpacks.

Assuming you have downloaded and installed the Heroku command-line utility and have initialized the app, you will need to tell Heroku to use both buildpacks via the command-line:

```
heroku buildpacks:set heroku/ruby
heroku buildpacks:add --index 1 heroku/nodejs
```

For more information, see [Using Multiple Buildpacks for an App](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app)

If for some reason you need custom buildpacks that are not officially supported by Heroku ([see this page](https://devcenter.heroku.com/articles/buildpacks)), we recommend checking out [heroku-buildpack-multi](https://github.com/ddollar/heroku-buildpack-multi).

## Fresh Rails Install

### Swap out sqlite for postgres by doing the following:

1. Delete the line with `sqlite` and replace it with:

```ruby
   gem 'pg'
```

2. Replace your `database.yml` file with this (assuming your app name is "ror")

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

Run:

```
bundle
bin/rake db:migrate
bin/rake db:setup
```



