/**
 * Isolates logic for handling render request. We don't want this module to
 * know about Express server and its req and res objects. This allows to test
 * module in isolation and without async calls.
 * @module worker/handleRenderRequest
 */

import cluster from 'cluster';
import path from 'path';
import fsExtra from 'fs-extra';

import { lock, unlock } from '../shared/locks';
import fileExistsAsync from '../shared/fileExistsAsync';
import log from '../shared/log';
import {
  formatExceptionMessage,
  errorResponseResult,
  workerIdLabel,
  moveUploadedAssets,
  Asset,
} from '../shared/utils';
import { getConfig } from '../shared/configBuilder';
import errorReporter from '../shared/errorReporter';
import { buildVM, getVmBundleFilePath, runInVM } from './vm';

/**
 *
 * @param renderingRequest
 * @returns {Promise<*>}
 */
async function prepareResult(renderingRequest: string) {
  try {
    const result = await runInVM(renderingRequest, cluster);

    let exceptionMessage = null;
    if (!result) {
      const error = new Error('INVALID NIL or NULL result for rendering');
      exceptionMessage = formatExceptionMessage(renderingRequest, error, 'INVALID result for prepareResult');
    } else if (typeof result === 'object' && result.exceptionMessage) {
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

function getRequestBundleFilePath(bundleTimestamp: string | number) {
  const { bundlePath } = getConfig();
  return path.join(bundlePath, `${bundleTimestamp}.js`);
}

type Bundle = Pick<Asset, 'file'>;

/**
 *
 * @param bundleFilePathPerTimestamp
 * @param providedNewBundle
 * @param renderingRequest
 * @param assetsToCopy might be null
 * @returns {Promise<{headers: {"Cache-Control": string}, data: any, status: number}>}
 */
async function handleNewBundleProvided(
  bundleFilePathPerTimestamp: string,
  providedNewBundle: Bundle,
  renderingRequest: string,
  assetsToCopy: Asset[] | null | undefined,
) {
  log.info('Worker received new bundle: %s', bundleFilePathPerTimestamp);

  let lockAcquired = false;
  let lockfileName: string | undefined;
  try {
    const { lockfileName: name, wasLockAcquired, errorMessage } = await lock(bundleFilePathPerTimestamp);
    lockfileName = name;
    lockAcquired = wasLockAcquired;

    if (!wasLockAcquired) {
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
      if (assetsToCopy) {
        await moveUploadedAssets(assetsToCopy);
      }

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
        if (lockfileName) {
          await unlock(lockfileName);
        }
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
export = async function handleRenderRequest({
  renderingRequest,
  bundleTimestamp,
  providedNewBundle,
  assetsToCopy,
}: {
  renderingRequest: string;
  bundleTimestamp: string | number;
  providedNewBundle?: Bundle | null;
  assetsToCopy?: Asset[] | null;
}) {
  try {
    const bundleFilePathPerTimestamp = getRequestBundleFilePath(bundleTimestamp);

    // If current vm is correct and ready
    if (getVmBundleFilePath() === bundleFilePathPerTimestamp) {
      return prepareResult(renderingRequest);
    }

    // If gem has posted updated bundle:
    if (providedNewBundle && providedNewBundle.file) {
      return handleNewBundleProvided(
        bundleFilePathPerTimestamp,
        providedNewBundle,
        renderingRequest,
        assetsToCopy,
      );
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
    errorReporter.notify(msg);
    return Promise.reject(error as Error);
  }
};
