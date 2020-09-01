const clientConfig = require('./client');
const serverConfig = require('./server');

const webpackConfig = (envSpecific) => {
  if (envSpecific) {
    envSpecific();
  }

  let result;
  // For HMR, need to separate the the client and server webpack configurations
  if (process.env.WEBPACK_DEV_SERVER || process.env.CLIENT_BUNDLE_ONLY) {
    // eslint-disable-next-line no-console
    console.log('[React on Rails] Creating only the client bundles.');
    result = clientConfig();
  } else if (process.env.SERVER_BUNDLE_ONLY) {
    // eslint-disable-next-line no-console
    console.log('[React on Rails] Creating only the server bundle.');
    result = serverConfig();
  } else {
    // default is the standard client and server build
    // eslint-disable-next-line no-console
    console.log('[React on Rails] Creating both client and server bundles.');
    result = [clientConfig(), serverConfig()];
  }

  // To debug, uncomment next line and inspect "result"
  // debugger
  return result;
};

module.exports = webpackConfig;
