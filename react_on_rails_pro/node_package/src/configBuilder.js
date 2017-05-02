/**
 * Reads CLI arguments and build the config.
 * @module configBuilder
 */

const path = require('path');

const bundlePath = path.resolve(__dirname, '../../spec/dummy/app/assets/webpack/');
let bundleFileName = 'server-bundle.js';
let port = 3000;

module.exports = function configBuilder() {
  let currentArg;

  process.argv.forEach((val) => {
    if (val[0] === '-') {
      currentArg = val.slice(1);
      return;
    }

    if (currentArg === 's') {
      bundleFileName = val;
    }
  });

  return { bundlePath, bundleFileName, port };
};
