const path = require('path');
const {
  uploadedBundlePath,
  createUploadedBundle,
  readRenderingRequest,
  createVmBundle,
} = require('./helper');
const { buildVM, runInVM, getVmBundleFilePath, resetVM } = require('../lib/worker/vm');

test('buildVM and runInVM', async () => {
  expect.assertions(14);

  createUploadedBundle();
  await buildVM(uploadedBundlePath());

  let result = await runInVM('ReactOnRails');
  expect(result).toEqual({ dummy: { html: 'Dummy Object' } });

  expect(global.ReactOnRails === undefined).toBeTruthy();

  result = await runInVM('typeof global !== undefined');
  expect(result).toBeTruthy();

  result = await runInVM('Math === global.Math');
  expect(result).toBeTruthy();

  result = await runInVM('ReactOnRails === global.ReactOnRails');
  expect(result).toBeTruthy();

  await runInVM('global.testVar = "test"');
  result = await runInVM('this.testVar === "test"');
  expect(result).toBeTruthy();

  result = await runInVM('testVar === "test"');
  expect(result).toBeTruthy();

  result = await runInVM('console');
  expect(result !== console).toBeTruthy();

  expect(console.history === undefined).toBeTruthy();

  result = await runInVM('console.history !== undefined');
  expect(result).toBeTruthy();

  result = await runInVM('getStackTrace !== undefined');
  expect(result).toBeTruthy();

  result = await runInVM('setInterval !== undefined');
  expect(result).toBeTruthy();

  result = await runInVM('setTimeout !== undefined');
  expect(result).toBeTruthy();

  result = await runInVM('clearTimeout !== undefined');
  expect(result).toBeTruthy();
});

test('VM security and captured exceptions', async () => {
  expect.assertions(1);
  createUploadedBundle();
  await buildVM(uploadedBundlePath());
  // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
  const result = await runInVM('process.exit()');
  expect(result.exceptionMessage.match(/process is not defined/)).toBeTruthy();
});

test('Captured exceptions for a long message', async () => {
  expect.assertions(4);
  createUploadedBundle();
  await buildVM(uploadedBundlePath());
  // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
  const code = `process.exit()${'\n// 1234567890123456789012345678901234567890'.repeat(
    50,
  )}\n// Finishing Comment`;
  const { exceptionMessage } = await runInVM(code);
  expect(exceptionMessage.match(/process is not defined/)).toBeTruthy();
  expect(exceptionMessage.match(/process.exit/)).toBeTruthy();
  expect(exceptionMessage.match(/Finishing Comment/)).toBeTruthy();
  expect(exceptionMessage.match(/\.\.\./)).toBeTruthy();
});

test('resetVM', async () => {
  expect.assertions(2);
  createUploadedBundle();
  buildVM(uploadedBundlePath());

  const result = await runInVM('ReactOnRails');
  expect(result).toEqual({ dummy: { html: 'Dummy Object' } });

  resetVM();

  expect(getVmBundleFilePath() === undefined).toBeTruthy();
});

test('VM console history', async () => {
  expect.assertions(1);
  createUploadedBundle();
  buildVM(uploadedBundlePath());

  const vmResult = await runInVM('console.log("Console message inside of VM") || console.history;');
  const consoleHistory = [{ level: 'log', arguments: ['[SERVER] Console message inside of VM'] }];

  expect(vmResult).toEqual(consoleHistory);
});

test('getVmBundleFilePath', async () => {
  expect.assertions(1);
  await createVmBundle();

  expect(getVmBundleFilePath()).toBe(path.resolve(__dirname, './tmp/1495063024898.js'));
});

