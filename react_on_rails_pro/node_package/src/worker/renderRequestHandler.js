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
const { buildVM, runInVM, getBundleUpdateTimeUtc } = require('./sandbox');

// TODO: Split this function in smaller methods.
module.exports = function handleRenderRequest(req) {
  if (!cluster.isMaster) console.log(`worker #${cluster.worker.id} received render request with with code ${req.body.renderingRequest}`);
  const { bundlePath } = getConfig();
  const bundleFilePath = path.join(bundlePath, 'bundle.js');

  // If gem has posted updated bundle:
  if (req.files.bundle) {
    console.log('Worker received new bundle');
    fsExtra.copySync(req.files.bundle.file, bundleFilePath);
    buildVM(bundleFilePath);
    const result = runInVM(req.body.renderingRequest);

    return {
      status: 200,
      data: { renderedHtml: result },
    };
  }

  // If bundle was updated:
  if (!getBundleUpdateTimeUtc() ||
      (getBundleUpdateTimeUtc() < Number(req.body.bundleUpdateTimeUtc))) {
    console.log('Bundle was updated');

    // Check if bundle was uploaded:
    if (!fs.existsSync(bundleFilePath)) {
      return {
        status: 410,
        data: 'No bundle uploaded',
      };
    }

    // Check if another thread has already updated bundle and we don't need
    // to request it form the gem:
    const bundleUpdateTime = +(fs.statSync(bundleFilePath).mtime);
    if (bundleUpdateTime < Number(req.body.bundleUpdateTimeUtc)) {
      console.log('Bundle is outated');

      return {
        status: 410,
        data: 'Bundle is outdated',
      };
    }

    // If there is a fresh bundle, simply update VM:
    buildVM(bundleFilePath);
  }

  const result = runInVM(req.body.renderingRequest);

  return {
    status: 200,
    data: { renderedHtml: result },
  };
};
