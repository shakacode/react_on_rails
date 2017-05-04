/**
 * Loads app server bundle and watches for updates.
 * @module bundleWatcher
 */

const fs = require('fs');
const path = require('path');
const { buildVM } = require('./vm');

function loadBundle(bundlePath, bundleFileName) {
  buildVM(bundlePath, bundleFileName);
  console.log(`Loaded server bundle: ${bundlePath}${bundleFileName}`);
}

module.exports = function bundleWatcher(bundlePath, bundleFileName) {
  try {
    fs.mkdirSync(bundlePath);
  } catch (e) {
    if (e.code !== 'EEXIST') {
      throw e;
    } else {
      loadBundle(bundlePath, bundleFileName);
    }
  }

  fs.watchFile(path.join(bundlePath, bundleFileName), (curr) => {
    if (curr && curr.blocks && curr.blocks > 0) {
      loadBundle(bundlePath, bundleFileName);
    }
  });
};
