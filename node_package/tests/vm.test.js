const test = require('tape');
const path = require('path');
const fs = require('fs');
const { buildVM, runInVM, getBundleUpdateTimeUtc } = require('../src/worker/vm');

function getBundlePath() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

test('buildVM and runInVM', (assert) => {
  assert.plan(2);
  buildVM(getBundlePath());
  assert.deepEqual(runInVM('ReactOnRails'), { dummy: 'Dummy Object' }, 'ReactOnRails object is availble is sandbox');
  assert.ok(global.ReactOnRails === undefined, 'ReactOnRails object did not leak to global context');
});

test('getBundleUpdateTimeUtc', (assert) => {
  assert.plan(1);
  buildVM(path.resolve(__dirname, './fixtures/bundle.js'));
  assert.equal(
    getBundleUpdateTimeUtc(),
    +(fs.statSync(getBundlePath()).mtime),
    'getBundleUpdateTimeUtc() should return lasty modification time of bundle loaded to VM');
});
