/**
 * Allow defaults for the config/webpacker.yml. Thee values in this file MUST match values
 * in https://github.com/rails/webpacker/blob/master/lib/install/config/webpacker.yml
 *
 * NOTE: for hot reloading, env.WEBPACKER_HMR value will override any config value. This env value
 * should be set to TRUE to turn this on.
 */
const { join, resolve } = require('path');
const { safeLoad } = require('js-yaml');
const { readFileSync } = require('fs');

const MANIFEST = 'manifest.json';
const DEFAULT_PUBLIC_OUTPUT_PATH = 'packs';
const DEFAULT_DEV_SERVER_HOST = 'localhost';
const DEFAULT_DEV_SERVER_PORT = '8080';
const DEFAULT_DEV_SERVER_HTTPS = false;
const DEFAULT_DEV_SERVER_HOT = false;

/**
 * @param configPath, location where webpacker.yml will be found
 * @returns {{
 * devBuild,
 * hotReloadingEnabled,
 * devServerEnabled,
 * devServerHost,
 * devServerPort,
 * devServerUrl,
 * manifest,
 * webpackOutputPath,
 * webpackPublicOutputDir
 * }}
 */
const configLoader = (configPath) => {
  const env = process.env;

  // Some test environments might not have the NODE_ENV set, so we'll have fallbacks.
  const configEnv = (process.env.NODE_ENV || process.env.RAILS_ENV || 'development');
  const ymlConfigPath = join(configPath, 'webpacker.yml');
  const configuration = safeLoad(readFileSync(ymlConfigPath, 'utf8'))[configEnv];
  const devServerValues = configuration.dev_server;
  const devBuild = configEnv !== 'production';
  const devServerHost = devServerValues && (devServerValues.host || DEFAULT_DEV_SERVER_HOST);
  const devServerPort = devServerValues && (devServerValues.port || DEFAULT_DEV_SERVER_PORT);
  const devServerHttps = devServerValues && (devServerValues.https || DEFAULT_DEV_SERVER_HTTPS);
  const devServerHot = devServerValues && (devServerValues.https || DEFAULT_DEV_SERVER_HOT);

  // NOTE: Rails path is hard coded to `/public`
  const webpackPublicOutputDir = configuration.public_output_path ||
    DEFAULT_PUBLIC_OUTPUT_PATH;
  const webpackOutputPath = resolve(configPath, '..', 'public', webpackPublicOutputDir);

  const manifest = MANIFEST;

  const devServerEnabled = !!devServerValues;
  const hotReloadingEnabled = !!devServerHot || env.WEBPACKER_HMR === 'TRUE';

  let devServerUrl = null;
  if (devServerValues) {
    devServerUrl = `http${devServerHttps ? 's' : ''}://${devServerHost}:${devServerPort}`;
  }

  return {
    devBuild,
    hotReloadingEnabled,
    devServerEnabled,
    devServerHost,
    devServerPort,
    devServerUrl,
    manifest,
    webpackOutputPath,
    webpackPublicOutputDir,
  };
};

module.exports = configLoader;
