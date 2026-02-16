// React Server Components webpack configuration
// This creates the RSC bundle based on the server webpack config
// See: https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/

const serverWebpackModule = require('./serverWebpackConfig');

// Backward compatibility:
// - New Pro config exports: { default: configureServer, extractLoader }
// - Legacy config exports: module.exports = configureServer
const serverWebpackConfig = serverWebpackModule.default || serverWebpackModule;
const extractLoader = serverWebpackModule.extractLoader || ((rule, loaderName) => {
  if (!Array.isArray(rule.use)) return null;
  return rule.use.find((item) => {
    const testValue = typeof item === 'string' ? item : item.loader;
    return testValue && testValue.includes(loaderName);
  });
});

const configureRsc = () => {
  // Pass true to skip RSCWebpackPlugin - RSC bundle doesn't need it
  const rscConfig = serverWebpackConfig(true);

  // Update the entry name to be `rsc-bundle` instead of `server-bundle`
  const rscEntry = {
    'rsc-bundle': rscConfig.entry['server-bundle'],
  };
  rscConfig.entry = rscEntry;

  // Add the RSC loader before the JS loader (babel-loader or swc-loader)
  // This loader properly excludes client components from the RSC bundle
  const { rules } = rscConfig.module;
  rules.forEach((rule) => {
    if (Array.isArray(rule.use)) {
      // Find the JS loader (could be babel-loader or swc-loader depending on configuration)
      const jsLoader = extractLoader(rule, 'babel-loader') || extractLoader(rule, 'swc-loader');
      if (jsLoader) {
        rule.use.push({
          loader: 'react-on-rails-rsc/WebpackLoader',
        });
      }
    }
  });

  // Add the `react-server` condition to the resolve config
  // This condition is used by React and React on Rails to identify RSC bundles
  // The `...` tells webpack to retain the default conditions (e.g., `node` for server target)
  rscConfig.resolve = {
    ...rscConfig.resolve,
    conditionNames: ['react-server', '...'],
    alias: {
      ...rscConfig.resolve?.alias,
      // Ignore react-dom/server in RSC bundle - it's not needed for RSC payload generation
      // Not removing it will cause a runtime error
      'react-dom/server': false,
    },
  };

  // Update the output bundle name to be `rsc-bundle.js` instead of `server-bundle.js`
  rscConfig.output.filename = 'rsc-bundle.js';

  return rscConfig;
};

module.exports = configureRsc;
