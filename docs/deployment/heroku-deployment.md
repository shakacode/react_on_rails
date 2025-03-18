# Heroku Deployment

## Heroku buildpacks

React on Rails requires both a ruby environment (for Rails) and a Node environment (for Webpack), so you will need to have Heroku use multiple buildpacks.

Assuming you have downloaded and installed the Heroku command-line utility and have initialized the app, you will need to tell Heroku to use both buildpacks via the command-line:

```bash
heroku buildpacks:set heroku/ruby
heroku buildpacks:add --index 1 heroku/nodejs
```

For more information, see [Using Multiple Buildpacks for an App](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app)

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
