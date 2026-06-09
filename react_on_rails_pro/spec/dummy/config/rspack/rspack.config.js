// Set this before loading the shared webpack config because Shakapacker reads
// the assets_bundler setting while its config module is required.
process.env.SHAKAPACKER_ASSETS_BUNDLER = 'rspack';

module.exports = require('../webpack/webpack.config');
