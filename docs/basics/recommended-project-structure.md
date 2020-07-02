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

However, you may wish to move all your client side files to a single directory called something like `/client`.

## Steps to convert from the generator defaults to use a `/client` directory structure.

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
2. Create a `/package.json` that delegates to `/client/package.json`. See the example in [spec/dummy/package.json](../../spec/dummy/package.json).
3. See the webpack configuration in [spec/dummy/client](../../spec/dummy/client) for a webpack configuration example.


## JavaScript Assets
1. `/client`: All client side JavaScript goes under the `/client` directory. Place all the major domains of the client side app under client.
1. `/client/app`: All application JavaScript. Note the adherence to the [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript#naming-conventions) where we name the files to correspond to exported Objects (PascalCase) or exported functions (camelCase). We don't use dashes or snake_case for JavaScript files, except for possibly some config files.
1. `/client/app/bundles`: Top level of different app domains. Use a name within this directory for you app domains. For example, if you had a domain called `widget-editing`, then you would have: `/client/app/bundles/widget-editing`
1. `/client/app/lib`: Common code for bundles
1. Within each bundle directory (or the lib directory), such as a domain named "comments"
`/client/app/bundles/comments`, use following directory structure, if you're using redux. However, with React hooks, this will probably be a bit different:

  * `/actions`: Redux actions.
  * `/components`: "dumb" components (no connections to Redux or Ajax). These get props and can render themselves and children.
  * `/constants`: Constants used by Redux actions and reducers.
  * `/containers`: "smart" components. These components are bound to Redux.
  * `/reducers`: Reducers for redux.
  * `/routes`: Routes for React Router.
  * `/store`: Store, which might be [configured differently for dev vs. production](https://github.com/reactjs/redux/tree/master/examples/real-world/store).
  * `/startup`: Component bindings to stores, with registration of components and stores.
  * `/schemas`: Schemas for AJAX JSON requests and responses, as used by the [Normalizr](https://github.com/gaearon/normalizr) package.

## CSS, Sass, Fonts, and Images
Should you move your styling assets to Webpack? Or stick with the plain Rails asset pipeline. It depends! You have 2 basic choices:

### Simple Rails Way
This isn't really any technique, as you keep handling all your styling assets using Rails standard tools, such as using the [sass-rails gem](https://rubygems.org/gems/sass-rails/versions/5.0.4). Basically, Webpack doesn't get involved with styling. Your Rails layouts just doing the styling the standard Rails way.

#### Advantages
1. Much simpler! There's no changes really from your current processes.

### Using Webpack to Manage Styling Assets
This technique involves customization of the webpack config files to generate CSS, image, and font assets. 

#### Directory structure
1. `/client/app/assets`: Assets for CSS for client app.
1. `/client/app/assets/fonts` and `/client/app/assets/styles`: Globally shared assets for styling. Note, most Sass and image assets will be stored next to the JavaScript files.

#### Advantages
1. You can use [CSS modules](https://github.com/css-modules/css-modules), which is super compelling once you seen the benefits.
1. You can do hot reloading of your assets. Thus, you do not have to refresh your web page to see asset change, including changing styles.
1. You can run your client code on a mocked out express server for super fast prototyping. In other words, your client application can somewhat more easily be move to a different application server.
