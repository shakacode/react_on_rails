/**
 * Setup default for the config/webpacker_lite.yml
 *
 * webpack_public_output_dir: 'webpack'
 * manifest: 'manifest.json'
 *
 * hot_reloading_enabled_by_default: false
 * hot_reloading_server: localhost:3500
 */
const { join, resolve } = require('path');
const { env } = require('process');
const { safeLoad } = require('js-yaml');
const { readFileSync } = require('fs');

/**
 * @param configPath, location where webpacker_lite.yml will be found
 * @returns {{
 * devBuild,
 * hotReloadingServerEnabled,
 * hotReloadingServer,
 * manifest,
 * webpackOutputPath
 * }}
 */
const configLoader = (configPath) => {
  const configuration = safeLoad(readFileSync(join(configPath, 'webpacker_lite.yml'), 'utf8'))[env.NODE_ENV];
  const devBuild = env !== 'production';
  const hotReloadingServer = configuration.hot_reloading_server || 'locahost:3500';

  // NOTE: Rails path is hard coded to `/public`
  const webpackPublicOutputDir = configuration.webpack_public_output_dir || 'webpack';
  const webpackOutputPath = resolve(configPath, '..', 'public',
    webpackPublicOutputDir);

  const manifest = configuration.manifest;
  let hotReloadingServerEnabled = false;
  if (env.HOT_RELOADING === 'TRUE' || env.HOT_RELOADING === 'YES' ||
    configuration.hot_reloading_enabled_by_default) {
    hotReloadingServerEnabled = true;
  }

  return {
    devBuild,
    hotReloadingServerEnabled,
    hotReloadingServer,
    manifest,
    webpackOutputPath,
  };
};

module.exports = configLoader;
