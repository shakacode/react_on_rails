# Heroku Deployment
## Heroku buildpacks

React on Rails requires both a ruby environment (for Rails) and a Node environment (for Webpack), so you will need to have Heroku use multiple buildpacks.

Assuming you have downloaded and installed the Heroku command-line utility and have initialized the app, you will need to tell Heroku to use both buildpacks via the command-line:

```
heroku buildpacks:set heroku/ruby
heroku buildpacks:add --index 1 heroku/nodejs
```

For more information, see [Using Multiple Buildpacks for an App](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app)

## assets:precompile

### rails/webpacker webpack configuration
If you're using the standard rails/webpacker configuration of webpack, then rails/webpacker
will automatically modify or create an assets:precompile task to build your assets. 

Alternatively, you can specify `config.build_production_command` to have
react_on_rails invoke a command for you during assets:precompile.

```
config.build_production_command = "RAILS_ENV=production bin/webpack"
```

### Consider Removing Webpacker's clean task

If you are deploying on Heroku, then you don't need Webpacker's clean task which
might delete files that you need.

```
Rake::Task['webpacker:clean'].clear
```
