const test = require('tape');
const fs = require('fs');
const { getUploadedBundlePath, createUploadedBundle } = require('./helper');
const { buildVM, runInVM, getBundleFilePath } = require('../src/worker/vm');

test('buildVM and runInVM', (assert) => {
  assert.plan(8);

  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  assert.deepEqual(
    runInVM('ReactOnRails'),
    { dummy: 'Dummy Object' },
    'ReactOnRails object is availble is sandbox');

  assert.ok(
    global.ReactOnRails === undefined,
    'ReactOnRails object did not leak to global context');

  assert.ok(
    runInVM('typeof global !== undefined'),
    'global object is defined in VM context');

  assert.ok(
    runInVM('Math === global.Math'),
    'global object points to global VM context');

  assert.ok(
    runInVM('ReactOnRails === global.ReactOnRails'),
    'New objects added to global context are accessible by global reference');

  assert.ok(
    runInVM('console') !== console,
    'VM context has its own console');

  assert.ok(
    console.history === undefined,
    'Building VM does not mutate console in master code');

  assert.ok(
    runInVM('console.history !== undefined'),
    'VM has patched console with history');
});
