# Recommended Project structure

The React on Rails generator uses the standard `rails/webpacker` convention of this structure:

```yml
app/javascript:
  ├── bundles:
  │   # Logical groups of files that can be used for code splitting
  │   └── hello-world-bundle.js
  ├── packs:
  │   # only webpack entry files here
  │   └── hello-world-bundle.js
```

Per the example repo [shakacode/react_on_rails_demo_ssr_hmr](https://github.com/shakacode/react_on_rails_demo_ssr_hmr),
you should consider keeping your codebase mostly consistent with the defaults for [rails/webpacker](https://github.com/rails/webpacker).

## Steps to convert from the generator defaults to use a `/client` directory for source code 

1. Move the directory:

```
mv app/javascript client
```

2. Edit your `/config/webpacker.yml` file. Change the `default/source_path`:

```yml
  source_path: client
```

## Moving node_modules from `/` to `/client` with a custom webpack setup.

`rails/webpacker` probably doesn't support having your main node_modules directory under `/client`, so only follow these steps if you want to use your own webpack configuration.

1. Move the `/package.json` to `/client/package.json`
2. Create a `/package.json` that delegates to `/client/package.json`. 
   ```
     "scripts": {
       "heroku-postbuild": "cd ./client && yarn"
     },
   ```
3. If your node_modules directory is not at the top level of the Rails project, then you will need to set the
ENV value of WEBPACKER_CONFIG to the location of the `config/webpacker.yml` file per [rails/webpacker PR 2561](https://github.com/rails/webpacker/pull/2561).

## CSS, Sass, Fonts, and Images
Should you move your styling assets to Webpack? Or stick with the plain Rails asset pipeline. It depends!

Here's a good discussion of this option: [Why does Rails 6 include both Webpacker and Sprockets?](https://rossta.net/blog/why-does-rails-install-both-webpacker-and-sprockets.html). 

You have 2 basic choices:

### Simple Rails Way
This isn't really any technique, as you keep handling all your styling assets using Rails standard tools, such as using the [sass-rails gem](https://rubygems.org/gems/sass-rails/versions/5.0.4). Basically, Webpack doesn't get involved with styling. Your Rails layouts just doing the styling the standard Rails way.

#### Advantages to the Simple Rails Way
1. Much simpler! There's no changes really from your current processes.

### Using Webpack to Manage Styling Assets
This technique involves customization of the webpack config files to generate CSS, image, and font assets. 

#### Directory structure
1. `/client/app/assets`: Assets for CSS for client app.
1. `/client/app/assets/fonts` and `/client/app/assets/styles`: Globally shared assets for styling. Note, most Sass and image assets will be stored next to the JavaScript files.

#### Advantages to having Webpack Manage Styles
1. You can use [CSS modules](https://github.com/css-modules/css-modules), which is super compelling once you seen the benefits.
1. You can use CSS in JS.
1. You can do hot reloading of your assets. Thus, you do not have to refresh your web page to see asset change, including changing styles.
