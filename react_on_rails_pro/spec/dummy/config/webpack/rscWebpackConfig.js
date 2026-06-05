const { existsSync } = require('fs');
const { dirname, resolve } = require('path');
const { config } = require('shakapacker');
const { default: serverWebpackConfig, extractLoader } = require('./serverWebpackConfig');

const rscReferenceDiscoveryPlugin = () => {
  try {
    // eslint-disable-next-line global-require
    return require('react-on-rails-rsc/RSCReferenceDiscoveryPlugin').RSCReferenceDiscoveryPlugin;
  } catch (error) {
    throw new Error(
      `Missing react-on-rails-rsc/RSCReferenceDiscoveryPlugin. ` +
        `Install react-on-rails-rsc with RSCReferenceDiscoveryPlugin support ` +
        `(check package.json for the required peer range) before running ` +
        `bin/shakapacker-precompile-hook. ${error.message}`,
    );
  }
};

const configureRsc = () => {
  const rscConfig = serverWebpackConfig(true);
  const discoveryBuild = process.env.RSC_REFERENCE_DISCOVERY_BUILD === 'true';

  const sourceEntryDirectory = resolve(config.source_path, config.source_entry_path);
  const serverComponentRegistrationEntry = resolve(
    dirname(sourceEntryDirectory),
    'generated/server-component-registration-entry.js',
  );

  if (discoveryBuild) {
    if (!existsSync(serverComponentRegistrationEntry)) {
      throw new Error(
        `Missing server component registration entry: ${serverComponentRegistrationEntry}. ` +
          `Run bin/shakapacker-precompile-hook before bin/shakapacker.`,
      );
    }

    rscConfig.entry = {
      'rsc-reference-discovery': serverComponentRegistrationEntry,
    };
  } else {
    // Update the entry name to be `rsc-bundle` instead of `server-bundle`
    rscConfig.entry = {
      'rsc-bundle': rscConfig.entry['server-bundle'],
    };
  }

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
  const rscAliases = { ...(rscConfig.resolve?.alias || {}) };
  delete rscAliases['react-on-rails-pro$'];
  // Drop the client-only StrictMode shim so RSC imports of `react-on-rails-pro/client` don't pull
  // in a browser entry point inside the React server bundle.
  delete rscAliases['react-on-rails-pro/client$'];
  rscConfig.resolve = {
    ...rscConfig.resolve,
    conditionNames: ['react-server', '...'],
    alias: {
      ...rscAliases,
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

  if (discoveryBuild) {
    rscConfig.output.filename = 'rsc-reference-discovery.js';
    const RSCReferenceDiscoveryPlugin = rscReferenceDiscoveryPlugin();
    rscConfig.plugins.push(new RSCReferenceDiscoveryPlugin());
  } else {
    // Update the output bundle name to be `rsc-bundle.js` instead of `server-bundle.js`
    rscConfig.output.filename = 'rsc-bundle.js';
  }
  return rscConfig;
};

module.exports = configureRsc;
