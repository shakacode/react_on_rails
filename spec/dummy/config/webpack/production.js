process.env.NODE_ENV = process.env.NODE_ENV || 'production';

const webpackConfig = require('./webpackConfig');

const productionOnly = () => {
  // place any code here that is for production only

  // const optimization = {
  //   splitChunks: {
  //     chunks: 'async',
  //     cacheGroups: {
  //       vendor: {
  //         chunks: 'async',
  //         name: 'vendor',
  //         test: 'vendor',
  //         enforce: true,
  //       },
  //     },
  //   },
  // };

  // webpackConfig.splitChunks((config) => Object.assign({}, config, { optimization: optimization }));
};

module.exports = webpackConfig(productionOnly);
