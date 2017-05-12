const path = require('path');
const fs = require('fs');
const fsExtra = require('fs-extra');
const { buildConfig } = require('../src/worker/configBuilder');

/**
 *
 */
function setConfig() {
  buildConfig({
    bundlePath: path.resolve(__dirname, './tmp'),
  });
}

/**
 *
 */
function getTmpUploadedBundlePath() {
  return path.resolve(__dirname, './tmp/uploads/bundle.js');
}

/**
 *
 */
function getUploadedBundlePath() {
  return path.resolve(__dirname, './tmp/bundle.js');
}

/**
 *
 */
function createTmpUploadedBundle() {
  fsExtra.copySync(path.resolve(__dirname, './fixtures/bundle.js'), getTmpUploadedBundlePath());
}

/**
 *
 */
function createUploadedBundle() {
  fsExtra.copySync(path.resolve(__dirname, './fixtures/bundle.js'), getUploadedBundlePath());
}

/**
 *
 */
function cleanUploadedBundles() {
  if (fs.existsSync(getUploadedBundlePath())) fs.unlink(getUploadedBundlePath());
  if (fs.existsSync(getTmpUploadedBundlePath())) fs.unlink(getTmpUploadedBundlePath());
}

exports.setConfig = setConfig;
exports.getTmpUploadedBundlePath = getTmpUploadedBundlePath;
exports.getUploadedBundlePath = getUploadedBundlePath;
exports.createTmpUploadedBundle = createTmpUploadedBundle;
exports.createUploadedBundle = createUploadedBundle;
exports.cleanUploadedBundles = cleanUploadedBundles;
