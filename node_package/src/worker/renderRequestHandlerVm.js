/**
 * Isolates logic for handling render request. We don't want this module to know about
 * Express server and its req and res objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/renderRequestHandlerVm
 */

'use strict';

const cluster = require('cluster');
const path = require('path');
const fs = require('fs');
const fsExtra = require('fs-extra');
const log = require('winston');
const { getConfig } = require('../shared/configBuilder');
const { buildVM, runInVM, getBundleFilePath } = require('./vm');

/**
 *
 */
// TODO: Split this function in smaller methods.
module.exports = function handleRenderRequest(req) {
  if (!cluster.isMaster) log.debug(`worker #${cluster.worker.id} received render request with with code ${req.body.renderingRequest}`);
  const { bundlePath } = getConfig();
  const bundleFilePath = path.join(bundlePath, `${req.params.bundleTimestamp}.js`);

  // If gem has posted updated bundle:
  if (req.files.bundle) {
    log.debug('Worker received new bundle');
    fsExtra.copySync(req.files.bundle.file, bundleFilePath);
    buildVM(bundleFilePath);
    const result = runInVM(req.body.renderingRequest);

    return {
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      status: 200,
      data: { renderedHtml: result },
    };
  }

  // If bundle was updated:
  if (!getBundleFilePath() || (getBundleFilePath() !== bundleFilePath)) {
    log.debug('Bundle was updated');

    // Check if bundle was uploaded:
    if (!fs.existsSync(bundleFilePath)) {
      return {
        status: 410,
        data: 'No bundle uploaded',
      };
    }

    // If there is a fresh bundle, simply update VM:
    buildVM(bundleFilePath);
  }

  const result = runInVM(req.body.renderingRequest);

  return {
    headers: { 'Cache-Control': 'public, max-age=31536000' },
    status: 200,
    data: { renderedHtml: result },
    // data: { renderedHtml: '{ "html": "FAKE" }' },
  };
};
