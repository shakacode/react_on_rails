/**
 * Isolates logic for handling render request. We don't want this module to know about
 * Express server and its req and res objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/renderRequestHandler
 */

const cluster = require('cluster');
const path = require('path');
const fs = require('fs');
const fsExtra = require('fs-extra');
const { getConfig } = require('./configBuilder');
const { clearConsoleHistory } = require('./consoleHistory');

/**
 *
 */
// TODO: Split this function in smaller methods.
module.exports = function handleRenderRequest(req) {
  if (!cluster.isMaster) console.log(`worker #${cluster.worker.id} received render request with with code ${req.body.renderingRequest}`);
  const { bundlePath } = getConfig();
  const bundleFilePath = path.join(bundlePath, 'bundle.js');

  // If bundle was not evaluated yet:
  if (!global.ReactOnRails) {
    // If gem has posted updated bundle:
    if (req.files.bundle) {
      saveAndEvalBundle(req, bundleFilePath);
      return processRenderingRequest(req);
    }

    // Check if bundle was uploaded:
    if (!fs.existsSync(bundleFilePath)) return reportNoBundle();

    // Check if another thread has already updated bundle and we don't need
    // to request it form the gem:
    /*const bundleUpdateTime = +(fs.statSync(bundleFilePath).mtime);
    if (bundleUpdateTime < Number(req.body.bundleUpdateTimeUtc)) {
      console.log('Bundle is outated');

      return {
        status: 410,
        data: 'Bundle is outdated',
      };
    }*/

    // If there is a fresh bundle, simply update VM:
    require(bundleFilePath);
  }

  return processRenderingRequest(req);
};

/**
 *
 */
function saveAndEvalBundle(req, bundleFilePath) {
  console.log('Worker has no bundle evaluated received new bundle');
  fsExtra.copySync(req.files.bundle.file, bundleFilePath);
  const bundleContents = fs.readFileSync(bundleFilePath, 'utf8');

  // (1, eval) is a small trick to evaluate code in the global scope (not in current function scope):
  (1, eval)(bundleContents);
}

/**
 *
 */
function processRenderingRequest(req) {
  clearConsoleHistory();
  const result = (1, eval)(req.body.renderingRequest);

  return {
    status: 200,
    data: { renderedHtml: result },
    die: false,
  };
}

/**
 *
 */
function reportNoBundle() {
  console.log('Worker has no bundle evaluated and found no bundle file');

  return {
    status: 410,
    data: 'No bundle uploaded',
    die: false,
  };
}
