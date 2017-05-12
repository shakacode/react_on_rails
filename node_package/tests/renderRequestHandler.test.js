const test = require('tape');
const path = require('path');
const fs = require('fs');
const { setConfig, getTmpUploadedBundlePath, getUploadedBundlePath, createTmpUploadedBundle,
        createUploadedBundle, cleanUploadedBundles } = require('./helper');
const { getBundleUpdateTimeUtc } = require('../src/worker/vm');
const renderRequestHandler = require('../src/worker/renderRequestHandler');
const { resetVM } = require('../src/worker/vm');

test('If gem has posted updated bundle', (assert) => {
  assert.plan(2);
  setConfig();
  createTmpUploadedBundle();

  const req = {
    body: {
      renderingRequest: 'ReactOnRails.dummy',
    },
    files: {
      bundle: {
        file: getTmpUploadedBundlePath(),
      },
    },
  };

  const result = renderRequestHandler(req);

  assert.deepEqual(
    result,
    { status: 200, data: { renderedHtml: 'Dummy Object' } },
    'renderRequestHandler returns status 200 and correct rendered renderedHtmls');
  assert.equal(
    getBundleUpdateTimeUtc(),
    +(fs.statSync(path.resolve(__dirname, './tmp/bundle.js')).mtime),
    'getBundleUpdateTimeUtc() should return last modification time of bundle loaded to VM');

  cleanUploadedBundles();
});

test('If bundle was not uploaded yet', (assert) => {
  assert.plan(1);

  resetVM();
  createUploadedBundle();
  const updateBundleTimestamp = +(fs.statSync(getUploadedBundlePath()).mtime) + 1;
  cleanUploadedBundles();

  setConfig();

  const req = {
    files: {},
    body: {
      renderingRequest: 'ReactOnRails.dummy',
      bundleUpdateTimeUtc: updateBundleTimestamp,
    },
  };

  const result = renderRequestHandler(req);

  assert.deepEqual(
    result,
    { status: 410, data: 'No bundle uploaded' },
    'renderRequestHandler returns status 410 with "No bundle uploaded"');
});

test('If bundle is outdated', (assert) => {
  assert.plan(1);

  resetVM();
  createUploadedBundle();
  const updateBundleTimestamp = +(fs.statSync(getUploadedBundlePath()).mtime) + 1;

  setConfig();

  const req = {
    files: {},
    body: {
      renderingRequest: 'ReactOnRails.dummy',
      bundleUpdateTimeUtc: updateBundleTimestamp,
    },
  };

  const result = renderRequestHandler(req);

  assert.deepEqual(
    result,
    { status: 410, data: 'Bundle is outdated' },
    'renderRequestHandler returns status 410 with "Bundle is outdated"');
});

test('If bundle was already uppdated by another thread', (assert) => {
  assert.plan(1);

  resetVM();
  createUploadedBundle();
  const updateBundleTimestamp = +(fs.statSync(getUploadedBundlePath()).mtime);

  setConfig();

  const req = {
    files: {},
    body: {
      renderingRequest: 'ReactOnRails.dummy',
      bundleUpdateTimeUtc: updateBundleTimestamp,
    },
  };

  const result = renderRequestHandler(req);

  assert.deepEqual(
    result,
    { status: 200, data: { renderedHtml: 'Dummy Object' } },
    'renderRequestHandler returns status 200 and correct rendered renderedHtmls');
});
