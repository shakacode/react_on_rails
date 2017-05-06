const test  = require('tape');
const path = require('path');
const { buildVM, getBundleUpdateTimeUtc } = require('../src/worker/vm');

test('getBundleUpdateTimeUtc', (assert) => {
  assert.plan(1);
  buildVM(path.resolve(__dirname, './fixtures/bundle.js'));
  assert.ok(getBundleUpdateTimeUtc() !== undefined)
});
