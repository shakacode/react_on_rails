const test = require('tape');
const path = require('path');
const fs = require('fs');
const { buildVM, runInVM, getBundleUpdateTimeUtc } = require('../src/worker/vm');

function getBundlePath() {
  return path.resolve(__dirname, './fixtures/bundle.js');
}

test('buildVM and runInVM', (assert) => {
  assert.plan(5);
  buildVM(getBundlePath());

  assert.deepEqual(runInVM('ReactOnRails'), { dummy: 'Dummy Object' }, 'ReactOnRails object is availble is sandbox');
  assert.ok(global.ReactOnRails === undefined, 'ReactOnRails object did not leak to global context');

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

test('getBundleUpdateTimeUtc', (assert) => {
  assert.plan(1);
  buildVM(path.resolve(__dirname, './fixtures/bundle.js'));
  assert.equal(
    getBundleUpdateTimeUtc(),
    +(fs.statSync(getBundlePath()).mtime),
    'getBundleUpdateTimeUtc() should return last modification time of bundle loaded to VM');
});
