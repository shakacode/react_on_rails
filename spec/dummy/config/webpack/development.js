process.env.NODE_ENV = process.env.NODE_ENV || 'development';

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

// For HMR, we need to separate the the client and server webpack configurations
if (process.env.WEBPACK_DEV_SERVER) {
  module.exports = clientConfig;
} else if (process.env.SERVER_BUNDLE_ONLY) {
  module.exports = serverConfig;
} else {
  module.exports = [clientConfig, serverConfig];
}
