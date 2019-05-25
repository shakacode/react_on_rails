const path = require('path');
const fs = require('fs');
const fsExtra = require('fs-extra');

const { buildVM, resetVM } = require('../src/worker/vm');

const { buildConfig } = require('../src/shared/configBuilder');

function getFixtureBundle() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

const helper = exports;

helper.BUNDLE_TIMESTAMP = 1495063024898;

/**
 *
 */
helper.setConfig = function setConfig() {
  buildConfig({
    bundlePath: path.resolve(__dirname, './tmp'),
  });
};

helper.vmBundlePath = function vmBundlePath() {
  return path.resolve(__dirname, `./tmp/${helper.BUNDLE_TIMESTAMP}.js`);
};

/**
 *
 * @returns {Promise<void>}
 */
helper.createVmBundle = async function createVmBundle() {
  fsExtra.copySync(getFixtureBundle(), helper.vmBundlePath());
  await buildVM(helper.vmBundlePath());
};

helper.lockfilePath = function lockfilePath() {
  return `${helper.vmBundlePath()}.lock`;
};

helper.uploadedBundlePath = function uploadedBundlePath() {
  return path.resolve(__dirname, `./tmp/uploads/${helper.BUNDLE_TIMESTAMP}.js`);
};

helper.createUploadedBundle = function createUploadedBundle() {
  fsExtra.copySync(getFixtureBundle(), helper.uploadedBundlePath());
};

helper.resetForTest = function resetForTest() {
  if (fs.existsSync(helper.uploadedBundlePath())) fs.unlinkSync(helper.uploadedBundlePath());
  if (fs.existsSync(helper.vmBundlePath())) fs.unlinkSync(helper.vmBundlePath());
  if (fs.existsSync(helper.lockfilePath())) fs.unlinkSync(helper.lockfilePath());
  resetVM();
  helper.setConfig();
};

helper.readRenderingRequest = function readRenderingRequest(projectName, commit, requestDumpFileName) {
  const renderingRequestRelativePath = path.join(
    './fixtures/projects/',
    projectName,
    commit,
    requestDumpFileName,
  );
  return fs.readFileSync(path.resolve(__dirname, renderingRequestRelativePath), 'utf8');
};

helper.createResponse = function createResponse(validate) {
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

helper.setConfig();
