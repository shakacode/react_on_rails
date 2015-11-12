# Heroku Deployment
The generator has created the necessary files and gems for deployment to Heroku. If you have installed manually, you will need to provide these files yourself:

+ `Procfile`: used by Heroku and Foreman to start the server
+ `.buildpacks`: used to install Ruby and Node environments
+ `12factor` gem: required by Heroku
+ `lib/tasks/assets.rake`: rake task that generates your JavaScript bundles for production.

## How to Deploy

React on Rails requires both a ruby environment (for Rails) and a Node environment (for Webpack), so you will need to have Heroku use multiple buildpacks. Currently, we would suggest using [DDollar's Heroku Buildpack Multi](https://github.com/ddollar/heroku-buildpack-multi).

Assuming you have downloaded and installed the Heroku command-line utility and have initialized the app, you will need to tell Heroku to use Heroku Buildpack Multi via the command-line:

```
heroku buildpacks:set https://github.com/heroku/heroku-buildpack-multi
```

Heroku will now be able to use the multiple buildpacks specified in `.buildpacks`. 

Note, an alternative approach is to use the [Heroku Toolbelt to set buildpacks](https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app).
