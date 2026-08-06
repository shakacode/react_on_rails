// The source code including full typescript support is available at:
// https://github.com/shakacode/react-on-rails-demo-ssr-hmr/blob/master/config/webpack/ServerClientOrBoth.js

const clientWebpackConfig = require('./clientWebpackConfig');
const { default: serverWebpackConfig } = require('./serverWebpackConfig');
const rscWebpackConfig = require('./rscWebpackConfig');

const serverClientOrBoth = (envSpecific) => {
  const clientConfig = clientWebpackConfig();
  const serverConfig = serverWebpackConfig();

  const rscConfig = rscWebpackConfig();


  if (envSpecific) {

    envSpecific(clientConfig, serverConfig, rscConfig);

  }

  let result;
  // For HMR, need to separate the the client and server webpack configurations
  if (process.env.WEBPACK_SERVE || process.env.CLIENT_BUNDLE_ONLY) {
    // eslint-disable-next-line no-console
    console.log('[React on Rails] Creating only the client bundles.');
    result = clientConfig;
  } else if (process.env.SERVER_BUNDLE_ONLY) {
    // eslint-disable-next-line no-console
    console.log('[React on Rails] Creating only the server bundle.');
    result = serverConfig;

  } else if (process.env.RSC_BUNDLE_ONLY) {
    // eslint-disable-next-line no-console
    console.log('[React on Rails] Creating only the RSC bundle.');
    result = rscConfig;

  } else {
    // default is the standard client and server build
    // eslint-disable-next-line no-console

    console.log('[React on Rails] Creating client, server, and RSC bundles.');
    result = [clientConfig, serverConfig, rscConfig];

  }

  // To debug, uncomment next line and inspect "result"
  // debugger
  return result;
};

module.exports = serverClientOrBoth;
