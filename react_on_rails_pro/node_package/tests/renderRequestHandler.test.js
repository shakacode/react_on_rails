const test = require('tape');
const path = require('path');
const fs = require('fs');
const { buildConfig } = require('../src/worker/configBuilder');
const { getBundleUpdateTimeUtc } = require('../src/worker/vm');
const renderRequestHandler = require('../src/worker/renderRequestHandler');

function setConfig() {
  buildConfig({
    bundlePath: path.resolve(__dirname, './tmp'),
  });
}

function cleanUploadedBundle() {
  fs.unlink(path.resolve(__dirname, './tmp/bundle.js'));
}

function getTmpUploadedBundlePath() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

test('If gem has posted updated bundle', (assert) => {
  assert.plan(2);
  setConfig();

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
});

test('If bundle was not uploaded yet', (assert) => {
  assert.plan(1);
  const updateBundleTimestamp = +(fs.statSync(path.resolve(__dirname, './tmp/bundle.js')).mtime) + 1;

  cleanUploadedBundle();
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
