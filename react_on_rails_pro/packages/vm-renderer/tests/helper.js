import path from 'path';
import fs from 'fs';
import fsExtra from 'fs-extra';

import { buildVM, resetVM } from '../src/worker/vm';

const { buildConfig } = require('../src/shared/configBuilder');

function getFixtureBundle() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

export const BUNDLE_TIMESTAMP = 1495063024898;

/**
 *
 */
export function setConfig() {
  buildConfig({
    bundlePath: path.resolve(__dirname, './tmp'),
  });
}

export function vmBundlePath() {
  return path.resolve(__dirname, `./tmp/${BUNDLE_TIMESTAMP}.js`);
}

/**
 *
 * @returns {Promise<void>}
 */
export async function createVmBundle() {
  fsExtra.copySync(getFixtureBundle(), vmBundlePath());
  await buildVM(vmBundlePath());
}

export function lockfilePath() {
  return `${vmBundlePath()}.lock`;
}

export function uploadedBundlePath() {
  return path.resolve(__dirname, `./tmp/uploads/${BUNDLE_TIMESTAMP}.js`);
}

export function createUploadedBundle() {
  fsExtra.copySync(getFixtureBundle(), uploadedBundlePath());
}

export function resetForTest() {
  if (fs.existsSync(uploadedBundlePath())) fs.unlinkSync(uploadedBundlePath());
  if (fs.existsSync(vmBundlePath())) fs.unlinkSync(vmBundlePath());
  if (fs.existsSync(lockfilePath())) fs.unlinkSync(lockfilePath());
  resetVM();
  setConfig();
}

export function readRenderingRequest(projectName, commit, requestDumpFileName) {
  const renderingRequestRelativePath = path.join('./fixtures/projects/', projectName, commit, requestDumpFileName);
  return fs.readFileSync(path.resolve(__dirname, renderingRequestRelativePath), 'utf8');
}

export const createResponse = (validate) => {
  const result = {
    headers: {},
    data: '',
    status: null,
  };

  return {
    set: (key, value) => {
      result.headers[key] = value;
    },
    status: (value) => { result.status = value; },
    send: (data) => {
      result.data = data;
      validate(result);
    },
  };
};
