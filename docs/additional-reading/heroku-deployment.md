# Heroku Deployment
The generator has created the necessary files and gems for deployment to Heroku. If you have installed manually, you will need to provide these files yourself:

+ `Procfile`: used by Heroku and Foreman to start the Puma server
+ `12factor` gem: required by Heroku if using a version before Rails 5 (see their [README](https://github.com/heroku/rails_12factor#rails-5) for more information if upgrading from a lower version)
+ `'puma'` gem: recommended Heroku webserver
+ `config/puma.rb`: Puma webserver config file
+ `/package.json`: Top level package.json which must contain `"scripts": { "postinstall": "cd client && npm install" }`

If you want to see an updated example deployed to Heroku, please visit the [github.com/shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial).

## More details on precompilation using webpack to create JavaScript assets
This is how the `assets:precompile` rake task gets modified by `react_on_rails`. You should be able to call `clear_prerequisites` and setup your own custom precompile if needed.
```ruby
# These tasks run as pre-requisites of assets:precompile.
# Note, it's not possible to refer to ReactOnRails configuration values at this point.
Rake::Task["assets:precompile"]
    .clear_prerequisites
    .enhance([:environment, "react_on_rails:assets:compile_environment"])
    .enhance do
      Rake::Task["react_on_rails:assets:symlink_non_digested_assets"].invoke
      Rake::Task["react_on_rails:assets:delete_broken_symlinks"].invoke
    end
```    

For an example of how to do this, see the [dummy app](https://github.com/shakacode/react_on_rails/blob/master/spec/dummy/lib/tasks/assets.rake).

## Caching Node Modules
By default Heroku will cache the root `node_modules` directory between deploys but since we're installing in `client/node_modules` you'll need to add the following line to the `package.json` in your root directory (otherwise you'll have to sit through a full `yarn` on each deploy):

```js
"cacheDirectories": [
  "node_modules",
  "client/node_modules"
],
```

## How to Deploy

React on Rails requires both a ruby environment (for Rails) and a Node environment (for Webpack), so you will need to have Heroku use multiple buildpacks.

Assuming you have downloaded and installed the Heroku command-line utility and have initialized the app, you will need to tell Heroku to use both buildpacks via the command-line:

```
heroku buildpacks:set heroku/ruby
heroku buildpacks:add --index 1 heroku/nodejs
```

For more information, see [Using Multiple Buildpacks for an App](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app)

## Fresh Rails Install

### Swap out sqlite for postgres by doing the following:

#### 1. Delete the line with `sqlite` and replace it with:

```ruby
   gem 'pg'
```

#### 2. Replace your `database.yml` file with this (assuming your app name is "ror")

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
bin/rake db:setup
bin/rake db:migrate
```
