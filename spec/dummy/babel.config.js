module.exports = function (api) {
  const defaultConfigFunc = require('@rails/webpacker/package/babel/preset.js');
  const resultConfig = defaultConfigFunc(api);

  const changesOnDefault = {
    plugins: [process.env.WEBPACK_SERVE && 'react-refresh/babel'].filter(Boolean),
  };

  resultConfig.plugins = [...resultConfig.plugins, ...changesOnDefault.plugins];

  return resultConfig;
};
