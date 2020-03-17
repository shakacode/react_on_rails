/**
 * Isolates logic for handling render request. We don't want this module to
 * know about Express server and its req and res objects. This allows to test
 * module in isolation and without async calls.
 * @module worker/handleRenderRequest
 */

const cluster = require('cluster');
const path = require('path');
const fsExtra = require('fs-extra');

const { lock, unlock } = require('../shared/locks');
const fileExistsAsync = require('../shared/fileExistsAsync');
const log = require('../shared/log');
const { formatExceptionMessage, errorResponseResult, workerIdLabel } = require('../shared/utils');
const { getConfig } = require('../shared/configBuilder');
const errorReporter = require('../shared/errorReporter');
const { buildVM, getVmBundleFilePath, runInVM } = require('./vm');

/**
 *
 * @param renderingRequest
 * @returns {Promise<*>}
 */
async function prepareResult(renderingRequest) {
  try {
    const result = await runInVM(renderingRequest, cluster);

    let exceptionMessage = null;
    if (!result) {
      const error = new Error('INVALID NIL or NULL result for rendering');
      exceptionMessage = formatExceptionMessage(renderingRequest, error, 'INVALID result for prepareResult');
    } else if (result.exceptionMessage) {
      ({ exceptionMessage } = result);
    }

    if (exceptionMessage) {
      return Promise.resolve(errorResponseResult(exceptionMessage));
    }

    return Promise.resolve({
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      status: 200,
      data: result,
    });
  } catch (err) {
    const exceptionMessage = formatExceptionMessage(renderingRequest, err, 'Unknown error calling runInVM');
    return Promise.resolve(errorResponseResult(exceptionMessage));
  }
}

function getRequestBundleFilePath(bundleTimestamp) {
  const { bundlePath } = getConfig();
  return path.join(bundlePath, `${bundleTimestamp}.js`);
}

/**
 *
 * @param bundleFilePathPerTimestamp
 * @param providedNewBundle
 * @param renderingRequest
 * @returns {Promise<{headers: {"Cache-Control": string}, data: any, status: number}>}
 */
async function handleNewBundleProvided(bundleFilePathPerTimestamp, providedNewBundle, renderingRequest) {
  log.info('Worker received new bundle: %s', bundleFilePathPerTimestamp);

  let lockAcquired;
  let lockfileName;
  try {
    const { lockfileName: name, wasLockAcquired, errorMessage } = await lock(bundleFilePathPerTimestamp);
    lockfileName = name;
    lockAcquired = wasLockAcquired;

    if (!lockAcquired) {
      const msg = formatExceptionMessage(
        renderingRequest,
        errorMessage,
        `Failed to acquire lock ${lockfileName}. Worker: ${workerIdLabel()}.`,
      );
      return Promise.resolve(errorResponseResult(msg));
    }

    try {
      log.info(`Moving uploaded file ${providedNewBundle.file} to ${bundleFilePathPerTimestamp}`);
      await fsExtra.move(providedNewBundle.file, bundleFilePathPerTimestamp);

      log.info(`Completed moving uploaded file ${providedNewBundle.file} to ${bundleFilePathPerTimestamp}`);
    } catch (error) {
      const fileExists = await fileExistsAsync(bundleFilePathPerTimestamp);
      if (!fileExists) {
        const msg = formatExceptionMessage(
          renderingRequest,
          error,
          `Unexpected error when moving the bundle from ${providedNewBundle.file} \
to ${bundleFilePathPerTimestamp})`,
        );
        log.error(msg);
        return Promise.resolve(errorResponseResult(msg));
      }
      log.info(
        'File exists when trying to overwrite bundle %s. Assuming bundle written by other thread',
        bundleFilePathPerTimestamp,
      );
    }

    try {
      // Either this process or another process placed the file. Because the lock is acquired, the
      // file must be fully written
      log.info('buildVM, bundleFilePathPerTimestamp', bundleFilePathPerTimestamp);
      await buildVM(bundleFilePathPerTimestamp);
      return prepareResult(renderingRequest);
    } catch (error) {
      const msg = formatExceptionMessage(
        renderingRequest,
        error,
        `Unexpected error when building the VM ${bundleFilePathPerTimestamp}`,
      );
      return Promise.resolve(errorResponseResult(msg));
    }
  } finally {
    if (lockAcquired) {
      log.info('About to unlock %s from worker %i', lockfileName, workerIdLabel());
      try {
        await unlock(lockfileName);
      } catch (error) {
        const msg = formatExceptionMessage(
          renderingRequest,
          error,
          `Error unlocking ${lockfileName} from worker ${workerIdLabel()}.`,
        );
        log.warn(msg);
      }
    }
  }
}

/**
 * Creates the result for the express server to use.
 * @returns Promise where the result contains { status, data, headers } for to
 * send back to the browser.
 */
module.exports = async function handleRenderRequest({
  renderingRequest,
  bundleTimestamp,
  providedNewBundle,
}) {
  try {
    const bundleFilePathPerTimestamp = getRequestBundleFilePath(bundleTimestamp);

    // If current vm is correct and ready
    if (getVmBundleFilePath() === bundleFilePathPerTimestamp) {
      return prepareResult(renderingRequest);
    }

    // If gem has posted updated bundle:
    if (providedNewBundle && providedNewBundle.file) {
      return handleNewBundleProvided(bundleFilePathPerTimestamp, providedNewBundle, renderingRequest);
    }

    // If no vm yet or bundle name does not match
    const workerId = workerIdLabel();

    if (getVmBundleFilePath()) {
      log.info('Bundle per timestamp %s needed. Worker: %s', bundleFilePathPerTimestamp, workerId);
    } else {
      log.info('Bundle %s needed, but none saved yet. Worker: %s', bundleFilePathPerTimestamp, workerId);
    }

    // Check if bundle was uploaded:
    const fileExists = await fileExistsAsync(bundleFilePathPerTimestamp);
    if (!fileExists) {
      log.info(`No saved bundle ${bundleFilePathPerTimestamp}. Requesting a new bundle.`);
      return Promise.resolve({
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        status: 410,
        data: 'No bundle uploaded',
      });
    }

    // The bundle exists and the vm was not yet created. Another worker must
    // have written it or it was saved during deployment.
    await buildVM(bundleFilePathPerTimestamp);

    return prepareResult(renderingRequest);
  } catch (error) {
    const msg = formatExceptionMessage(
      renderingRequest,
      error,
      'Caught top level error in handleRenderRequest',
    );
    log.error(msg);
    errorReporter.notify(msg);
    return Promise.reject(error);
  }
};
