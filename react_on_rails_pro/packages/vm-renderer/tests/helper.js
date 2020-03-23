// NOTE: The tmp bundle directory for each test file must be different due to the fact that
// jest will run multiple test files synchronously.
const path = require('path');
const fs = require('fs');
const { promisify } = require('util');
const fsExtra = require('fs-extra');

const fsCopyFileAsync = promisify(fs.copyFile);

const { buildVM, resetVM } = require('../src/worker/vm');

const { buildConfig } = require('../src/shared/configBuilder');

exports.BUNDLE_TIMESTAMP = 1495063024898;

exports.ASSET_UPLOAD_FILE = 'loadable-stats.json';
exports.ASSET_UPLOAD_OTHER_FILE = 'loadable-stats-other.json';

exports.getFixtureBundle = function getFixtureBundle() {
  return path.resolve(__dirname, './fixtures/bundle.js');
};

exports.getFixtureAsset = function getFixtureAsset() {
  return path.resolve(__dirname, `./fixtures/${exports.ASSET_UPLOAD_FILE}`);
};

exports.getOtherFixtureAsset = function getOtherFixtureAsset() {
  return path.resolve(__dirname, `./fixtures/${exports.ASSET_UPLOAD_OTHER_FILE}`);
};

exports.bundlePath = function bundlePath(testName) {
  return path.resolve(__dirname, 'tmp', testName);
};

exports.setConfig = function setConfig(testName) {
  buildConfig({
    bundlePath: exports.bundlePath(testName),
  });
};

/**
 *
 * @returns {Promise<void>}
 */
exports.createVmBundle = async function createVmBundle(testName) {
  await fsCopyFileAsync(exports.getFixtureBundle(), exports.vmBundlePath(testName));
  return buildVM(exports.vmBundlePath(testName));
};

exports.lockfilePath = function lockfilePath(testName) {
  return `${exports.vmBundlePath(testName)}.lock`;
};

exports.uploadedBundleDir = function uploadedBundleDir(testName) {
  return path.resolve(exports.bundlePath(testName), 'uploads');
};

exports.uploadedBundlePath = function uploadedBundlePath(testName) {
  return path.resolve(exports.uploadedBundleDir(testName), `${exports.BUNDLE_TIMESTAMP}.js`);
};

exports.vmBundlePath = function vmBundlePath(testName) {
  return path.resolve(exports.bundlePath(testName), `${exports.BUNDLE_TIMESTAMP}.js`);
};

exports.assetPath = function assetPath(testName) {
  return path.resolve(exports.bundlePath(testName), exports.ASSET_UPLOAD_FILE);
};

exports.assetPathOther = function assetPathOther(testName) {
  return path.resolve(exports.bundlePath(testName), exports.ASSET_UPLOAD_OTHER_FILE);
};

exports.createUploadedBundle = async function createUploadedBundle(testName) {
  const mkdirAsync = promisify(fs.mkdir);
  await mkdirAsync(exports.uploadedBundleDir(testName), { recursive: true });
  return fsCopyFileAsync(exports.getFixtureBundle(), exports.uploadedBundlePath(testName));
};

exports.createAsset = async function createAsset(testName) {
  return fsCopyFileAsync(exports.getFixtureAsset(), exports.assetPath(testName));
};

exports.resetForTest = async function resetForTest(testName) {
  await fsExtra.emptyDir(exports.bundlePath(testName));
  resetVM();
  exports.setConfig(testName);
};

exports.readRenderingRequest = function readRenderingRequest(projectName, commit, requestDumpFileName) {
  const renderingRequestRelativePath = path.join(
    './fixtures/projects/',
    projectName,
    commit,
    requestDumpFileName,
  );
  return fs.readFileSync(path.resolve(__dirname, renderingRequestRelativePath), 'utf8');
};

exports.createResponse = function createResponse(validate) {
  const result = {
    headers: {},
    data: '',
    status: null,
  };

  return {
    set: (key, value) => {
      result.headers[key] = value;
    },
    status: value => {
      result.status = value;
    },
    send: data => {
      result.data = data;
      validate(result);
    },
  };
};

exports.setConfig('helper');
