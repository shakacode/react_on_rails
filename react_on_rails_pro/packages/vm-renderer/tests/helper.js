const path = require('path');
const fs = require('fs');
const fsExtra = require('fs-extra');

const { buildVM, resetVM } = require('../lib/worker/vm');

const { buildConfig } = require('../lib/shared/configBuilder');

function getFixtureBundle() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

const helper = exports;

helper.BUNDLE_TIMESTAMP = 1495063024898;

/**
 *
 */
helper.setConfig = function() {
  buildConfig({
    bundlePath: path.resolve(__dirname, './tmp'),
  });
};

helper.vmBundlePath = function() {
  return path.resolve(__dirname, `./tmp/${BUNDLE_TIMESTAMP}.js`);
};

/**
 *
 * @returns {Promise<void>}
 */
helper.createVmBundle = async function() {
  fsExtra.copySync(getFixtureBundle(), vmBundlePath());
  await buildVM(vmBundlePath());
};

helper.lockfilePath = function() {
  return `${vmBundlePath()}.lock`;
};

helper.uploadedBundlePath = function() {
  return path.resolve(__dirname, `./tmp/uploads/${BUNDLE_TIMESTAMP}.js`);
};

helper.createUploadedBundle = function() {
  fsExtra.copySync(getFixtureBundle(), uploadedBundlePath());
};

helper.resetForTest = function() {
  if (fs.existsSync(uploadedBundlePath())) fs.unlinkSync(uploadedBundlePath());
  if (fs.existsSync(vmBundlePath())) fs.unlinkSync(vmBundlePath());
  if (fs.existsSync(lockfilePath())) fs.unlinkSync(lockfilePath());
  resetVM();
  setConfig();
};

helper.readRenderingRequest = function(projectName, commit, requestDumpFileName) {
  const renderingRequestRelativePath = path.join(
    './fixtures/projects/',
    projectName,
    commit,
    requestDumpFileName,
  );
  return fs.readFileSync(path.resolve(__dirname, renderingRequestRelativePath), 'utf8');
};

helper.createResponse = function(validate) {
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
