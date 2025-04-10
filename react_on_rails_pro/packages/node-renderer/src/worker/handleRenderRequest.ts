/**
 * Isolates logic for handling render request. We don't want this module to
 * Fastify server and its Request and Reply objects. This allows to test
 * module in isolation and without async calls.
 * @module worker/handleRenderRequest
 */

import cluster from 'cluster';
import path from 'path';
import { lock, unlock } from '../shared/locks';
import fileExistsAsync from '../shared/fileExistsAsync';
import log from '../shared/log';
import {
  Asset,
  formatExceptionMessage,
  errorResponseResult,
  workerIdLabel,
  moveUploadedAssets,
  ResponseResult,
  moveUploadedAsset,
  isReadableStream,
  isErrorRenderResult,
  handleStreamError,
} from '../shared/utils';
import { getConfig } from '../shared/configBuilder';
import * as errorReporter from '../shared/errorReporter';
import { buildVM, hasVMContextForBundle, runInVM } from './vm';

async function prepareResult(
  renderingRequest: string,
  bundleFilePathPerTimestamp: string,
): Promise<ResponseResult> {
  try {
    const result = await runInVM(renderingRequest, bundleFilePathPerTimestamp, cluster);

    let exceptionMessage = null;
    if (!result) {
      const error = new Error('INVALID NIL or NULL result for rendering');
      exceptionMessage = formatExceptionMessage(renderingRequest, error, 'INVALID result for prepareResult');
    } else if (isErrorRenderResult(result)) {
      ({ exceptionMessage } = result);
    }

    if (exceptionMessage) {
      return errorResponseResult(exceptionMessage);
    }

    if (isReadableStream(result)) {
      const newStreamAfterHandlingError = handleStreamError(result, (error) => {
        const msg = formatExceptionMessage(renderingRequest, error, 'Error in a rendering stream');
        errorReporter.message(msg);
      });
      return {
        headers: { 'Cache-Control': 'public, max-age=31536000' },
        status: 200,
        stream: newStreamAfterHandlingError,
      };
    }

    return {
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      status: 200,
      data: result,
    };
  } catch (err) {
    const exceptionMessage = formatExceptionMessage(renderingRequest, err, 'Unknown error calling runInVM');
    return errorResponseResult(exceptionMessage);
  }
}

function getRequestBundleFilePath(bundleTimestamp: string | number) {
  const { bundlePath } = getConfig();
  return path.join(bundlePath, `${bundleTimestamp}.js`);
}

/**
 * @param bundleFilePathPerTimestamp
 * @param providedNewBundle
 * @param renderingRequest
 * @param assetsToCopy might be null
 */
async function handleNewBundleProvided(
  bundleFilePathPerTimestamp: string,
  providedNewBundle: Asset,
  renderingRequest: string,
  assetsToCopy: Asset[] | null | undefined,
): Promise<ResponseResult> {
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
      return errorResponseResult(msg);
    }

    try {
      log.info(`Moving uploaded file ${providedNewBundle.savedFilePath} to ${bundleFilePathPerTimestamp}`);
      await moveUploadedAsset(providedNewBundle, bundleFilePathPerTimestamp);
      if (assetsToCopy) {
        await moveUploadedAssets(assetsToCopy);
      }

      log.info(
        `Completed moving uploaded file ${providedNewBundle.savedFilePath} to ${bundleFilePathPerTimestamp}`,
      );
    } catch (error) {
      const fileExists = await fileExistsAsync(bundleFilePathPerTimestamp);
      if (!fileExists) {
        const msg = formatExceptionMessage(
          renderingRequest,
          error,
          `Unexpected error when moving the bundle from ${providedNewBundle.savedFilePath} \
to ${bundleFilePathPerTimestamp})`,
        );
        log.error(msg);
        return errorResponseResult(msg);
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
      return await prepareResult(renderingRequest, bundleFilePathPerTimestamp);
    } catch (error) {
      const msg = formatExceptionMessage(
        renderingRequest,
        error,
        `Unexpected error when building the VM ${bundleFilePathPerTimestamp}`,
      );
      return errorResponseResult(msg);
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
 * Creates the result for the Fastify server to use.
 * @returns Promise where the result contains { status, data, headers } to
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
  providedNewBundle?: Asset | null;
  assetsToCopy?: Asset[] | null;
}): Promise<ResponseResult> {
  try {
    const bundleFilePathPerTimestamp = getRequestBundleFilePath(bundleTimestamp);

    // If the current VM has the correct bundle and is ready
    if (hasVMContextForBundle(bundleFilePathPerTimestamp)) {
      return await prepareResult(renderingRequest, bundleFilePathPerTimestamp);
    }

    // If gem has posted updated bundle:
    if (providedNewBundle) {
      return await handleNewBundleProvided(
        bundleFilePathPerTimestamp,
        providedNewBundle,
        renderingRequest,
        assetsToCopy,
      );
    }

    // Check if the bundle exists:
    const fileExists = await fileExistsAsync(bundleFilePathPerTimestamp);
    if (!fileExists) {
      log.info(`No saved bundle ${bundleFilePathPerTimestamp}. Requesting a new bundle.`);
      return {
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        status: 410,
        data: 'No bundle uploaded',
      };
    }

    // The bundle exists, but the VM has not yet been created.
    // Another worker must have written it or it was saved during deployment.
    log.info('Bundle %s exists. Building VM for worker %s.', bundleFilePathPerTimestamp, workerIdLabel());
    await buildVM(bundleFilePathPerTimestamp);

    return await prepareResult(renderingRequest, bundleFilePathPerTimestamp);
  } catch (error) {
    const msg = formatExceptionMessage(
      renderingRequest,
      error,
      'Caught top level error in handleRenderRequest',
    );
    errorReporter.message(msg);
    return Promise.reject(error as Error);
  }
};
