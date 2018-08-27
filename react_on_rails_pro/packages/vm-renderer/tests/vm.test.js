import test from 'tape';
import path from 'path';
import {
  uploadedBundlePath,
  createUploadedBundle,
  readRenderingRequest,
  createVmBundle,
} from './helper';
import { buildVM, runInVM, getVmBundleFilePath, resetVM } from '../src/worker/vm';

test('buildVM and runInVM', async (assert) => {
  assert.plan(14);

  createUploadedBundle();
  await buildVM(uploadedBundlePath());

  let result = await runInVM('ReactOnRails');
  assert.deepEqual(
    result,
    { dummy: { html: 'Dummy Object' } },
    'ReactOnRails object is availble is sandbox',
  );

  assert.ok(
    global.ReactOnRails === undefined,
    'ReactOnRails object did not leak to global context',
  );

  result = await runInVM('typeof global !== undefined');
  assert.ok(
    result,
    'global object is defined in VM context',
  );

  result = await runInVM('Math === global.Math');
  assert.ok(
    result,
    'global object points to global VM context',
  );

  result = await runInVM('ReactOnRails === global.ReactOnRails');
  assert.ok(
    result,
    'New objects added to global context are accessible by global reference',
  );

  await runInVM('global.testVar = "test"');
  result = await runInVM('this.testVar === "test"');
  assert.ok(
    result,
    'Variable added through global reference is available though global "this"',
  );

  result = await runInVM('testVar === "test"');
  assert.ok(
    result,
    'Variable added through global reference is availble directly in global context',
  );

  result = await runInVM('console');
  assert.ok(
    result !== console,
    'VM context has its own console',
  );

  assert.ok(
    console.history === undefined,
    'Building VM does not mutate console in master code',
  );

  result = await runInVM('console.history !== undefined');
  assert.ok(
    result,
    'VM has patched console with history',
  );

  result = await runInVM('getStackTrace !== undefined');
  assert.ok(
    result,
    'getStackTrace function is availble is sandbox',
  );

  result = await runInVM('setInterval !== undefined');
  assert.ok(
    result,
    'setInterval function is availble is sandbox',
  );

  result = await runInVM('setTimeout !== undefined');
  assert.ok(
    result,
    'setTimeout function is availble is sandbox',
  );

  result = await runInVM('clearTimeout !== undefined');
  assert.ok(
    result,
    'clearTimeout function is availble is sandbox',
  );
});

test('VM security and captured exceptions', async (assert) => {
  assert.plan(1);
  createUploadedBundle();
  await buildVM(uploadedBundlePath());
  // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
  const result = await runInVM('process.exit()');
  assert.ok(
    result.exceptionMessage.match(/process is not defined/),
    'Expected captured exception b/c VM prevents global access',
  );
});

test('Captured exceptions for a long message', async (assert) => {
  assert.plan(4);
  createUploadedBundle();
  await buildVM(uploadedBundlePath());
  // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
  const code = `process.exit()${
    '\n// 1234567890123456789012345678901234567890'.repeat(50)
  }\n// Finishing Comment`;
  const { exceptionMessage } = await runInVM(code);
  assert.ok(
    exceptionMessage.match(/process is not defined/),
    'Expected error message in error result',
  );
  assert.ok(
    exceptionMessage.match(/process.exit/),
    'Expected captured code to contain beginning',
  );
  assert.ok(
    exceptionMessage.match(/Finishing Comment/),
    'Expected captured code to contain end',
  );
  assert.ok(
    exceptionMessage.match(/\.\.\./),
    'Expected captured code to contain ...',
  );
});

test('resetVM', async (assert) => {
  assert.plan(2);
  createUploadedBundle();
  buildVM(uploadedBundlePath());

  const result = await runInVM('ReactOnRails');
  assert.deepEqual(
    result,
    { dummy: { html: 'Dummy Object' } },
    'VM context is created',
  );

  resetVM();

  assert.ok(
    getVmBundleFilePath() === undefined,
    'resetVM() drops file path of the bundle loaded to VM',
  );
});

test('VM console history', async (assert) => {
  assert.plan(1);
  createUploadedBundle();
  buildVM(uploadedBundlePath());

  const vmResult = await runInVM('console.log("Console message inside of VM") || console.history;');
  const consoleHistory = [{ level: 'log', arguments: ['[SERVER] Console message inside of VM'] }];

  assert.deepEqual(
    vmResult,
    consoleHistory,
    'Console logging from VM changes history for console inside VM',
  );
});

test('getVmBundleFilePath', async (assert) => {
  assert.plan(1);
  await createVmBundle();

  assert.equal(
    getVmBundleFilePath(),
    path.resolve(__dirname, './tmp/1495063024898.js'),
    'getVmBundleFilePath() should return file path of the bundle loaded to VM',
  );
});

