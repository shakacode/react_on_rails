/**
 * Allow defaults for the config/webpacker.yml. Thee values in this file MUST match values
 * in https://github.com/rails/webpacker/blob/master/lib/install/config/webpacker.yml
 *
 * NOTE: for HMR reloading, env.WEBPACKER_HMR value will override any config value. This env value
 * should be set to TRUE to turn this on.
 */

const { join, resolve } = require('path');
const { env } = require('process');
const { safeLoad } = require('js-yaml');
const { readFileSync } = require('fs');


function removeOuterSlashes(string) {
  return string.replace(/^\/*/, '').replace(/\/*$/, '');
}

function formatPublicPath(settings) {
  if (settings.dev_server) {
    const { host } = settings.dev_server;
    const { port } = settings.dev_server;
    const path = settings.public_output_path;
    const hostWithHttp = `http://${host}:${port}`;

    let formattedHost = removeOuterSlashes(hostWithHttp);
    if (formattedHost && !/^http/i.test(formattedHost)) {
      formattedHost = `//${formattedHost}`;
    }
    const formattedPath = removeOuterSlashes(path);
    return `${formattedHost}/${formattedPath}/`;
  }

  const publicOuterPathWithoutOutsideSlashes = removeOuterSlashes(settings.public_output_path);
  return `//${publicOuterPathWithoutOutsideSlashes}/`;
}

/**
 * @param configPath, location where webpacker.yml will be found
 * Return values are consistent with Webpacker's js helpers
 * For example, you might define:
 *   const isHMR = settings.dev_server && settings.dev_server.hmr
 * @returns {{
     settings,
     resolvedModules,
     output: { path, publicPath, publicPathWithHost }
   }}
 */
const configLoader = (configPath) => {
  // Some test environments might not have the NODE_ENV set, so we'll have fallbacks.
  const configEnv = (env.NODE_ENV || env.RAILS_ENV || 'development');
  const ymlConfigPath = join(configPath, 'webpacker.yml');
  const settings = safeLoad(readFileSync(ymlConfigPath, 'utf8'))[configEnv];

  // NOTE: Rails path is hard coded to `/public`
  const output = {
    // Next line differs from the webpacker definition as we use the configPath to create
    // the relative path.
    path: resolve(configPath, '..', 'public', settings.public_output_path),
    publicPath: `/${settings.public_output_path}/`.replace(/([^:]\/)\/+/g, '$1'),
    publicPathWithHost: formatPublicPath(settings),
  };

  return {
    settings,
    output,
  };
};

module.exports = configLoader;
