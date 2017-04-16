const { join, resolve } = require('path');
const { env } = require('process');
const { safeLoad } = require('js-yaml');
const { readFileSync } = require('fs');

const configPath = resolve('..', 'config', 'webpack');
const paths = safeLoad(readFileSync(join(configPath, 'paths.yml'), 'utf8'))[env.NODE_ENV];

const publicPath = `/${paths.assets}/`;

module.exports = {
  env,
  paths,
  publicPath,
};
