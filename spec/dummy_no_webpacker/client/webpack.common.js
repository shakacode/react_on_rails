const urlFileSizeCutover = 10000; // below 10k, inline

const assetLoaderRules = [
  {
    test: /\.(ttf|eot)$/,
    use: 'file-loader',
  },
  {
    test: /(bg_|bg-).*\.(jpe?g|png|gif|ico)$/,
    use: {
      loader: 'url-loader',
      options: {
        limit: urlFileSizeCutover,
        name: 'images/[hash].[ext]',
      },
    },
  },
  {
    test: /^((?!(bg_|bg-)).)*\.(jpe?g|png|gif|ico|woff)$/,
    use: {
      loader: 'url-loader',
      options: {
        limit: urlFileSizeCutover,
        publicPath: 'assets/',
        name: 'images/[hash].[ext]',
      },
    },
  },
  {
    test: /(bg_|bg-).*\.(ttf|eot|svg)$/,
    use: {
      loader: 'file-loader',
      options: {
        name: 'images/[hash].[ext]',
      }
    },
  },
  {
    test: /^((?!(bg_|bg-)).)*\.(ttf|eot|svg)$/,
    use: {
      loader: 'file-loader',
      options: {
        publicPath: 'assets/',
        name: 'images/[hash].[ext]',
      }
    },
  },
];

module.exports = {
  assetLoaderRules,
};
