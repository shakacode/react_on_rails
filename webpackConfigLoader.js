/**
 * Allow defaults for the config/webpacker_lite.yml. Thee values in this file MUST match values
 * in README for https://github.com/shakacode/webpacker_lite
 *
 * webpack_public_output_dir: 'webpack'
 * manifest: 'manifest.json'
 *
 * hot_reloading_enabled_by_default: false
 * hot_reloading_host: localhost:3500
 *
 * NOTE: for hot reloading, env.HOT_RELOADING value will override any config value. This env value
 * should be set to TRUE to turn this on.
 */
const { join, resolve } = require('path');
const { safeLoad } = require('js-yaml');
const { readFileSync } = require('fs');

const DEFAULT_WEBPACK_PUBLIC_OUTPUT_DIR = 'webpack';
const DEFAULT_MANIFEST = 'manifest.json';
const DEFAULT_HOT_RELOADING_HOST = 'localhost:3500';
const HOT_RELOADING_ENABLED_BY_DEFAULT = false;

function getLocation(href) {
  const match = href.match(/^(https?:)\/\/(([^:/?#]*)(?::([0-9]+))?)([/]?[^?#]*)(\?[^#]*|)(#.*|)$/);

  return match && {
    href,
    protocol: match[1],
    host: match[2],
    hostname: match[3],
    port: match[4],
    pathname: match[5],
    search: match[6],
    hash: match[7],
  };
}

/**
 * @param configPath, location where webpacker_lite.yml will be found
 * @returns {{
 * devBuild,
 * hotReloadingEnabled,
 * hotReloadingHost,
 * hotReloadingPort,
 * hotReloadingUrl,
 * manifest,
 * webpackOutputPath,
 * webpackPublicOutputDir
 * }}
 */
const configLoader = (configPath) => {
  const env = process.env;

  // Some test environments might not have the NODE_ENV set, so we'll have fallbacks.
  const configEnv = (process.env.NODE_ENV || process.env.RAILS_ENV || 'development');
  const ymlConfigPath = join(configPath, 'webpacker_lite.yml');
  const configuration = safeLoad(readFileSync(ymlConfigPath, 'utf8'))[configEnv];
  const devBuild = configEnv !== 'production';
  const hotReloadingHost = configuration.hot_reloading_host || DEFAULT_HOT_RELOADING_HOST;

  // NOTE: Rails path is hard coded to `/public`
  const webpackPublicOutputDir = configuration.webpack_public_output_dir ||
    DEFAULT_WEBPACK_PUBLIC_OUTPUT_DIR;
  const webpackOutputPath = resolve(configPath, '..', 'public', webpackPublicOutputDir);

  const manifest = configuration.manifest || DEFAULT_MANIFEST;

  const hotReloadingEnabled = (env.HOT_RELOADING === 'TRUE' || env.HOT_RELOADING === 'YES' ||
    configuration.hot_reloading_enabled_by_default || HOT_RELOADING_ENABLED_BY_DEFAULT);

  const hotReloadingUrl = hotReloadingHost.match(/^http/)
    ? hotReloadingHost
    : `http://${hotReloadingHost}`;

  const url = getLocation(hotReloadingUrl);
  const hotReloadingPort = url.port;
  const hotReloadingHostname = url.hostname;
  if (hotReloadingPort === '' || hotReloadingHostname === '') {
    const msg = 'Missing port number. Please specify the `hot_reloading_host` like `localhost:3500`';
    throw new Error(msg);
  }

  return {
    devBuild,
    hotReloadingEnabled,
    hotReloadingHost,
    hotReloadingHostname,
    hotReloadingPort,
    hotReloadingUrl,
    manifest,
    webpackOutputPath,
    webpackPublicOutputDir,
  };
};

module.exports = configLoader;
