import path from 'path';
import fs from 'fs';
import fsExtra from 'fs-extra';

const { buildConfig } = require('../src/shared/configBuilder');

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
  return path.resolve(__dirname, './tmp/1495063024898.js');
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
  if (fs.existsSync(getUploadedBundlePath())) fs.unlinkSync(getUploadedBundlePath());
  if (fs.existsSync(getTmpUploadedBundlePath())) fs.unlinkSync(getTmpUploadedBundlePath());
}

/**
 *
 */
function readRenderingRequest(projectName, commit, requestDumpFileName) {
  const renderingRequestRelativePath = path.join('./fixtures/projects/', projectName, commit, requestDumpFileName);
  return fs.readFileSync(path.resolve(__dirname, renderingRequestRelativePath), 'utf8');
}

exports.setConfig = setConfig;
exports.getTmpUploadedBundlePath = getTmpUploadedBundlePath;
exports.getUploadedBundlePath = getUploadedBundlePath;
exports.createTmpUploadedBundle = createTmpUploadedBundle;
exports.createUploadedBundle = createUploadedBundle;
exports.cleanUploadedBundles = cleanUploadedBundles;
exports.readRenderingRequest = readRenderingRequest;