test('FriendsAndGuests bundle for commit 1a7fe417', async () => {
  expect.assertions(5);

  const project = 'friendsandguests';
  const commit = '1a7fe417';

  await buildVM(path.resolve(__dirname, './fixtures/projects/friendsandguests/1a7fe417/server-bundle.js'));

  // WelcomePage component:
  const welcomePageComponentRenderingRequest = readRenderingRequest(
    project,
    commit,
    'welcomePageRenderingRequest.js',
  );
  const welcomePageRenderingResult = await runInVM(welcomePageComponentRenderingRequest);
  expect(welcomePageRenderingResult.includes('data-react-checksum=\\"800299790\\"')).toBeTruthy();

  // LayoutNavbar component:
  const layoutNavbarComponentRenderingRequest = readRenderingRequest(
    project,
    commit,
    'layoutNavbarRenderingRequest.js',
  );
  const layoutNavbarRenderingResult = await runInVM(layoutNavbarComponentRenderingRequest);
  expect(layoutNavbarRenderingResult.includes('data-react-checksum=\\"-667058792\\"')).toBeTruthy();

  // ListingIndex component:
  const listingIndexComponentRenderingRequest = readRenderingRequest(
    project,
    commit,
    'listingIndexRenderingRequest.js',
  );
  const listingIndexRenderingResult = await runInVM(listingIndexComponentRenderingRequest);
  expect(listingIndexRenderingResult.includes('data-react-checksum=\\"452252439\\"')).toBeTruthy();

  // ListingShow component:
  const listingShowComponentRenderingRequest = readRenderingRequest(
    project,
    commit,
    'listingsShowRenderingRequest.js',
  );
  const listingShowRenderingResult = await runInVM(listingShowComponentRenderingRequest);
  expect(listingShowRenderingResult.includes('data-react-checksum=\\"-324043796\\"')).toBeTruthy();

  // UserShow component:
  const userShowComponentRenderingRequest = readRenderingRequest(
    project,
    commit,
    'userShowRenderingRequest.js',
  );
  const userShowRenderingResult = await runInVM(userShowComponentRenderingRequest);
  expect(userShowRenderingResult.includes('data-react-checksum=\\"-1039690194\\"')).toBeTruthy();
});

test('ReactWebpackRailsTutorial bundle for commit ec974491', async () => {
  expect.assertions(3);

  const project = 'react-webpack-rails-tutorial';
  const commit = 'ec974491';

  await buildVM(
    path.resolve(__dirname, './fixtures/projects/react-webpack-rails-tutorial/ec974491/server-bundle.js'),
  );

  // NavigationBar component:
  const navigationBarComponentRenderingRequest = readRenderingRequest(
    project,
    commit,
    'navigationBarAppRenderingRequest.js',
  );
  const navigationBarRenderingResult = await runInVM(navigationBarComponentRenderingRequest);
  expect(navigationBarRenderingResult.includes('data-react-checksum=\\"-472831860\\"')).toBeTruthy();

  // RouterApp component:
  const routerAppComponentRenderingRequest = readRenderingRequest(
    project,
    commit,
    'routerAppRenderingRequest.js',
  );
  const routerAppRenderingResult = await runInVM(routerAppComponentRenderingRequest);
  expect(routerAppRenderingResult.includes('data-react-checksum=\\"-1777286250\\"')).toBeTruthy();

  // App component:
  const appComponentRenderingRequest = readRenderingRequest(project, commit, 'appRenderingRequest.js');
  const appRenderingResult = await runInVM(appComponentRenderingRequest);
  expect(appRenderingResult.includes('data-react-checksum=\\"-490396040\\"')).toBeTruthy();
});

test('BionicWorkshop bundle for commit fa6ccf6b', async () => {
  expect.assertions(4);

  const project = 'bionicworkshop';
  const commit = 'fa6ccf6b';

  await buildVM(path.resolve(__dirname, './fixtures/projects/bionicworkshop/fa6ccf6b/server-bundle.js'));

  // SignIn page with flash component:
  const signInPageWithFlashRenderingRequest = readRenderingRequest(
    project,
    commit,
    'signInPageWithFlashRenderingRequest.js',
  );
  const signInPageWithFlashRenderingResult = await runInVM(signInPageWithFlashRenderingRequest);

  // We don't put checksum here since it changes for every request with Rails auth token:
  expect(signInPageWithFlashRenderingResult.includes('data-react-checksum=')).toBeTruthy();

  // Landing page component:
  const landingPageRenderingRequest = readRenderingRequest(project, commit, 'landingPageRenderingRequest.js');
  const landingPageRenderingResult = await runInVM(landingPageRenderingRequest);
  expect(landingPageRenderingResult.includes('data-react-checksum=\\"-1899958456\\"')).toBeTruthy();

  // Post page component:
  const postPageRenderingRequest = readRenderingRequest(project, commit, 'postPageRenderingRequest.js');
  const postPageRenderingResult = await runInVM(postPageRenderingRequest);
  expect(postPageRenderingResult.includes('data-react-checksum=\\"-1296077150\\"')).toBeTruthy();

  // Authors page component:
  const authorsPageRenderingRequest = readRenderingRequest(project, commit, 'authorsPageRenderingRequest.js');
  const authorsPageRenderingResult = await runInVM(authorsPageRenderingRequest);
  expect(authorsPageRenderingResult.includes('data-react-checksum=\\"-1066737665\\"')).toBeTruthy();
});
