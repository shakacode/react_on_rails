/**
 * Isolates logic for handling render request. We don't want this module to
 * Fastify server and its Request and Reply objects. This allows to test
 * module in isolation and without async calls.
 * @module worker/handleRenderRequest
 */

import cluster from 'cluster';
import path from 'path';
import { mkdir } from 'fs/promises';
import { lock, unlock } from '../shared/locks.js';
import fileExistsAsync from '../shared/fileExistsAsync.js';
import log from '../shared/log.js';
import {
  Asset,
  formatExceptionMessage,
  errorResponseResult,
  workerIdLabel,
  copyUploadedAssets,
  ResponseResult,
  moveUploadedAsset,
  isReadableStream,
  isErrorRenderResult,
  getRequestBundleFilePath,
  deleteUploadedAssets,
  validateBundlesExist,
} from '../shared/utils.js';
import { getConfig } from '../shared/configBuilder.js';
import * as errorReporter from '../shared/errorReporter.js';
import { buildExecutionContext, ExecutionContext, VMContextNotFoundError } from './vm.js';

export type ProvidedNewBundle = {
  timestamp: string | number;
  bundle: Asset;
};

async function prepareResult(
  renderingRequest: string,
  bundleFilePathPerTimestamp: string,
  executionContext: ExecutionContext,
): Promise<ResponseResult> {
  try {
    const result = await executionContext.runInVM(renderingRequest, bundleFilePathPerTimestamp, cluster);

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
      return {
        headers: { 'Cache-Control': 'public, max-age=31536000' },
        status: 200,
        stream: result,
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

/**
 * @param bundleFilePathPerTimestamp
 * @param providedNewBundle
 * @param renderingRequest
 * @param assetsToCopy might be null
 */
async function handleNewBundleProvided(
  renderingRequest: string,
  providedNewBundle: ProvidedNewBundle,
  assetsToCopy: Asset[] | null | undefined,
): Promise<ResponseResult | undefined> {
  const bundleFilePathPerTimestamp = getRequestBundleFilePath(providedNewBundle.timestamp);
  const bundleDirectory = path.dirname(bundleFilePathPerTimestamp);
  await mkdir(bundleDirectory, { recursive: true });
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
      log.info(
        `Moving uploaded file ${providedNewBundle.bundle.savedFilePath} to ${bundleFilePathPerTimestamp}`,
      );
      await moveUploadedAsset(providedNewBundle.bundle, bundleFilePathPerTimestamp);
      if (assetsToCopy) {
        await copyUploadedAssets(assetsToCopy, bundleDirectory);
      }

      log.info(
        `Completed moving uploaded file ${providedNewBundle.bundle.savedFilePath} to ${bundleFilePathPerTimestamp}`,
      );
    } catch (error) {
      const fileExists = await fileExistsAsync(bundleFilePathPerTimestamp);
      if (!fileExists) {
        const msg = formatExceptionMessage(
          renderingRequest,
          error,
          `Unexpected error when moving the bundle from ${providedNewBundle.bundle.savedFilePath} \
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

    return undefined;
  } finally {
    if (lockAcquired && lockfileName) {
      log.info('About to unlock %s from worker %s', lockfileName, workerIdLabel());
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

export async function handleNewBundlesProvided(
  renderingRequest: string,
  providedNewBundles: ProvidedNewBundle[],
  assetsToCopy: Asset[] | null | undefined,
): Promise<ResponseResult | undefined> {
  log.info('Worker received new bundles: %s', providedNewBundles);

  const handlingPromises = providedNewBundles.map((providedNewBundle) =>
    handleNewBundleProvided(renderingRequest, providedNewBundle, assetsToCopy),
  );
  const results = await Promise.all(handlingPromises);

  if (assetsToCopy) {
    await deleteUploadedAssets(assetsToCopy);
  }

  const errorResult = results.find((result) => result !== undefined);
  return errorResult;
}

/**
 * Creates the result for the Fastify server to use.
 * @returns Promise where the result contains { status, data, headers } to
 * send back to the browser.
 */
export async function handleRenderRequest({
  renderingRequest,
  bundleTimestamp,
  dependencyBundleTimestamps,
  providedNewBundles,
  assetsToCopy,
}: {
  renderingRequest: string;
  bundleTimestamp: string | number;
  dependencyBundleTimestamps?: string[] | number[];
  providedNewBundles?: ProvidedNewBundle[] | null;
  assetsToCopy?: Asset[] | null;
}): Promise<ResponseResult> {
  try {
    // const bundleFilePathPerTimestamp = getRequestBundleFilePath(bundleTimestamp);
    const allBundleFilePaths = Array.from(
      new Set([...(dependencyBundleTimestamps ?? []), bundleTimestamp].map(getRequestBundleFilePath)),
    );
    const entryBundleFilePath = getRequestBundleFilePath(bundleTimestamp);

    const { maxVMPoolSize } = getConfig();

    if (allBundleFilePaths.length > maxVMPoolSize) {
      return {
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        status: 410,
        data: `Too many bundles uploaded. The maximum allowed is ${maxVMPoolSize}. Please reduce the number of bundles or increase maxVMPoolSize in your configuration.`,
      };
    }

    try {
      const executionContext = await buildExecutionContext(allBundleFilePaths, /* buildVmsIfNeeded */ false);
      return await prepareResult(renderingRequest, entryBundleFilePath, executionContext);
    } catch (e) {
      // Ignore VMContextNotFoundError, it means the bundle does not exist.
      // The following code will handle this case.
      if (!(e instanceof VMContextNotFoundError)) {
        throw e;
      }
    }

    // If gem has posted updated bundle:
    if (providedNewBundles && providedNewBundles.length > 0) {
      const result = await handleNewBundlesProvided(renderingRequest, providedNewBundles, assetsToCopy);
      if (result) {
        return result;
      }
    }

    // Check if the bundle exists:
    const missingBundleError = await validateBundlesExist(bundleTimestamp, dependencyBundleTimestamps);
    if (missingBundleError) {
      return missingBundleError;
    }

    // The bundle exists, but the VM has not yet been created.
    // Another worker must have written it or it was saved during deployment.
    log.info(
      'Bundle %s exists. Building ExecutionContext for worker %s.',
      entryBundleFilePath,
      workerIdLabel(),
    );
    const executionContext = await buildExecutionContext(allBundleFilePaths, /* buildVmsIfNeeded */ true);
    return await prepareResult(renderingRequest, entryBundleFilePath, executionContext);
  } catch (error) {
    const msg = formatExceptionMessage(
      renderingRequest,
      error,
      'Caught top level error in handleRenderRequest',
    );
    errorReporter.message(msg);
    return Promise.reject(error as Error);
  }
}
