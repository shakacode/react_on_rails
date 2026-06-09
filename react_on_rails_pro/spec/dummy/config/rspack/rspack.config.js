// Set this before loading the shared webpack config because Shakapacker reads
// the assets_bundler setting while its config module is required.
// Rspack CLI invokes this file in a fresh Node process, so webpack.config has
// not already been cached with the default webpack bundler.
const previousAssetsBundler = process.env.SHAKAPACKER_ASSETS_BUNDLER;
process.env.SHAKAPACKER_ASSETS_BUNDLER = 'rspack';

try {
  // eslint-disable-next-line global-require
  module.exports = require('../webpack/webpack.config');
} finally {
  if (previousAssetsBundler === undefined) {
    delete process.env.SHAKAPACKER_ASSETS_BUNDLER;
  } else {
    process.env.SHAKAPACKER_ASSETS_BUNDLER = previousAssetsBundler;
  }
}
