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

setConfig('helper');
