# Recommended Project structure

The React on Rails generator uses the standard Shakapacker convention of this structure:

```text
app/javascript:
  ├── bundles:
  │   # Logical groups of files that can be used for code splitting
  │   └── hello-world-bundle.js
  ├── packs:
  │   # only Webpack entry files here
  │   └── hello-world-bundle.js
```

Per the example repo [shakacode/react_on_rails_demo_ssr_hmr](https://github.com/shakacode/react_on_rails_demo_ssr_hmr),
you should consider keeping your codebase mostly consistent with the defaults for [Shakapacker](https://github.com/shakacode/shakapacker).

## Steps to convert from the generator defaults to use a `/client` directory for source code

1. Move the directory:

```bash
mv app/javascript client
```

2. Edit your `/config/shakapacker.yml` file. Change the `default/source_path`:

```yml
source_path: client
```

## Moving node_modules from `/` to `/client` with a custom Webpack setup

Shakapacker probably doesn't support having your main `node_modules` directory under `/client`, so only follow these steps if you want to use your own Webpack configuration.

1. Move the `/package.json` to `/client/package.json`
2. Create a `/package.json` that delegates to `/client/package.json`.
   ```json
     "scripts": {
       "heroku-postbuild": "cd ./client && yarn"
     },
   ```
3. If your `node_modules` directory is not at the top level of the Rails project, then you will need to set the
   ENV value of `SHAKAPACKER_CONFIG` to the location of the `config/shakapacker.yml` file per [rails/webpacker PR 2561](https://github.com/rails/webpacker/pull/2561). (Notice the change of spelling from Webpacker to Shakapacker)

## CSS, Sass, Fonts, and Images

Should you move your styling assets to Webpack, or stick with the plain Rails asset pipeline? It depends!

Here's a good discussion of this option: [Why does Rails 6 include both Webpacker and Sprockets?](https://rossta.net/blog/why-does-rails-install-both-webpacker-and-sprockets.html).

You have 2 basic choices:

### Simple Rails Way

This isn't really a technique, as you keep handling all your styling assets using Rails standard tools, such as using the [sass-rails gem](https://rubygems.org/gems/sass-rails/versions/5.0.4). Basically, Webpack doesn't get involved with styling. Your Rails layouts just continue doing the styling the standard Rails way.

#### Advantages to the Simple Rails Way

1. Much simpler! There's no change from your current processes.

### Using Webpack to Manage Styling Assets

This technique involves customization of the Webpack config files to generate CSS, image, and font assets.

#### Directory structure

1. `/client/app/assets`: Assets for CSS for client app.
1. `/client/app/assets/fonts` and `/client/app/assets/styles`: Globally shared assets for styling. Note, most Sass and image assets will be stored next to the JavaScript files.

#### Advantages to having Webpack Manage Styles

1. You can use [CSS modules](https://github.com/css-modules/css-modules), which is super compelling once you see the benefits.
1. You can use CSS in JS.
1. You can do hot reloading of your assets. Thus, you do not have to refresh your web page to see asset change, including changing styles.
