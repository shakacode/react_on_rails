const test = require('tape');
const path = require('path');
const fs = require('fs');
const { getUploadedBundlePath, createUploadedBundle } = require('./helper');
const { buildVM, runInVM, getBundleFilePath, resetVM } = require('../src/worker/vm');

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

test('VM security', (assert) => {
  assert.plan(1);
  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
  assert.throws(
    () => runInVM('process.exit()'),
    'process is not defined',
    'VM prevents global access');
});

test('resetVM', (assert) => {
  assert.plan(2);
  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  assert.deepEqual(
    runInVM('ReactOnRails'),
    { dummy: 'Dummy Object' },
    'VM context is created');

  resetVM();

  assert.ok(
    getBundleFilePath() === undefined,
    'resetVM() drops file path of the bundle loaded to VM');
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
    'getBundleFilePath() should return file path of the bundle loaded to VM');
});

test('FriendsAndGuestst bundle for commit 1a7fe417', (assert) => {
  assert.plan(3);
  buildVM(path.resolve(__dirname, './fixtures/projects/friendsandguests/1a7fe417/server-bundle.js'));

  // WelcomePage component:
  const welcomePageComponentRenderingRequest = fs.readFileSync(
    path.resolve(__dirname, './fixtures/projects/friendsandguests/1a7fe417/welcomePageRenderingRequest.js'), 'utf8');
  const welcomePageRenderingResult = runInVM(welcomePageComponentRenderingRequest);
  assert.ok(
    welcomePageRenderingResult.includes("data-react-checksum=\\\"800299790\\\""),
    'WelcomePage component has correct checksum');

  // LayoutNavbar component:
  const layoutNavbarComponentRenderingRequest = fs.readFileSync(
    path.resolve(__dirname, './fixtures/projects/friendsandguests/1a7fe417/layoutNavbarRenderingRequest.js'), 'utf8');
  const layoutNavbarRenderingResult = runInVM(layoutNavbarComponentRenderingRequest);
  assert.ok(
    layoutNavbarRenderingResult.includes("data-react-checksum=\\\"-667058792\\\"",
    'LayoutNavbar component has correct checksum'));

  // ListingIndex component:
  const listingIndexComponentRenderingRequest = fs.readFileSync(
    path.resolve(__dirname, './fixtures/projects/friendsandguests/1a7fe417/listingIndexRenderingRequest.js'), 'utf8');
  const listingIndexRenderingResult = runInVM(listingIndexComponentRenderingRequest);
  assert.ok(
    listingIndexRenderingResult.includes("data-react-checksum=\\\"452252439\\\"",
    'ListingIndex component has correct checksum'));
});
