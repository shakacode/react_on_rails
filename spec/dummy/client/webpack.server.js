const path = require('path');

module.exports = {
  context: __dirname,
  entry: [
    "Global"
  ],
  output: {
    path: '../app/assets/javascripts/generated',
    filename: "server.js",
    libaryTarget: "this"
  },
  resolve: {
    root: [path.join(__dirname, 'app')],
    extensions: ['', '.js', '.jsx']
  },
  module: {
    loaders: [
      // require Resolve must go first
      // 1. React must be exposed
      { test: require.resolve("react"), loader: "expose?React" },

      // 2. Expose the components
      { test: require.resolve("./app/HelloString.js"), loader: "expose?HelloString" },
      { test: require.resolve("./app/initters/server.jsx"), loader: "expose?App" },

      { loader: 'babel-loader?stage=0'}
    ]
  }
};
