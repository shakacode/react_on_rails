const urlFileSizeCutover = 1000; // below 10k, inline, small 1K is to test file loader

const assetLoaderRules = [
  {
    test: /\.(jpe?g|png|gif|ico|woff)$/,
    use: {
      loader: 'url-loader',
      options: {
        limit: urlFileSizeCutover,

        // NO leading slash
        name: 'images/[name]-[hash].[ext]',
      },
    },
  },
  {
    test: /\.(ttf|eot|svg)$/,
    use: {
      loader: 'file-loader',
      options: {

        // NO leading slash
        name: 'images/[name]-[hash].[ext]',
      }
    },
  },
];

module.exports = {
  assetLoaderRules,
};
