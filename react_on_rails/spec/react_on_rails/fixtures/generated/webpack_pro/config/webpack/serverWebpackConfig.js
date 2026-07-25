// The source code including full typescript support is available at: 
// https://github.com/shakacode/react-on-rails-demo-ssr-hmr/blob/master/config/webpack/serverWebpackConfig.js

const { merge, config } = require('shakapacker');
const commonWebpackConfig = require('./commonWebpackConfig');

const bundler = config.assets_bundler === 'rspack'
  ? require('@rspack/core')
  : require('webpack');

// Normalizes an entry of a webpack/rspack `rule.use` array to its loader path.
// Entries may be a bare string, a `{ loader, options }` object, or null.
function getLoaderPath(item) {
  if (typeof item === 'string') return item;
  if (item && typeof item.loader === 'string') return item.loader;
  return '';
}

function extractLoader(rule, loaderName) {
  if (!Array.isArray(rule.use)) return null;
  return rule.use.find((item) => getLoaderPath(item).includes(loaderName));
}

const configureServer = () => {
  // We need to use "merge" because the clientConfigObject, EVEN after running
  // toWebpackConfig() is a mutable GLOBAL. Thus any changes, like modifying the
  // entry value will result in changing the client config!
  // Using webpack-merge into an empty object avoids this issue.
  const serverWebpackConfig = commonWebpackConfig();

  // We just want the single server bundle entry
  const serverEntry = {
    'server-bundle': serverWebpackConfig.entry['server-bundle'],
  };

  if (!serverEntry['server-bundle']) {
    throw new Error(
      "Create a pack named 'server-bundle' containing all the server rendering files, for example 'server-bundle.js' or 'server-bundle.ts'",
    );
  }

  serverWebpackConfig.entry = serverEntry;

  // Remove the mini-css-extract-plugin from the style loaders because
  // the client build will handle exporting CSS.
  // replace file-loader with null-loader
  serverWebpackConfig.module.rules.forEach((loader) => {
    if (loader.use && loader.use.filter) {
      loader.use = loader.use.filter((item) => {
        const loaderPath = getLoaderPath(item);
        return !(
          loaderPath.includes('mini-css-extract-plugin') ||
          loaderPath.includes('cssExtractLoader') // Rspack uses this path
        );
      });
    }
  });

  // No splitting of chunks for a server bundle
  serverWebpackConfig.optimization = {
    minimize: false,
  };
  serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));

  // Custom output for the server-bundle
  // Using Shakapacker 9.0+ privateOutputPath for automatic sync with shakapacker.yml
  // This eliminates manual path configuration and keeps configs in sync.
  // Falls back to hardcoded path if private_output_path is not configured.
  const serverBundleOutputPath = config.privateOutputPath ||
    require('path').resolve(__dirname, '../../ssr-generated');

  serverWebpackConfig.output = {
    filename: 'server-bundle.js',
    globalObject: 'this',
    // Required for React on Rails Pro Node Renderer
    libraryTarget: 'commonjs2',
    path: serverBundleOutputPath,
    // No publicPath needed since server bundles are not served via web
    // https://webpack.js.org/configuration/output/#outputglobalobject
  };

  // Validate server bundle output path configuration
  // For Shakapacker 9.0+, verify privateOutputPath is configured in shakapacker.yml
  if (!config.privateOutputPath) {
    console.warn('⚠️  Shakapacker 9.0+ detected but private_output_path not configured in shakapacker.yml');
    console.warn('   Add to config/shakapacker.yml:');
    console.warn('     private_output_path: ssr-generated');
    console.warn('   Run: rails react_on_rails:doctor to validate your configuration');
  }


  // Don't hash the server bundle b/c would conflict with the client manifest
  // And no need for the MiniCssExtractPlugin
  serverWebpackConfig.plugins = serverWebpackConfig.plugins.filter(
    (plugin) =>
      plugin.constructor.name !== 'WebpackAssetsManifest' &&
      plugin.constructor.name !== 'MiniCssExtractPlugin' &&
      plugin.constructor.name !== 'ForkTsCheckerWebpackPlugin',
  );

  // Configure loader rules for SSR
  // Remove the mini-css-extract-plugin from the style loaders because
  // the client build will handle exporting CSS.
  // replace file-loader with null-loader
  const rules = serverWebpackConfig.module.rules;
  rules.forEach((rule) => {
    if (Array.isArray(rule.use)) {
      // remove the mini-css-extract-plugin and style-loader
      rule.use = rule.use.filter((item) => {
        const loaderPath = getLoaderPath(item);
        return !(
          loaderPath.includes('mini-css-extract-plugin') ||
          loaderPath.includes('cssExtractLoader') || // Rspack uses this path
          loaderPath === 'style-loader'
        );
      });
      const cssLoader = rule.use.find((item) => getLoaderPath(item).includes('css-loader'));
      if (cssLoader && cssLoader.options && cssLoader.options.modules) {
        cssLoader.options.modules = {
          ...(typeof cssLoader.options.modules === 'object' ? cssLoader.options.modules : {}),
          exportOnlyLocals: true,
        };
      }

      // Set SSR caller for Babel (if using Babel instead of SWC)
      const babelLoader = extractLoader(rule, 'babel-loader');
      if (babelLoader && babelLoader.options) {
        babelLoader.options.caller = { ssr: true };
      }

      // Skip writing image files during SSR by setting emitFile to false
    } else if (rule.use && (rule.use.loader === 'url-loader' || rule.use.loader === 'file-loader')) {
      rule.use.options.emitFile = false;
    }
  });

  // Avoid the webpack eval devtool, which triggers a webpack 5.106+ regression
  // with ESM default exports (ReferenceError: __WEBPACK_DEFAULT_EXPORT__ is not defined).
  // In development, cheap-module-source-map provides original line numbers in SSR error traces.
  // In production, devtool is disabled to avoid generating .map files.
  serverWebpackConfig.devtool = process.env.NODE_ENV === 'production' ? false : 'cheap-module-source-map';

  // React on Rails Pro uses Node renderer, so target must be 'node'
  // This fixes issues with libraries like Emotion and loadable-components
  serverWebpackConfig.target = 'node';

  // Disable Node.js polyfills - not needed when targeting Node
  serverWebpackConfig.node = false;

  // Source-mapped SSR stack traces in production:
  // The Pro Node renderer can remap bundled stack frames back to your original
  // source files (see docs/oss/building-features/node-renderer/debugging.md). This
  // needs source maps in the *production* server bundle, which the default above
  // disables (`devtool: false`). To opt in, replace only the `serverWebpackConfig.devtool`
  // assignment above (keep the eval-devtool note) with a production-aware variant so
  // development is unaffected. Both examples below use non-`eval` devtools, satisfying
  // that constraint. E.g.:
  //   serverWebpackConfig.devtool = process.env.NODE_ENV === 'production' ? 'source-map' : 'cheap-module-source-map';
  //     // 'source-map' — external .map (smaller bundle; stage the .map next to the uploaded bundle)
  //   serverWebpackConfig.devtool = process.env.NODE_ENV === 'production' ? 'inline-source-map' : 'cheap-module-source-map';
  //     // 'inline-source-map' — simplest; map travels inside the bundle (larger file)
  // The server bundle is never served to browsers; still, never expose
  // server-bundle source maps publicly.


  return serverWebpackConfig;
};

module.exports = {
  default: configureServer,
  extractLoader,
};
