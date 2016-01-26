# Project structure

While React On Rails does not *enforce* a specific project structure, we do *recommend* a standard organization. The more we follow standards as a community, the easier it will be for all of us to move between various Rails projects that include React On Rails.

1. `/client`: All client side JavaScript goes under the `/client` directory. Place all the major domains of the client side app under client.
1. `/client/app`: All application JavaScript. Note the adherence to the [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript#naming-conventions) where we name the files to correspond to exported Objects (PascalCase) or exported functions (camelCase). We don't use dashes or snake_case for JavaScript files, except for possibly some config files.
1. `/client/app/bundles`: Top level of different app domains. Use a name within this directory for you app domains. For example, if you had a domain called `widget-editing`, then you would have: `/client/app/bundles/widget-editing`
1. `/client/app/lib`: Common code for bundles
1. Within each bundle directory (or the lib directory), such as a domain named "comments"
`/client/app/bundle/comments`, use following directory structure:

  * `/actions`: Redux actions.
  * `/components`: "dumb" components (no connections to Redux or Ajax). These get props and can render themselves and children.
  * `/constants`: Constants used by Redux actions and reducers.
  * `/containers`: "smart" components. These components are bound to Redux.
  * `/reducers`: Reducers for redux.
  * `/routes`: Routes for React Router.
  * `/store`: Store, which might be [configured differently for dev vs. production](https://github.com/rackt/redux/tree/master/examples/real-world/store).
  * `/startup`: Component bindings to stores, with registration of components and stores.
  * `/schemas`: Schemas for AJAX JSON requests and responses, as used by the [Normalizr](https://github.com/gaearon/normalizr) package.
1. `/client/app/assets`: Assets for CSS for client app.
1. `/client/app/assets/fonts` and `/client/app/assets/styles`: Globally shared assets for styling. Note, most Sass and image assets will be stored next to the JavaScript files.
