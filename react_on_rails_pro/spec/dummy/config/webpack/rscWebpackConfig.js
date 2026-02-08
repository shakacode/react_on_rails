const { resolve } = require('path');
const { default: serverWebpackConfig, extractLoader } = require('./serverWebpackConfig');

const configureRsc = () => {
  const rscConfig = serverWebpackConfig(true);

  // Update the entry name to be `rsc-bundle` instead of `server-bundle`
  const rscEntry = {
    'rsc-bundle': rscConfig.entry['server-bundle'],
  };
  rscConfig.entry = rscEntry;

  // Add the RSC loader before the babel loader
  const { rules } = rscConfig.module;
  rules.forEach((rule) => {
    if (Array.isArray(rule.use)) {
      // Ensure this loader runs before the JS loader (Babel loader in this case) to properly exclude client components from the RSC bundle.
      // If your project uses a different JS loader, insert it before that loader instead.
      const babelLoader = extractLoader(rule, 'babel-loader');
      if (babelLoader) {
        rule.use.push({
          loader: 'react-on-rails-rsc/WebpackLoader',
        });
      }
    }
  });

  // Add the `react-server` condition to the resolve config
  // This condition is used by React and React on Rails to know that this bundle is a React Server Component bundle
  // The `...` tells webpack to retain the default Webpack conditions (In this case will keep the `node` condition because the bundle targets node)
  //
  // IMPORTANT: The alias.js file sets React aliases to directory paths for deduplication.
  // Directory-path aliases bypass webpack's conditionNames/exports resolution.
  // For the RSC bundle, we must override these aliases to point to the react-server
  // entry files directly, so that React's server-specific code is bundled correctly.
  const rootNodeModules = resolve(__dirname, '..', '..', '..', '..', '..', 'node_modules');
  rscConfig.resolve = {
    ...rscConfig.resolve,
    conditionNames: ['react-server', '...'],
    alias: {
      ...rscConfig.resolve?.alias,
      // Override React aliases to use react-server entry points
      react: resolve(rootNodeModules, 'react', 'react.react-server.js'),
      'react/jsx-runtime': resolve(rootNodeModules, 'react', 'jsx-runtime.react-server.js'),
      'react/jsx-dev-runtime': resolve(rootNodeModules, 'react', 'jsx-dev-runtime.react-server.js'),
      // Ignore import of react-dom/server in rsc bundle
      // This module is not needed to generate the rsc payload, it's rendered using `react-on-rails-rsc`
      // Not removing it will cause a runtime error
      'react-dom/server': false,
    },
  };

  // Update the output bundle name to be `rsc-bundle.js` instead of `server-bundle.js`
  rscConfig.output.filename = 'rsc-bundle.js';
  return rscConfig;
};

module.exports = configureRsc;
