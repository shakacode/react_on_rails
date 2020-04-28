const builder = require('./webpack/builder');

/*
 * builder config options:
 *
 * developerAids: ?boolean - things like babel type check, react perf tools, pathinfo, etc.
 * extractCss: ?boolean - extract styles out of JS and into bundle CSS files
 * optimize: ?boolean - performance optimizations like uglify, minimize, etc.
 * serverRendering: ?boolean - whether you are server rendering (different entry, env vars)
 * sourceMaps: ?string | false - webpack's 'devtool' setting, renamed for clarity. `false` means turn off source maps at all.
 */
const BUILDER_CONFIGS = {
  dev: {
    developerAids: true,
    extractCss: true,
    sourceMaps: 'eval',
  },

  devServer: {
    developerAids: true,
    extractCss: false,
    sourceMaps: 'eval',
    devServer: true,
  },

  serverBundleDev: {
    developerAids: true,
    serverRendering: true,
    sourceMaps: 'eval',
  },

  prod: {
    extractCss: true,
    optimize: true,
    sourceMaps: 'plugin',
  },

  serverBundleProd: {
    optimize: false,
    serverRendering: true,
    sourceMaps: false,
  },

  rspec: {
    developerAids: true,
    extractCss: true,
    sourceMaps: 'inline-source-map',
  },

  serverBundleRspec: {
    developerAids: true,
    serverRendering: true,
    sourceMaps: 'eval',
  },
};

module.exports = (env = 'prod') => {
  const config = BUILDER_CONFIGS[env];
  if (!config) {
    console.error(`See webpack.config.babel.js. You passed an unsupported config --env "${env}"`);
    process.exit(1);
  }

  return builder(config);
};