test('FriendsAndGuests bundle for commit 1a7fe417', async (assert) => {
  assert.plan(5);

  const project = 'friendsandguests';
  const commit = '1a7fe417';

  await buildVM(path.resolve(__dirname, './fixtures/projects/friendsandguests/1a7fe417/server-bundle.js'));

  // WelcomePage component:
  const welcomePageComponentRenderingRequest = readRenderingRequest(project, commit, 'welcomePageRenderingRequest.js');
  const welcomePageRenderingResult = await runInVM(welcomePageComponentRenderingRequest);
  assert.ok(
    welcomePageRenderingResult.includes('data-react-checksum=\\"800299790\\"'),
    'WelcomePage component has correct checksum',
  );

  // LayoutNavbar component:
  const layoutNavbarComponentRenderingRequest =
    readRenderingRequest(project, commit, 'layoutNavbarRenderingRequest.js');
  const layoutNavbarRenderingResult = await runInVM(layoutNavbarComponentRenderingRequest);
  assert.ok(
    layoutNavbarRenderingResult.includes('data-react-checksum=\\"-667058792\\"'),
    'LayoutNavbar component has correct checksum',
  );

  // ListingIndex component:
  const listingIndexComponentRenderingRequest =
    readRenderingRequest(project, commit, 'listingIndexRenderingRequest.js');
  const listingIndexRenderingResult = await runInVM(listingIndexComponentRenderingRequest);
  assert.ok(
    listingIndexRenderingResult.includes('data-react-checksum=\\"452252439\\"'),
    'ListingIndex component has correct checksum',
  );

  // ListingShow component:
  const listingShowComponentRenderingRequest = readRenderingRequest(project, commit, 'listingsShowRenderingRequest.js');
  const listingShowRenderingResult = await runInVM(listingShowComponentRenderingRequest);
  assert.ok(
    listingShowRenderingResult.includes('data-react-checksum=\\"-324043796\\"'),
    'ListingShow component has correct checksum',
  );

  // UserShow component:
  const userShowComponentRenderingRequest = readRenderingRequest(project, commit, 'userShowRenderingRequest.js');
  const userShowRenderingResult = await runInVM(userShowComponentRenderingRequest);
  assert.ok(
    userShowRenderingResult.includes('data-react-checksum=\\"-1039690194\\"'),
    'UserShow component has correct checksum',
  );
});

test('ReactWebpackRailsTutorial bundle for commit ec974491', async (assert) => {
  assert.plan(3);

  const project = 'react-webpack-rails-tutorial';
  const commit = 'ec974491';

  await buildVM(path.resolve(__dirname, './fixtures/projects/react-webpack-rails-tutorial/ec974491/server-bundle.js'));

  // NavigationBar component:
  const navigationBarComponentRenderingRequest =
    readRenderingRequest(project, commit, 'navigationBarAppRenderingRequest.js');
  const navigationBarRenderingResult = await runInVM(navigationBarComponentRenderingRequest);
  assert.ok(
    navigationBarRenderingResult.includes('data-react-checksum=\\"-472831860\\"'),
    'NavigationBar component has correct checksum',
  );

  // RouterApp component:
  const routerAppComponentRenderingRequest = readRenderingRequest(project, commit, 'routerAppRenderingRequest.js');
  const routerAppRenderingResult = await runInVM(routerAppComponentRenderingRequest);
  assert.ok(
    routerAppRenderingResult.includes('data-react-checksum=\\"-1777286250\\"'),
    'RouterApp component has correct checksum',
  );

  // App component:
  const appComponentRenderingRequest = readRenderingRequest(project, commit, 'appRenderingRequest.js');
  const appRenderingResult = await runInVM(appComponentRenderingRequest);
  assert.ok(
    appRenderingResult.includes('data-react-checksum=\\"-490396040\\"'),
    'App component has correct checksum',
  );
});

test('BionicWorkshop bundle for commit fa6ccf6b', async (assert) => {
  assert.plan(4);

  const project = 'bionicworkshop';
  const commit = 'fa6ccf6b';

  await buildVM(path.resolve(__dirname, './fixtures/projects/bionicworkshop/fa6ccf6b/server-bundle.js'));

  // SignIn page with flash component:
  const signInPageWithFlashRenderingRequest = readRenderingRequest(project, commit, 'signInPageWithFlashRenderingRequest.js');
  const signInPageWithFlashRenderingResult = await runInVM(signInPageWithFlashRenderingRequest);

  // We don't put checksum here since it changes for every request with Rails auth token:
  assert.ok(
    signInPageWithFlashRenderingResult.includes('data-react-checksum='),
    'SignIn page with flash component has correct checksum',
  );

  // Landing page component:
  const landingPageRenderingRequest = readRenderingRequest(project, commit, 'landingPageRenderingRequest.js');
  const landingPageRenderingResult = await runInVM(landingPageRenderingRequest);
  assert.ok(
    landingPageRenderingResult.includes('data-react-checksum=\\"-1899958456\\"'),
    'Landing page component has correct checksum',
  );

  // Post page component:
  const postPageRenderingRequest = readRenderingRequest(project, commit, 'postPageRenderingRequest.js');
  const postPageRenderingResult = await runInVM(postPageRenderingRequest);
  assert.ok(
    postPageRenderingResult.includes('data-react-checksum=\\"-1296077150\\"'),
    'Post page component has correct checksum',
  );

  // Authors page component:
  const authorsPageRenderingRequest = readRenderingRequest(project, commit, 'authorsPageRenderingRequest.js');
  const authorsPageRenderingResult = await runInVM(authorsPageRenderingRequest);
  assert.ok(
    authorsPageRenderingResult.includes('data-react-checksum=\\"-1066737665\\"'),
    'Authors page component has correct checksum',
  );
});
