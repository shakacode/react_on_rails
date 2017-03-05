# Project structure

While React On Rails does not *enforce* a specific project structure, we do *recommend* a standard organization. The more we follow standards as a community, the easier it will be for all of us to move between various Rails projects that include React On Rails.

The best way to understand these standards is to follow this example: [github.com/shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial)

## JavaScript Assets
1. `/client`: All client side JavaScript goes under the `/client` directory. Place all the major domains of the client side app under client.
1. `/client/app`: All application JavaScript. Note the adherence to the [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript#naming-conventions) where we name the files to correspond to exported Objects (PascalCase) or exported functions (camelCase). We don't use dashes or snake_case for JavaScript files, except for possibly some config files.
1. `/client/app/bundles`: Top level of different app domains. Use a name within this directory for you app domains. For example, if you had a domain called `widget-editing`, then you would have: `/client/app/bundles/widget-editing`
1. `/client/app/lib`: Common code for bundles
1. Within each bundle directory (or the lib directory), such as a domain named "comments"
`/client/app/bundles/comments`, use following directory structure:

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
This technique involves customization of the webpack config files to generate CSS, image, and font assets. See [webpack.client.rails.build.config.js](https://github.com/shakacode/react_on_rails/blob/master/spec%2Fdummy%2Fclient%2Fwebpack.client.rails.build.config.js) for an example how to set the webpack part.

#### Directory structure
1. `/client/app/assets`: Assets for CSS for client app.
1. `/client/app/assets/fonts` and `/client/app/assets/styles`: Globally shared assets for styling. Note, most Sass and image assets will be stored next to the JavaScript files.

#### Advantages
1. You can use [CSS modules](https://github.com/css-modules/css-modules), which is super compelling once you seen the benefits.
1. You can do hot reloading of your assets. Thus, you do not have to refresh your web page to see asset change, including changing styles.
1. You can run your client code on a mocked out express server for super fast prototyping. In other words, your client application can somewhat more easily be move to a different application server.

#### Updates 2017-03-04 Regarding CSS handled by Webpack
* See article [Best practices for CSS and CSS Modules using Webpack](https://forum.shakacode.com/t/best-practices-for-css-and-css-modules-using-webpack/799).
* In the near future, all docs will be updated to Webpack v2 and probably recommended to move all CSS handling to Webpack v2 for advanced users. In the near term, global CSS handled by Rails will be best for simple projects. Another data point is that Rails is moving in direction of handling JavaScript, but not CSS, with [Webpacker](https://github.com/rails/webpacker).

