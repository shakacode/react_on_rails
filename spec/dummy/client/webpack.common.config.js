const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');
const urlFileSizeCutover = 1000; // below 10k, inline, small 1K is to test file loader

const assetLoaderRules = [
  {
    test: /\.(jpe?g|png|gif|ico|woff)$/,
    use: {
      loader: 'url-loader',
      options: {
        limit: urlFileSizeCutover,

        // Leading slash is needed
        name: 'images/[name]-[hash].[ext]',
      },
    },
  },
  {
    test: /\.(ttf|eot|svg)$/,
    use: {
      loader: 'file-loader',
      options: {
        // Leading slash is 100% needed
        name: 'images/[name]-[hash].[ext]',
      }
    },
  },
];

module.exports = {
  assetLoaderRules,
};
