const test = require('tape');
const fs = require('fs');
const { getUploadedBundlePath, createUploadedBundle } = require('./helper');
const { buildVM, runInVM, getBundleUpdateTimeUtc } = require('../src/worker/sandbox');
const { initiConsoleHistory } = require('../src/worker/consoleHistory');

if (!console.history) initiConsoleHistory();

test('buildVM and runInVM', (assert) => {
  assert.plan(2);
  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  assert.deepEqual(runInVM('ReactOnRails'), { dummy: 'Dummy Object' }, 'ReactOnRails object is availble is sandbox');
  assert.ok(global.ReactOnRails === undefined, 'ReactOnRails object did not leak to global context');
});

test('Sandbox security', (assert) => {
  assert.plan(3);
  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  assert.equal(
    runInVM('process.exit'),
    process.exit,
    'Sandbox has access to process globals and able to stop the process');

  assert.strictEqual(
    runInVM('(function() { return arguments.callee.caller.constructor === Function; })()'),
    false,
    'Sandbox does not prevent arguments attack');

  assert.throws(
    () => runInVM('(function() { return arguments.callee.caller.caller.toString(); })()'),
    /Cannot read property 'toString' of null/,
    'Sandbox prevents global attack');
});

test('Sandbox console history', (assert) => {
  assert.plan(2);
  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  let vmResult = runInVM('console.log("Console message inside of Sandbox") || console.history;');
  const consoleHistory = [{ level: 'log', arguments: ['[SERVER] Console message inside of Sandbox'] }];
  assert.deepEqual(
    vmResult,
    consoleHistory,
    'Console logging from Sandbox changes history for console inside Sandbox');

  console.history = [];
  vmResult = runInVM('console.log("Console message inside of Sandbox") || console.history;');
  assert.deepEqual(
    console.history,
    consoleHistory,
    'Console logging from Sandbox changes history for console outside of Sandbox');
});

test('getBundleUpdateTimeUtc', (assert) => {
  assert.plan(1);
  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  assert.equal(
    getBundleUpdateTimeUtc(),
    +(fs.statSync(getUploadedBundlePath()).mtime),
    'getBundleUpdateTimeUtc() should return last modification time of bundle loaded to Sandbox');
});
