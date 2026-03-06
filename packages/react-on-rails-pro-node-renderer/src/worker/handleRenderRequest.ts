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
  isBundleComplete,
  cleanIncompleteBundleDirectory,
  markBundleComplete,
} from '../shared/utils.js';
import { getConfig } from '../shared/configBuilder.js';
import type { TracingContext } from '../shared/tracing.js';
import { buildVM, hasVMContextForBundle, runInVM } from './vm.js';

export type ProvidedNewBundle = {
  timestamp: string | number;
  bundle: Asset;
};

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
      const [bundleFileExists, bundleComplete] = await Promise.all([
        fileExistsAsync(bundleFilePathPerTimestamp),
        isBundleComplete(providedNewBundle.timestamp),
      ]);
      if (bundleFileExists && bundleComplete) {
        log.info(
          'Bundle %s already exists and is complete. Skipping duplicate upload.',
          bundleFilePathPerTimestamp,
        );
        return undefined;
      }

      const wasIncomplete = await cleanIncompleteBundleDirectory(providedNewBundle.timestamp);
      if (wasIncomplete) {
        log.warn('Removed incomplete bundle directory before writing bundle %s', bundleFilePathPerTimestamp);
      }

      log.info(
        `Moving uploaded file ${providedNewBundle.bundle.savedFilePath} to ${bundleFilePathPerTimestamp}`,
      );
      await moveUploadedAsset(providedNewBundle.bundle, bundleFilePathPerTimestamp);
      if (assetsToCopy) {
        await copyUploadedAssets(assetsToCopy, bundleDirectory);
      }
      await markBundleComplete(providedNewBundle.timestamp);

      log.info(
        `Completed moving uploaded file ${providedNewBundle.bundle.savedFilePath} to ${bundleFilePathPerTimestamp}`,
      );
    } catch (error) {
      // On Windows and some cross-device move fallbacks, fs-extra can surface
      // EEXIST if a competing write already created the destination path.
      const isExistingBundleWriteConflict =
        (error as NodeJS.ErrnoException).code === 'EEXIST' &&
        (await fileExistsAsync(bundleFilePathPerTimestamp));
      if (isExistingBundleWriteConflict) {
        log.warn(
          'Bundle already existed when writing %s while lock was held. Preserving existing bundle and ensuring completion marker.',
          bundleFilePathPerTimestamp,
        );
        if (assetsToCopy) {
          await copyUploadedAssets(assetsToCopy, bundleDirectory);
        }
        // Complete-marker writes are idempotent. This keeps the loser path safe
        // even if the competing writer exits after moving bundle bytes.
        if (!(await isBundleComplete(providedNewBundle.timestamp))) {
          await markBundleComplete(providedNewBundle.timestamp);
        }
        return undefined;
      }

      const msg = formatExceptionMessage(
        renderingRequest,
        error,
        `Unexpected error when preparing the bundle from ${providedNewBundle.bundle.savedFilePath} \
to ${bundleFilePathPerTimestamp}`,
      );
      log.error(msg);
      return errorResponseResult(msg);
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

async function handleNewBundlesProvided(
  renderingRequest: string,
  providedNewBundles: ProvidedNewBundle[],
  assetsToCopy: Asset[] | null | undefined,
): Promise<ResponseResult | undefined> {
  log.info('Worker received new bundles: %s', providedNewBundles);

  const handlingPromises = providedNewBundles.map((providedNewBundle) =>
    handleNewBundleProvided(renderingRequest, providedNewBundle, assetsToCopy),
  );
  // Defensive: use allSettled so that if handleNewBundleProvided ever throws
  // unexpectedly, all in-flight operations still complete before the handler
  // returns and the onResponse hook deletes req.uploadDir. Currently
  // handleNewBundleProvided catches its own errors, so Promise.all would also
  // wait for every promise.
  const settled = await Promise.allSettled(handlingPromises);
  const failures = settled.filter((result): result is PromiseRejectedResult => result.status === 'rejected');
  if (failures.length > 0) {
    failures.forEach((failure, index) => {
      log.error(
        'Bundle upload failed for bundle %d/%d. Error: %s',
        index + 1,
        handlingPromises.length,
        failure.reason instanceof Error ? failure.reason.message : String(failure.reason),
      );
    });

    const failureMessages = failures
      .map((failure) => (failure.reason instanceof Error ? failure.reason.message : String(failure.reason)))
      .join('; ');
    throw new Error(
      `Bundle upload failed for ${failures.length}/${handlingPromises.length} bundles: ${failureMessages}`,
    );
  }

  // handleNewBundleProvided returns undefined on success or a ResponseResult on
  // failure (e.g., lock timeout). Find the first error response, if any.
  const results = settled
    .filter((r): r is PromiseFulfilledResult<ResponseResult | undefined> => r.status === 'fulfilled')
    .map((r) => r.value);
  return results.find((result) => result !== undefined);
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
  tracingContext,
}: {
  renderingRequest: string;
  bundleTimestamp: string | number;
  dependencyBundleTimestamps?: string[] | number[];
  providedNewBundles?: ProvidedNewBundle[] | null;
  assetsToCopy?: Asset[] | null;
  tracingContext?: TracingContext;
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

    // Check if the bundle exists:
    const missingBundles = (
      await Promise.all(
        [...(dependencyBundleTimestamps ?? []), bundleTimestamp].map(async (timestamp) => {
          const bundleFilePath = getRequestBundleFilePath(timestamp);
          const [fileExists, bundleComplete] = await Promise.all([
            fileExistsAsync(bundleFilePath),
            isBundleComplete(timestamp),
          ]);
          return fileExists && bundleComplete ? null : timestamp;
        }),
      )
    ).filter((timestamp) => timestamp !== null);

    if (missingBundles.length > 0) {
      const missingBundlesText = missingBundles.length > 1 ? 'bundles' : 'bundle';
      log.info(`No saved ${missingBundlesText}: ${missingBundles.join(', ')}`);
      return {
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        status: 410,
        data: 'No bundle uploaded',
      };
    }

    // The bundle exists, but the VM has not yet been created.
    // Another worker must have written it or it was saved during deployment.
    log.info('Bundle %s exists. Building VM for worker %s.', entryBundleFilePath, workerIdLabel());
    await Promise.all(allBundleFilePaths.map((bundleFilePath) => buildVM(bundleFilePath)));

    return await prepareResult(renderingRequest, entryBundleFilePath);
  } catch (error) {
    const msg = formatExceptionMessage(
      renderingRequest,
      error,
      'Caught top level error in handleRenderRequest',
    );
    return errorResponseResult(msg, tracingContext);
  }
}
