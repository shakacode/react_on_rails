const path = require('path');

module.exports = {
  entry: [
    'es5-shim/es5-shim', // for poltergeist
    'es5-shim/es5-sham', // for poltergeist
    '@babel/polyfill',
    'jquery',
    'jquery-ujs',
    'startup/clientRegistration',
  ],
  output: {
    path: path.resolve(__dirname, '../app/assets/webpack'),
    // Implement chunkhash and bypass the asset pipeline
    // TODO: https://webpack.js.org/guides/code-splitting-libraries/#manifest-file
    filename: 'client.js',
  },
  resolve: {
    modules: [
      path.join(__dirname, 'app'),
      'node_modules',
    ],
    extensions: ['.js', '.jsx'],
  },

  // same issue, for loaders like babel
  resolveLoader: {
    fallback: [path.join(__dirname, 'node_modules')],
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        use: 'babel-loader',
        exclude: /node_modules/,
      },
      {
        test: require.resolve('jquery'),
        use: [
          {
            loader: 'expose-loader',
            options: {
              jQuery: true,
            },
          },
          {
            loader: 'expose-loader',
            options: {
              $: true,
            },
          },
        ],
      },
    ],
  },
};
