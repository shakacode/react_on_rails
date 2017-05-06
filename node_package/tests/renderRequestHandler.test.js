const test = require('tape');
const path = require('path');
const { buildConfig } = require('../src/worker/configBuilder');
const renderRequestHandler = require('../src/worker/renderRequestHandler');

function setConfig() {
  buildConfig({
    bundlePath: path.resolve(__dirname, './tmp')
  });
}

function getUploadedBundlePath() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

test('If gem has posted updated bundle', (assert) => {
  assert.plan(1);

  setConfig();

  const req = {
    body: {
      renderingRequest: 'ReactOnRails.dummy',
    },
    files: {
      bundle: {
        file: getUploadedBundlePath()
      }
    }
  }

  assert.deepEqual(renderRequestHandler(req), { status: 200, data: { renderedHtml: 'Dummy Object' } });
});
