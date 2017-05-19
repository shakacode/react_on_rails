/**
 * Setup default for the config/webpacker_lite.yml
 *
 * webpack_public_output_dir: 'webpack'
 * manifest: 'manifest.json'
 *
 * hot_reloading_enabled_by_default: false
 * hot_reloading_host: localhost:3500
 */
const { join, resolve } = require('path');
const { env } = require('process');
const { safeLoad } = require('js-yaml');
const { readFileSync } = require('fs');

function getLocation(href) {
  const match = href.match(/^(https?\:)\/\/(([^:\/?#]*)(?:\:([0-9]+))?)([\/]{0,1}[^?#]*)(\?[^#]*|)(#.*|)$/);
  return match && {
      href: href,
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
 * webpackOutputPath
 * }}
 */
const configLoader = (configPath) => {
  const configuration = safeLoad(readFileSync(join(configPath, 'webpacker_lite.yml'), 'utf8'))[env.NODE_ENV];

  const devBuild = env !== 'production';
  const hotReloadingHost = configuration.hot_reloading_host || 'localhost:3500';

  // NOTE: Rails path is hard coded to `/public`
  const webpackPublicOutputDir = configuration.webpack_public_output_dir || 'webpack';
  const webpackOutputPath = resolve(configPath, '..', 'public',
    webpackPublicOutputDir);

  const manifest = configuration.manifest;
  let hotReloadingEnabled = false;
  if (env.HOT_RELOADING === 'TRUE' || env.HOT_RELOADING === 'YES' ||
    configuration.hot_reloading_enabled_by_default) {
    hotReloadingEnabled = true;
  }

  let hotReloadingUrl = hotReloadingHost;
  if (!hotReloadingUrl.match(/^http/)) {
    hotReloadingUrl = `http://${hotReloadingUrl}`;
  }

  const url = getLocation(hotReloadingUrl);
  const hotReloadingPort = url.port;
  const hotReloadingHostname = url.hostname;
  if (hotReloadingPort === '' || hotReloadingHostname === '') {
    throw new Error(
      'Missing port number. Please specify the `hot_reloading_host` like `localhost:3500`'
    );
  }

  let xx = {
    devBuild,
    hotReloadingEnabled,
    hotReloadingHost,
    hotReloadingHostname,
    hotReloadingPort,
    hotReloadingUrl,
    manifest,
    webpackOutputPath,
  };

  return {
    devBuild,
    hotReloadingEnabled,
    hotReloadingHost,
    hotReloadingHostname,
    hotReloadingPort,
    hotReloadingUrl,
    manifest,
    webpackOutputPath,
  };
};

module.exports = configLoader;
