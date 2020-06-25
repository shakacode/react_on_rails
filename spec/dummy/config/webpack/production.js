process.env.NODE_ENV = process.env.NODE_ENV || 'production';

// We need to compile both our development JS (for serving to the client) and our server JS
// (for SSR of React components). This is easy enough as we can export arrays of webpack configs.
const clientEnvironment = require('./client');
const serverConfig = require('./server');
const merge = require('webpack-merge');

const optimization = {
  splitChunks: {
    chunks: 'async',
    cacheGroups: {
      vendor: {
        chunks: 'async',
        name: 'vendor',
        test: 'vendor',
        enforce: true,
      },
    },
  },
};

clientEnvironment.splitChunks((config) => Object.assign({}, config, { optimization: optimization }));

const clientConfig = clientEnvironment.toWebpackConfig();

module.exports = [clientConfig, serverConfig];
