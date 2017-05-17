const { join, resolve } = require('path');
const { env } = require('process');
const { safeLoad } = require('js-yaml');
const { readFileSync } = require('fs');

const configLoader = (configPath) => {
  const configuration = safeLoad(readFileSync(join(configPath, 'webpacker_lite.yml'), 'utf8'))[env.NODE_ENV];
  const devBuild = env !== 'production';
  const hotReloadingServer = configuration.hotReloadingServer;

  // NOTE: Rails path is hard coded to `/public`
  const webpackOutputPath = resolve(configPath, '..', 'public',
    configuration.webpack_public_output_dir);

  const manifest = webpackOutputPath.manifest;
  let hotReloadingServerEnabled = false;
  if (env.HOT_RELOADING === 'TRUE' || env.HOT_RELOADING === 'YES' ||
    configuration.hot_reloading_enabled_by_default) {
    hotReloadingServerEnabled = true;
  }

  return {
    configuration,
    devBuild,
    env,
    hotReloadingServerEnabled,
    hotReloadingServer,
    manifest,
    webpackOutputPath,
  };
};

module.exports = configLoader;
