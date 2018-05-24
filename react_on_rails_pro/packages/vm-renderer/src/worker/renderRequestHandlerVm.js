/**
 * Isolates logic for handling render request. We don't want this module to know about
 * Express server and its req and res objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/renderRequestHandlerVm
 */
import cluster from 'cluster';
import path from 'path';
import fs from 'fs';
import fsExtra from 'fs-extra';
import log from 'winston';

import { getConfig } from '../shared/configBuilder';
import { buildVM, runInVM, getBundleFilePath } from './vm';

/**
 *
 */
// TODO: Split this function in smaller methods.
module.exports = function handleRenderRequest(req) {
  const prepareResult = (request) => {
    const result = runInVM(request.body.renderingRequest);
    return {
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      status: 200,
      data: result,
    };
  };

  if (!cluster.isMaster) {
    log.debug('worker #%s received render request with with code %s',
      cluster.worker.id, req.body.renderingRequest);
  }
  const { bundlePath } = getConfig();
  const bundleFilePath = path.join(bundlePath, `${req.params.bundleTimestamp}.js`);

  // If gem has posted updated bundle:
  if (req.files.bundle) {
    log.debug('Worker received new bundle');
    fsExtra.copySync(req.files.bundle.file, bundleFilePath);
    buildVM(bundleFilePath);
    return prepareResult(req);
  }

  // If bundle was updated:
  if (!getBundleFilePath() || (getBundleFilePath() !== bundleFilePath)) {
    log.debug('Bundle was updated');

    // Check if bundle was uploaded:
    if (!fs.existsSync(bundleFilePath)) {
      return {
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        status: 410,
        data: 'No bundle uploaded',
      };
    }

    // If there is a fresh bundle, simply update VM:
    buildVM(bundleFilePath);
  }
  return prepareResult(req);
};
