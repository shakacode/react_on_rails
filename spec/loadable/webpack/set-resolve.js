const _ = require('lodash/fp');
const path = require('path');

function setResolve(_builderConfig, webpackConfig) {
  const resolve = {
    modules: ['node_modules'],
    extensions: ['.mjs', '.js', '.jsx'],
    alias: {
      Utils: path.resolve(__dirname, '..', 'app', 'javascript', 'utils'),
    },
  };

  return _.set('resolve', resolve, webpackConfig);
}

module.exports = _.curry(setResolve);
