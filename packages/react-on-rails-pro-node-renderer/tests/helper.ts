// NOTE: The tmp bundle directory for each test file must be different due to the fact that
// jest will run multiple test files synchronously.
import path from 'path';
import fsPromises from 'fs/promises';
import fs from 'fs';
import fsExtra from 'fs-extra';
import { buildVM, resetVM } from '../src/worker/vm';
import { buildConfig } from '../src/shared/configBuilder';

export const mkdirAsync = fsPromises.mkdir;
const safeCopyFileAsync = async (src: string, dest: string) => {
  const parentDir = path.dirname(dest);
  await mkdirAsync(parentDir, { recursive: true });
  await fsPromises.copyFile(src, dest);
};

export const BUNDLE_TIMESTAMP = 1495063024898;
export const SECONDARY_BUNDLE_TIMESTAMP = 1495063024899;
export const ASSET_UPLOAD_FILE = 'loadable-stats.json';
export const ASSET_UPLOAD_OTHER_FILE = 'loadable-stats-other.json';

export function getFixtureBundle() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

export function getFixtureSecondaryBundle() {
  return path.resolve(__dirname, './fixtures/secondary-bundle.js');
}

export function getFixtureAsset() {
  return path.resolve(__dirname, `./fixtures/${ASSET_UPLOAD_FILE}`);
}

export function getOtherFixtureAsset() {
  return path.resolve(__dirname, `./fixtures/${ASSET_UPLOAD_OTHER_FILE}`);
}

export function serverBundleCachePath(testName: string) {
  return path.resolve(__dirname, 'tmp', testName);
}

export function setConfig(testName: string) {
  buildConfig({
    serverBundleCachePath: serverBundleCachePath(testName),
  });
}

export function vmBundlePath(testName: string) {
  return path.resolve(serverBundleCachePath(testName), `${BUNDLE_TIMESTAMP}`, `${BUNDLE_TIMESTAMP}.js`);
}

export function vmSecondaryBundlePath(testName: string) {
  return path.resolve(
    serverBundleCachePath(testName),
    `${SECONDARY_BUNDLE_TIMESTAMP}`,
    `${SECONDARY_BUNDLE_TIMESTAMP}.js`,
  );
}

export async function createVmBundle(testName: string) {
  await safeCopyFileAsync(getFixtureBundle(), vmBundlePath(testName));
  return buildVM(vmBundlePath(testName));
}

export async function createSecondaryVmBundle(testName: string) {
  await safeCopyFileAsync(getFixtureSecondaryBundle(), vmSecondaryBundlePath(testName));
  return buildVM(vmSecondaryBundlePath(testName));
}

export function lockfilePath(testName: string) {
  return `${vmBundlePath(testName)}.lock`;
}

export function secondaryLockfilePath(testName: string) {
  return `${vmSecondaryBundlePath(testName)}.lock`;
}

export function uploadedBundleDir(testName: string) {
  return path.resolve(serverBundleCachePath(testName), 'uploads');
}

export function uploadedBundlePath(testName: string) {
  return path.resolve(uploadedBundleDir(testName), `${BUNDLE_TIMESTAMP}.js`);
}

export function uploadedSecondaryBundlePath(testName: string) {
  return path.resolve(uploadedBundleDir(testName), `${SECONDARY_BUNDLE_TIMESTAMP}.js`);
}

export function uploadedAssetPath(testName: string) {
  return path.resolve(uploadedBundleDir(testName), ASSET_UPLOAD_FILE);
}

export function uploadedAssetOtherPath(testName: string) {
  return path.resolve(uploadedBundleDir(testName), ASSET_UPLOAD_OTHER_FILE);
}

export function assetPath(testName: string, bundleTimestamp: string) {
  return path.resolve(serverBundleCachePath(testName), bundleTimestamp, ASSET_UPLOAD_FILE);
}

export function assetPathOther(testName: string, bundleTimestamp: string) {
  return path.resolve(serverBundleCachePath(testName), bundleTimestamp, ASSET_UPLOAD_OTHER_FILE);
}

export async function createUploadedBundle(testName: string) {
  await mkdirAsync(uploadedBundleDir(testName), { recursive: true });
  return safeCopyFileAsync(getFixtureBundle(), uploadedBundlePath(testName));
}

export async function createUploadedSecondaryBundle(testName: string) {
  await mkdirAsync(uploadedBundleDir(testName), { recursive: true });
  return safeCopyFileAsync(getFixtureSecondaryBundle(), uploadedSecondaryBundlePath(testName));
}

export async function createUploadedAsset(testName: string) {
  await mkdirAsync(uploadedBundleDir(testName), { recursive: true });
  return Promise.all([
    safeCopyFileAsync(getFixtureAsset(), uploadedAssetPath(testName)),
    safeCopyFileAsync(getOtherFixtureAsset(), uploadedAssetOtherPath(testName)),
  ]);
}

export async function createAsset(testName: string, bundleTimestamp: string) {
  return Promise.all([
    safeCopyFileAsync(getFixtureAsset(), assetPath(testName, bundleTimestamp)),
    safeCopyFileAsync(getOtherFixtureAsset(), assetPathOther(testName, bundleTimestamp)),
  ]);
}

export async function resetForTest(testName: string) {
  await fsExtra.emptyDir(serverBundleCachePath(testName));
  resetVM();
  setConfig(testName);
}

export function readRenderingRequest(projectName: string, commit: string, requestDumpFileName: string) {
  const renderingRequestRelativePath = path.join(
    './fixtures/projects/',
    projectName,
    commit,
    requestDumpFileName,
  );
  return fs.readFileSync(path.resolve(__dirname, renderingRequestRelativePath), 'utf8');
}

/**
 * Custom waitFor function that retries an expect statement until it passes or timeout is reached
 * @param expectFn - Function containing Jest expect statements
 * @param options - Configuration options
 * @param options.timeout - Maximum time to wait in milliseconds (default: 1000)
 * @param options.interval - Time between retries in milliseconds (default: 10)
 * @param options.message - Custom error message when timeout is reached
 */
export const waitFor = async (
  expectFn: () => void,
  options: {
    timeout?: number;
    interval?: number;
    message?: string;
  } = {},
): Promise<void> => {
  const { timeout = 1000, interval = 10, message } = options;
  const startTime = Date.now();
  let lastError: Error | null = null;

  while (Date.now() - startTime < timeout) {
    try {
      expectFn();
      // If we get here, the expect passed, so we can return
      return;
    } catch (error) {
      lastError = error as Error;
      // Expect failed, continue retrying
      if (Date.now() - startTime >= timeout) {
        // Timeout reached, re-throw the last error
        throw error;
      }
    }

    // Wait before next retry
    // eslint-disable-next-line no-await-in-loop
    await new Promise<void>((resolve) => {
      setTimeout(resolve, interval);
    });
  }

  // Timeout reached, throw error with descriptive message
  const defaultMessage = `Expect condition not met within ${timeout}ms`;
  throw new Error(message || defaultMessage + (lastError ? `\nLast error: ${lastError.message}` : ''));
};

setConfig('helper');
