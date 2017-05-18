const test = require('tape');
const path = require('path');
const { getUploadedBundlePath, createUploadedBundle } = require('./helper');
const { buildVM, runInVM, getBundleFilePath } = require('../src/worker/vm');

test('buildVM and runInVM', (assert) => {
  assert.plan(10);

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

  runInVM('global.testVar = "test"');
  assert.ok(
    runInVM('this.testVar === "test"'),
    'Variable added through global reference is availble though global "this"');

  assert.ok(
    runInVM('testVar === "test"'),
    'Variable added through global reference is availble directly in global context');

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

test('VM console history', (assert) => {
  assert.plan(1);
  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  const vmResult = runInVM('console.log("Console message inside of VM") || console.history;');
  const consoleHistory = [{ level: 'log', arguments: ['[SERVER] Console message inside of VM'] }];

  assert.deepEqual(
    vmResult,
    consoleHistory,
    'Console logging from VM changes history for console inside VM');
});

test('getBundleFilePath', (assert) => {
  assert.plan(1);
  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  assert.equal(
    getBundleFilePath(),
    path.resolve(__dirname, './tmp/1495063024898.js'),
    'getBundleUpdateTimeUtc() should return last modification time of bundle loaded to VM');
});
