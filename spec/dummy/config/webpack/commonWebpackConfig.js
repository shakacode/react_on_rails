// Common configuration applying to client and server configuration
const { generateWebpackConfig, merge, config } = require('shakapacker');
const { dirname } = require("path")

const baseClientWebpackConfig = generateWebpackConfig();

const webpack = require('webpack');

const aliasConfig = require('./alias');

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

// add sass resource loader
const sassLoaderConfig = {
  loader: 'sass-resources-loader',
  options: {
    resources: './client/app/assets/styles/app-variables.scss',
  },
};

const scssConfigIndex = baseClientWebpackConfig.module.rules.findIndex((config) =>
  '.scss'.match(config.test),
);
baseClientWebpackConfig.module.rules[scssConfigIndex]?.use.push(sassLoaderConfig);

// add jquery
const exposeJQuery = {
  test: require.resolve('jquery'),
  use: [{ loader: 'expose-loader', options: { exposes: ['$', 'jQuery'] } }],
};

const jqueryUjsLoader = {
  test: require.resolve('jquery-ujs'),
  use: [{ loader: 'imports-loader', options: { type: 'commonjs', imports: 'single jquery jQuery' } }],
};

baseClientWebpackConfig.plugins.push(
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    process: 'process/browser',
  }),
);

baseClientWebpackConfig.module.rules.push(exposeJQuery, jqueryUjsLoader);

const fileRule = baseClientWebpackConfig.module.rules.find((rule) => rule.test.test(".svg"));

fileRule.generator = {
  filename: (pathData) => {
    const path = dirname(pathData.filename);
    console.log(`path: ${path}`);
    const stripPaths = [...(config.additional_paths || []), config.source_path];

    const selectedStripPath = stripPaths.find((includePath) =>
      path.startsWith(includePath),
    );

    let processedPath = path.replace(`${selectedStripPath}`, "");
    console.log(`processedPath: ${processedPath}`);

    // Strip pnpm-specific path segments if they exist
    // Pattern: .pnpm/package-name@version/node_modules/
    processedPath = processedPath.replace(
      /\.pnpm\/[^@]+@[^/]+\/node_modules\//,
      "",
    );
    console.log(`processedPath: ${processedPath}`);

    const folders = processedPath.split("/").filter(Boolean);

    const foldersWithStatic = ["static", ...folders].join("/");
    return `${foldersWithStatic}/[name]-[hash][ext][query]`;
  },
};

const commonWebpackConfig = () => merge({}, baseClientWebpackConfig, commonOptions, aliasConfig);

module.exports = commonWebpackConfig;
