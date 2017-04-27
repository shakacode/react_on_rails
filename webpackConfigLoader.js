const { join } = require('path');
const { env } = require('process');
const { safeLoad } = require('js-yaml');
const { readFileSync } = require('fs');

const configLoader = (configPath) => {
  const paths = safeLoad(readFileSync(join(configPath, 'paths.yml'), 'utf8'))[env.NODE_ENV];

  const devServerConfig = join(configPath, 'development.server.yml');
  const devServer = safeLoad(readFileSync(devServerConfig, 'utf8')).development;

  if (env.REACT_ON_RAILS_ENV === 'HOT') {
    devServer.enabled = true;
  }
  const productionBuild = env.NODE_ENV === 'production';

  const publicPath = !productionBuild && devServer.enabled ?
    `http://${devServer.host}:${devServer.port}/` : `/${paths.assets}/`;

  return {
    devServer,
    env,
    paths,
    publicPath,
  };
};

module.exports = configLoader;
