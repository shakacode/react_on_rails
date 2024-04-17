// NOTE: The tmp bundle directory for each test file must be different due to the fact that
// jest will run multiple test files synchronously.
import path from 'path';
import fs from 'fs';
import { promisify } from 'util';
import fsExtra from 'fs-extra';
import { buildVM, resetVM } from '../src/worker/vm';
import { buildConfig } from '../src/shared/configBuilder';

const fsCopyFileAsync = promisify(fs.copyFile);

export const BUNDLE_TIMESTAMP = 1495063024898;
export const ASSET_UPLOAD_FILE = 'loadable-stats.json';
export const ASSET_UPLOAD_OTHER_FILE = 'loadable-stats-other.json';

export function getFixtureBundle() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

export function getFixtureAsset() {
  return path.resolve(__dirname, `./fixtures/${ASSET_UPLOAD_FILE}`);
}

export function getOtherFixtureAsset() {
  return path.resolve(__dirname, `./fixtures/${ASSET_UPLOAD_OTHER_FILE}`);
}

export function bundlePath(testName: string) {
  return path.resolve(__dirname, 'tmp', testName);
}

export function setConfig(testName: string) {
  buildConfig({
    bundlePath: bundlePath(testName),
  });
}

export function vmBundlePath(testName: string) {
  return path.resolve(bundlePath(testName), `${BUNDLE_TIMESTAMP}.js`);
}

export async function createVmBundle(testName: string) {
  await fsCopyFileAsync(getFixtureBundle(), vmBundlePath(testName));
  return buildVM(vmBundlePath(testName));
}

export function lockfilePath(testName: string) {
  return `${vmBundlePath(testName)}.lock`;
}

export function uploadedBundleDir(testName: string) {
  return path.resolve(bundlePath(testName), 'uploads');
}

export function uploadedBundlePath(testName: string) {
  return path.resolve(uploadedBundleDir(testName), `${BUNDLE_TIMESTAMP}.js`);
}

export function assetPath(testName: string) {
  return path.resolve(bundlePath(testName), ASSET_UPLOAD_FILE);
}

export function assetPathOther(testName: string) {
  return path.resolve(bundlePath(testName), ASSET_UPLOAD_OTHER_FILE);
}

export async function createUploadedBundle(testName: string) {
  const mkdirAsync = promisify(fs.mkdir);
  await mkdirAsync(uploadedBundleDir(testName), { recursive: true });
  return fsCopyFileAsync(getFixtureBundle(), uploadedBundlePath(testName));
}

export async function createAsset(testName: string) {
  return fsCopyFileAsync(getFixtureAsset(), assetPath(testName));
}

export async function resetForTest(testName: string) {
  await fsExtra.emptyDir(bundlePath(testName));
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
