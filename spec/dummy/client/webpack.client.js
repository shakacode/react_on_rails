const path = require('path');

module.exports = {
  entry: {
    app: './app/initters/client.jsx'
  },
  output: {
    path: '../app/assets/javascripts/generated',
    filename: "client.js"
  },
  resolve: {
    extensions: ['', '.js', '.jsx']
  },
  module: {
    loaders: [
      { loader: 'babel-loader?stage=0' }
    ]
  }
};
