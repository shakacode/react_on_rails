const test = require('tape');
const path = require('path');
const { getUploadedBundlePath, createUploadedBundle, readRenderingRequest } = require('./helper');
const { buildVM, runInVM, getBundleFilePath, resetVM } = require('../src/worker/vm');

test('buildVM and runInVM', (assert) => {
  assert.plan(14);

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

  assert.ok(
    runInVM('getStackTrace !== undefined'),
    'getStackTrace function is availble is sandbox');

  assert.ok(
    runInVM('setInterval !== undefined'),
    'setInterval function is availble is sandbox');

  assert.ok(
    runInVM('setTimeout !== undefined'),
    'setTimeout function is availble is sandbox');

  assert.ok(
    runInVM('clearTimeout !== undefined'),
    'clearTimeout function is availble is sandbox');
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
  assert.plan(5);

  const project = 'friendsandguests';
  const commit = '1a7fe417';

  buildVM(path.resolve(__dirname, './fixtures/projects/friendsandguests/1a7fe417/server-bundle.js'));

  // WelcomePage component:
  const welcomePageComponentRenderingRequest = readRenderingRequest(project, commit, 'welcomePageRenderingRequest.js');
  const welcomePageRenderingResult = runInVM(welcomePageComponentRenderingRequest);
  assert.ok(
    welcomePageRenderingResult.includes('data-react-checksum=\\"800299790\\"'),
    'WelcomePage component has correct checksum');

  // LayoutNavbar component:
  const layoutNavbarComponentRenderingRequest =
    readRenderingRequest(project, commit, 'layoutNavbarRenderingRequest.js');
  const layoutNavbarRenderingResult = runInVM(layoutNavbarComponentRenderingRequest);
  assert.ok(
    layoutNavbarRenderingResult.includes('data-react-checksum=\\"-667058792\\"'),
    'LayoutNavbar component has correct checksum');

  // ListingIndex component:
  const listingIndexComponentRenderingRequest =
    readRenderingRequest(project, commit, 'listingIndexRenderingRequest.js');
  const listingIndexRenderingResult = runInVM(listingIndexComponentRenderingRequest);
  assert.ok(
    listingIndexRenderingResult.includes('data-react-checksum=\\"452252439\\"'),
    'ListingIndex component has correct checksum');

  // ListingShow component:
  const listingShowComponentRenderingRequest = readRenderingRequest(project, commit, 'listingsShowRenderingRequest.js');
  const listingShowRenderingResult = runInVM(listingShowComponentRenderingRequest);
  assert.ok(
    listingShowRenderingResult.includes('data-react-checksum=\\"-324043796\\"'),
    'ListingShow component has correct checksum');

  // UserShow component:
  const userShowComponentRenderingRequest = readRenderingRequest(project, commit, 'userShowRenderingRequest.js');
  const userShowRenderingResult = runInVM(userShowComponentRenderingRequest);
  assert.ok(
    userShowRenderingResult.includes('data-react-checksum=\\"-1039690194\\"'),
    'UserShow component has correct checksum');
});

test('ReactWebpackRailsTutorial bundle for commit ec974491', (assert) => {
  assert.plan(3);

  const project = 'react-webpack-rails-tutorial';
  const commit = 'ec974491';

  buildVM(path.resolve(__dirname, './fixtures/projects/react-webpack-rails-tutorial/ec974491/server-bundle.js'));

  // NavigationBar component:
  const navigationBarComponentRenderingRequest =
    readRenderingRequest(project, commit, 'navigationBarAppRenderingRequest.js');
  const navigationBarRenderingResult = runInVM(navigationBarComponentRenderingRequest);
  assert.ok(
    navigationBarRenderingResult.includes('data-react-checksum=\\"-472831860\\"'),
    'NavigationBar component has correct checksum');

  // RouterApp component:
  const routerAppComponentRenderingRequest = readRenderingRequest(project, commit, 'routerAppRenderingRequest.js');
  const routerAppRenderingResult = runInVM(routerAppComponentRenderingRequest);
  assert.ok(
    routerAppRenderingResult.includes('data-react-checksum=\\"-1777286250\\"'),
    'RouterApp component has correct checksum');

  // App component:
  const appComponentRenderingRequest = readRenderingRequest(project, commit, 'appRenderingRequest.js');
  const appRenderingResult = runInVM(appComponentRenderingRequest);
  assert.ok(
    appRenderingResult.includes('data-react-checksum=\\"-490396040\\"'),
    'App component has correct checksum');
});

test('BionicWorkshop bundle for commit fa6ccf6b', (assert) => {
  assert.plan(4);

  const project = 'bionicworkshop';
  const commit = 'fa6ccf6b';

  buildVM(path.resolve(__dirname, './fixtures/projects/bionicworkshop/fa6ccf6b/server-bundle.js'));

  // SignIn page with flash component:
  const signInPageWithFlashRenderingRequest = readRenderingRequest(project, commit, 'signInPageWithFlashRenderingRequest.js');
  const signInPageWithFlashRenderingResult = runInVM(signInPageWithFlashRenderingRequest);

  // We don't put checksum here since it changes for every request with Rails auth token:
  assert.ok(
    signInPageWithFlashRenderingResult.includes('data-react-checksum='),
    'SignIn page with flash component has correct checksum');

  // Landing page component:
  const landingPageRenderingRequest = readRenderingRequest(project, commit, 'landingPageRenderingRequest.js');
  const landingPageRenderingResult = runInVM(landingPageRenderingRequest);
  assert.ok(
    landingPageRenderingResult.includes('data-react-checksum=\\"-1899958456\\"'),
    'Landing page component has correct checksum');

  // Post page component:
  const postPageRenderingRequest = readRenderingRequest(project, commit, 'postPageRenderingRequest.js');
  const postPageRenderingResult = runInVM(postPageRenderingRequest);
  assert.ok(
    postPageRenderingResult.includes('data-react-checksum=\\"-1296077150\\"'),
    'Post page component has correct checksum');

  // Authors page component:
  const authorsPageRenderingRequest = readRenderingRequest(project, commit, 'authorsPageRenderingRequest.js');
  const authorsPageRenderingResult = runInVM(authorsPageRenderingRequest);
  assert.ok(
    authorsPageRenderingResult.includes('data-react-checksum=\\"-1066737665\\"'),
    'Authors page component has correct checksum');
});
