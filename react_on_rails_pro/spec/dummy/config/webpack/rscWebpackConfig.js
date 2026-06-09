const { existsSync, statSync } = require('fs');
const { basename, dirname, isAbsolute, relative, resolve } = require('path');
const { config } = require('shakapacker');
const { default: serverWebpackConfig, extractLoader } = require('./serverWebpackConfig');

const reactPackageRoot = dirname(require.resolve('react/package.json'));
// React 19+ ships these react-server entry files alongside the standard entries.
const resolveReactServerEntry = (entryFilename) => {
  const entryPath = resolve(reactPackageRoot, entryFilename);
  if (!existsSync(entryPath)) {
    throw new Error(
      `Expected React server entry "${entryFilename}" at "${entryPath}". ` +
        'React package layout changed; update the RSC webpack aliases.',
    );
  }
  return entryPath;
};

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
  const defaultServerComponentRegistrationEntry = resolve(
    dirname(sourceEntryDirectory),
    'generated/server-component-registration-entry.js',
  );
  const expectedServerComponentRegistrationEntry = 'server-component-registration-entry.js';
  const excludedRegistrationEntryPathComponents = [
    '.git',
    'log',
    'node_modules',
    'public',
    'spec',
    'test',
    'tmp',
    'vendor',
  ];
  const registrationEntryPathComponents = (entryPath) => {
    const rootRelativePath = relative(process.cwd(), entryPath);
    const scopedPath =
      rootRelativePath &&
      rootRelativePath !== '..' &&
      !rootRelativePath.startsWith('../') &&
      !rootRelativePath.startsWith('..\\') &&
      !isAbsolute(rootRelativePath)
        ? rootRelativePath
        : entryPath;

    return scopedPath.split(/[\\/]+/).filter(Boolean);
  };
  const validServerComponentRegistrationEntry = (entryPath) => {
    if (basename(entryPath) !== expectedServerComponentRegistrationEntry) return false;
    if (
      registrationEntryPathComponents(entryPath).some((component) =>
        excludedRegistrationEntryPathComponents.includes(component),
      )
    ) {
      return false;
    }

    try {
      return statSync(entryPath).isFile();
    } catch {
      return false;
    }
  };
  const serverComponentRegistrationEntry = (() => {
    const configuredRegistrationEntry = process.env.REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH;
    if (configuredRegistrationEntry) {
      const configuredEntry = resolve(configuredRegistrationEntry);
      if (validServerComponentRegistrationEntry(configuredEntry)) return configuredEntry;
    }

    return defaultServerComponentRegistrationEntry;
  })();

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

  // Add the `react-server` condition to the resolve config.
  // This condition is used by React and React on Rails to identify RSC bundles.
  // The `...` tells webpack to retain the default conditions (e.g., `node` for server target).
  const rscAliases = { ...(rscConfig.resolve?.alias || {}) };
  delete rscAliases['react-on-rails-pro$'];
  // Strip client-only StrictMode shim so RSC imports of `react-on-rails-pro/client`
  // do not pull a browser entry point into the React server bundle.
  delete rscAliases['react-on-rails-pro/client$'];
  delete rscAliases.react;
  delete rscAliases.react$;
  delete rscAliases['react/jsx-runtime'];
  delete rscAliases['react/jsx-runtime$'];
  delete rscAliases['react/jsx-dev-runtime'];
  delete rscAliases['react/jsx-dev-runtime$'];
  delete rscAliases['react-dom/server'];
  delete rscAliases['react-dom/server$'];

  rscConfig.resolve = {
    ...rscConfig.resolve,
    conditionNames: ['react-server', '...'],
    alias: {
      ...rscAliases,
      // Canonicalize RSC-bundle React imports to one React server package instance.
      // Without these aliases, symlinked/hoisted packages can bundle one React copy
      // for react-on-rails-rsc and another for app Server Components. React.cache()
      // then sees no active RSC dispatcher and silently skips request-local dedupe.
      react$: resolveReactServerEntry('react.react-server.js'),
      'react/jsx-runtime$': resolveReactServerEntry('jsx-runtime.react-server.js'),
      'react/jsx-dev-runtime$': resolveReactServerEntry('jsx-dev-runtime.react-server.js'),
      // Ignore react-dom/server in RSC bundle - it's not needed for RSC payload generation.
      // Not removing it will cause a runtime error.
      // Prefix-match false covers exact and subpath imports such as
      // react-dom/server.browser.js; no $-variant is needed.
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
