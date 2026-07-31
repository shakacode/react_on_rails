// The source code including full typescript support is available at:
// https://github.com/shakacode/react-on-rails-demo-ssr-hmr/blob/master/config/webpack/test.js

const serverClientOrBoth = require('./ServerClientOrBoth')

const testOnly = (_clientWebpackConfig, _serverWebpackConfig) => {
  // place any code here that is for test only
}

module.exports = serverClientOrBoth(testOnly)
