const test = require('tape');
const path = require('path');
const fs = require('fs');
const { buildVM, runInVM, getBundleUpdateTimeUtc } = require('../src/worker/vm');
const { initiConsoleHistory } = require('../src/worker/consoleHistory');

function getBundlePath() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

if (!console._log) initiConsoleHistory();

test('buildVM and runInVM', (assert) => {
  assert.plan(2);
  buildVM(getBundlePath());

  assert.deepEqual(runInVM('ReactOnRails'), { dummy: 'Dummy Object' }, 'ReactOnRails object is availble is sandbox');
  assert.ok(global.ReactOnRails === undefined, 'ReactOnRails object did not leak to global context');
});

test('VM security', (assert) => {
  assert.plan(3);
  buildVM(getBundlePath());

  // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
  assert.throws(
    () => runInVM('process.exit()'),
    /(undefined is not a function|process.exit is not a function)/,
    'VM prevents global access');

  assert.strictEqual(
    runInVM('(function() { return arguments.callee.caller.constructor === Function; })()'),
    true,
    'VM prevents arguments attack');

  assert.throws(
    () => runInVM('(function() { return arguments.callee.caller.caller.toString(); })()'),
    /Cannot read property 'toString' of null/,
    'VM prevents global attack');
});

test('VM console history', (assert) => {
  assert.plan(2);
  buildVM(getBundlePath());

  let vmResult = runInVM('console.log("Console message inside of VM") || console.history;');
  const consoleHistory = [{ level: 'log', arguments: ['[SERVER] Console message inside of VM'] }];
  assert.deepEqual(
    vmResult,
    consoleHistory,
    'Console logging from VM changes history for console inside VM');

  console.history = [];
  vmResult = runInVM('console.log("Console message inside of VM") || console.history;');
  assert.deepEqual(
    console.history,
    consoleHistory,
    'Console logging from VM changes history for console outside of VM');
});

test('getBundleUpdateTimeUtc', (assert) => {
  assert.plan(1);
  buildVM(getBundlePath());
  assert.equal(
    getBundleUpdateTimeUtc(),
    +(fs.statSync(getBundlePath()).mtime),
    'getBundleUpdateTimeUtc() should return last modification time of bundle loaded to VM');
});
