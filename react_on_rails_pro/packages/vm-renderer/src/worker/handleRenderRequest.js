/**
 * Isolates logic for handling render request. We don't want this module to
 * know about Express server and its req and res objects. This allows to test
 * module in isolation and without async calls.
 * @module worker/handleRenderRequest
 */

const sleep = require('sleep-promise');
const cluster = require('cluster');
const path = require('path');
const fs = require('fs');
const fsExtra = require('fs-extra');
const lockfile = require('lockfile');
const { promisify } = require('util');

const debug = require('../shared/debug');
const log = require('../shared/log');
const { formatExceptionMessage, errorResponseResult, workerIdLabel } = require('../shared/utils');
const { getConfig } = require('../shared/configBuilder');
const errorReporter = require('../shared/errorReporter');
const { buildVM, getVmBundleFilePath, runInVM } = require('./vm');

const lockfileLockAsync = promisify(lockfile.lock);
const lockfileUnlockAsync = promisify(lockfile.unlock);

const TEST_LOCKFILE_THREADING = false;

// See definitions here: https://github.com/npm/lockfile/blob/master/README.md#options
/*
 * A number of milliseconds to wait for locks to expire before giving up. Only used by
 * lockFile.lock. Poll for opts.wait ms. If the lock is not cleared by the time the wait expires,
 * then it returns with the original error.
 */
const LOCKFILE_WAIT = 3000;

/*
 * When using opts.wait, this is the period in ms in which it polls to check if the lock has
 * expired. Defaults to 100.
 */
const LOCKFILE_POLL_PERIOD = 300; // defaults to 100

/*
 * A number of milliseconds before locks are considered to have expired.
 */
const LOCKFILE_STALE = 20000;

/*
 * Used by lock and lockSync. Retry n number of times before giving up.
 */
const LOCKFILE_RETRIES = 45;

/*
 * Used by lock. Wait n milliseconds before retrying.
 */
const LOCKFILE_RETRY_WAIT = 300;

const lockfileOptions = {
  wait: LOCKFILE_WAIT,
  retryWait: LOCKFILE_RETRY_WAIT,
  retries: LOCKFILE_RETRIES,
  stale: LOCKFILE_STALE,
  pollPeriod: LOCKFILE_POLL_PERIOD,
};

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
      log.error(exceptionMessage);
      errorReporter.notify(exceptionMessage);
      return Promise.resolve(errorResponseResult(exceptionMessage));
    }

    return Promise.resolve({
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      status: 200,
      data: result,
    });
  } catch (err) {
    const exceptionMessage = formatExceptionMessage(renderingRequest, err, 'Unknown error calling runInVM');
    log.error(exceptionMessage);
    errorReporter.notify(exceptionMessage);
    return Promise.resolve(errorResponseResult(exceptionMessage));
  }
}

function getRequestBundleFilePath(bundleTimestamp) {
  const { bundlePath } = getConfig();
  return path.join(bundlePath, `${bundleTimestamp}.js`);
}

function errorResult(msg) {
  errorReporter.notify(msg);
  log.error(` error ${msg}`);
  return {
    headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
    status: 400,
    data: msg,
  };
}

/**
 *
 * @param lockfileName
 * @returns {Promise<void>}
 */
async function unlock(lockfileName) {
  debug('Unlocking lockfile %s', lockfileName);

  await lockfileUnlockAsync(lockfileName);
}

/**
 *
 * @param bundleFilePathPerTimestamp
 * @param providedNewBundle
 * @param renderingRequest
 * @returns {Promise<void>}
 */
async function handleNewBundleProvided(bundleFilePathPerTimestamp, providedNewBundle, renderingRequest) {
  log.info('Worker received new bundle: %s', bundleFilePathPerTimestamp);

  const lockfileName = `${bundleFilePathPerTimestamp}.lock`;
  const workerId = workerIdLabel();
  let lockAcquired;

  try {
    try {
      debug('Worker %s: About to request lock %s', workerId, lockfileName);
      log.info('Worker %s: About to request lock %s', workerId, lockfileName);
      await lockfileLockAsync(lockfileName, lockfileOptions);
      lockAcquired = true;

      if (TEST_LOCKFILE_THREADING) {
        debug('Worker %i: handleNewBundleProvided sleeping 5s', workerId);
        await sleep(5000);
        debug('Worker %i: handleNewBundleProvided done sleeping 5s', workerId);
      }
      debug('After acquired lock in pid', lockfileName);
    } catch (error) {
      const msg = formatExceptionMessage(
        renderingRequest,
        error,
        `Failed to acquire lock ${lockfileName}. Worker: ${workerId}.`,
      );
      return Promise.resolve(errorResult(msg));
    }

    try {
      log.info(`Moving uploaded file ${providedNewBundle.file} to ${bundleFilePathPerTimestamp}`);
      await fsExtra.move(providedNewBundle.file, bundleFilePathPerTimestamp);

      log.info(`Completed moving uploaded file ${providedNewBundle.file} to ${bundleFilePathPerTimestamp}`);
    } catch (error) {
      if (!fs.existsSync(bundleFilePathPerTimestamp)) {
        const msg = formatExceptionMessage(
          renderingRequest,
          error,
          `Unexpected error when moving the bundle from ${providedNewBundle.file} \
to ${bundleFilePathPerTimestamp})`,
        );
        log.error(msg);
        return Promise.resolve(errorResult(msg));
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
      return Promise.resolve(errorResult(msg));
    }
  } finally {
    if (lockAcquired) {
      log.info('About to unlock %s from worker %i', lockfileName, workerId);
      try {
        await unlock(lockfileName);
      } catch (error) {
        const msg = formatExceptionMessage(
          renderingRequest,
          error,
          `Error unlocking ${lockfileName} from worker ${workerId}.`,
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
    if (!fs.existsSync(bundleFilePathPerTimestamp)) {
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
