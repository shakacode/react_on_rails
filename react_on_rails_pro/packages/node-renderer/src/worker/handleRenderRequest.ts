/**
 * Isolates logic for handling render request. We don't want this module to
 * Fastify server and its Request and Reply objects. This allows to test
 * module in isolation and without async calls.
 * @module worker/handleRenderRequest
 */

import path from 'path';
import { mkdir } from 'fs/promises';
import { lock, unlock } from '../shared/locks';
import fileExistsAsync from '../shared/fileExistsAsync';
import log from '../shared/log';
import {
  Asset,
  formatExceptionMessage,
  errorResponseResult,
  workerIdLabel,
  copyUploadedAssets,
  ResponseResult,
  moveUploadedAsset,
  getRequestBundleFilePath,
  deleteUploadedAssets,
} from '../shared/utils';
import { getConfig } from '../shared/configBuilder';
import { hasVMContextForBundle } from './vm';
import {
  validateAndGetBundlePaths,
  buildVMsForBundles,
  executeRenderInVM,
  createRenderErrorResponse,
} from './sharedRenderUtils';

export type ProvidedNewBundle = {
  timestamp: string | number;
  bundle: Asset;
};

async function prepareResult(
  renderingRequest: string,
  bundleFilePathPerTimestamp: string,
): Promise<ResponseResult> {
  try {
    const executionResult = await executeRenderInVM(renderingRequest, bundleFilePathPerTimestamp);

    if (!executionResult.success || !executionResult.result) {
      return executionResult.error || errorResponseResult('Unknown error during render execution');
    }

    return executionResult.result;
  } catch (err) {
    return createRenderErrorResponse(renderingRequest, err, 'Unknown error calling runInVM');
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

async function handleNewBundlesProvided(
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

    // If the current VM has the correct bundle and is ready
    if (allBundleFilePaths.every((bundleFilePath) => hasVMContextForBundle(bundleFilePath))) {
      return await prepareResult(renderingRequest, entryBundleFilePath);
    }

    // If gem has posted updated bundle:
    if (providedNewBundles && providedNewBundles.length > 0) {
      const result = await handleNewBundlesProvided(renderingRequest, providedNewBundles, assetsToCopy);
      if (result) {
        return result;
      }
    }

    // Validate bundles and get paths
    const validationResult = await validateAndGetBundlePaths(bundleTimestamp, dependencyBundleTimestamps);
    if (!validationResult.success || !validationResult.bundleFilePath) {
      return validationResult.error || errorResponseResult('Bundle validation failed');
    }

    // Build VMs
    const vmBuildResult = await buildVMsForBundles(
      validationResult.bundleFilePath,
      validationResult.dependencyBundleFilePaths || [],
    );
    if (!vmBuildResult.success) {
      return vmBuildResult.error || errorResponseResult('VM building failed');
    }

    return await prepareResult(renderingRequest, entryBundleFilePath);
  } catch (error) {
    return createRenderErrorResponse(
      renderingRequest,
      error,
      'Caught top level error in handleRenderRequest',
    );
  }
}
