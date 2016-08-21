# Heroku Deployment
The generator has created the necessary files and gems for deployment to Heroku. If you have installed manually, you will need to provide these files yourself:

+ `Procfile`: used by Heroku and Foreman to start the Puma server
+ `12factor` gem: required by Heroku
+ `'puma'` gem: recommended Heroku webserver
+ `config/puma.rb`: Puma webserver config file
+ `lib/tasks/assets.rake`: This rake task file is provided by the generator regardless of whether the user chose Heroku Deployment as an option. It is highlighted here because it is helpful to understand that this task is what generates your JavaScript bundles in production. Previously, users of this gem had to create a file `lib/tasks/assets.rake` to modify the Rails precompile task to deploy assets for production. However, we add this automatically in newer versions of React on Rails. If you need to customize this file, see [lib/tasks/assets.rake from React on Rails](https://github.com/shakacode/react_on_rails/blob/master/lib/tasks/assets.rake) as an example.

## More details on precompilation using webpack to create JavaScript assets
This is how the rake task gets modified. You should be able to call `clear_prerequisites` and setup your own custom precompile if needed.
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

## Caching Node Modules
By default Heroku will cache the root `node_modules` directory between deploys but since we're installing in `client/node_modules` you'll need to add the following line to the `package.json` in your root directory (otherwise you'll have to sit through a full `npm install` on each deploy):

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

If for some reason you need custom buildpacks that are not officially supported by Heroku ([see this page](https://devcenter.heroku.com/articles/buildpacks)), we recommend checking out [heroku-buildpack-multi](https://github.com/ddollar/heroku-buildpack-multi).

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
bin/rake db:migrate
bin/rake db:setup
```
