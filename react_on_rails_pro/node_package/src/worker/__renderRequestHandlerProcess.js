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

let evaluatedBundleFilePath;

/**
 *
 */
function saveBundle(req, bundleFilePath) {
  console.log('Worker has no bundle evaluated received new bundle');
  fsExtra.copySync(req.files.bundle.file, bundleFilePath);
}

/**
 *
 */
function evalBundle(bundleFilePath) {
  const bundleContents = fs.readFileSync(bundleFilePath, 'utf8');

  // (1, eval) is a small trick to evaluate code in the global scope (not in current
  // function scope).
  // See http://stackoverflow.com/questions/9107240/1-evalthis-vs-evalthis-in-javascript
  // eslint-disable-next-line no-eval
  (1, eval)(bundleContents);
  evaluatedBundleFilePath = bundleFilePath;
}

/**
 *
 */
function processRenderingRequest(req) {
  clearConsoleHistory();

  // eslint-disable-next-line no-eval
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

/**
 *
 */
function reportNeedRetryAndAskForDying() {
  return {
    status: 307,
    data: 'Worker process invalidated, dying',
    die: true,
  };
}

/**
 *
 */
function reportNoBundleAndAskForDying() {
  console.log('Worker already has evaluated bundle and found no bundle file');

  return {
    status: 410,
    data: 'No bundle uploaded',
    die: true,
  };
}

/**
 *
 */
// TODO: Split this function in smaller methods.
module.exports = function handleRenderRequest(req) {
  if (!cluster.isMaster) console.log(`worker #${cluster.worker.id} received render request with with code ${req.body.renderingRequest}`);
  const { bundlePath } = getConfig();
  const bundleFilePath = path.join(bundlePath, `${req.body.bundleUpdateTimeUtc}.js`);

  // ======= If bundle was not evaluated yet: =======
  if (!evaluatedBundleFilePath) {
    // If gem has posted updated bundle:
    if (req.files.bundle) {
      saveBundle(req, bundleFilePath);
      evalBundle(bundleFilePath);
      return processRenderingRequest(req);
    }

    // Check if bundle was uploaded:
    if (!fs.existsSync(bundleFilePath)) return reportNoBundle();

    // If bundle was already uploaded by another process:
    evalBundle(bundleFilePath);
    return processRenderingRequest(req);
  }

  // ======= If bundle was already evaluated: =======
  // If gem has posted updated bundle:
  if (req.files.bundle) {
    saveBundle(req, bundleFilePath);
    return reportNeedRetryAndAskForDying();
  }

  // If gem sent new bujndle update timestamp:
  if (bundleFilePath !== evaluatedBundleFilePath) {
    if (!fs.existsSync(bundleFilePath)) return reportNoBundleAndAskForDying();
    return reportNeedRetryAndAskForDying();
  }

  return processRenderingRequest(req);
};
