const test = require('tape');
const path = require('path');
const { setConfig, getTmpUploadedBundlePath, createTmpUploadedBundle,
        createUploadedBundle, cleanUploadedBundles } = require('./helper');
const { getBundleFilePath } = require('../src/worker/vm');
const renderRequestHandler = require('../src/worker/renderRequestHandlerVm');
const { resetVM } = require('../src/worker/vm');

test('If gem has posted updated bundle', (assert) => {
  assert.plan(2);
  setConfig();
  createTmpUploadedBundle();

  const req = {
    params: { bundleTimestamp: 1495063024898 },
    body: { renderingRequest: 'ReactOnRails.dummy' },
    files: {
      bundle: {
        file: getTmpUploadedBundlePath(),
      },
    },
  };

  const result = renderRequestHandler(req);

  assert.deepEqual(
    result,
    { status: 200, headers: { 'Cache-Control': 'public, max-age=31536000' }, data: { renderedHtml: 'Dummy Object' } },
    'renderRequestHandler returns status 200 and correct rendered renderedHtmls');
  assert.equal(
    getBundleFilePath(),
    path.resolve(__dirname, './tmp/1495063024898.js'),
    'getBundleFilePath() should return file path of the bundle loaded to VM');

  cleanUploadedBundles();
});

test('If bundle was not uploaded yet', (assert) => {
  assert.plan(1);

  resetVM();
  createUploadedBundle();
  const updateBundleTimestamp = 1495063024899;
  cleanUploadedBundles();

  setConfig();

  const req = {
    files: {},
    params: { bundleTimestamp: updateBundleTimestamp },
    body: { renderingRequest: 'ReactOnRails.dummy' },
  };

  const result = renderRequestHandler(req);

  assert.deepEqual(
    result,
    { status: 410,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      data: 'No bundle uploaded' },
    'renderRequestHandler returns status 410 with "No bundle uploaded"');
});

test('If bundle was already uppdated by another thread', (assert) => {
  assert.plan(1);

  resetVM();
  createUploadedBundle();
  const updateBundleTimestamp = 1495063024898;

  setConfig();

  const req = {
    files: {},
    params: { bundleTimestamp: updateBundleTimestamp },
    body: { renderingRequest: 'ReactOnRails.dummy' },
  };

  const result = renderRequestHandler(req);

  assert.deepEqual(
    result,
    { status: 200, headers: { 'Cache-Control': 'public, max-age=31536000' }, data: { renderedHtml: 'Dummy Object' } },
    'renderRequestHandler returns status 200 and correct rendered renderedHtmls');
});
