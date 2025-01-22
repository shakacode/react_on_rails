import path from 'path';
import {
  uploadedBundlePath,
  createUploadedBundle,
  readRenderingRequest,
  createVmBundle,
  resetForTest,
} from './helper';
import { buildVM, getVmBundleFilePath, resetVM, runInVM } from '../src/worker/vm';
import { getConfig } from '../src/shared/configBuilder';
import { isErrorRenderResult } from '../src/shared/utils';

const testName = 'vm';
const uploadedBundlePathForTest = () => uploadedBundlePath(testName);
const createUploadedBundleForTest = () => createUploadedBundle(testName);
const createVmBundleForTest = () => createVmBundle(testName);

describe('buildVM and runInVM', () => {
  beforeEach(async () => {
    await resetForTest(testName);
  });

  afterAll(async () => {
    await resetForTest(testName);
  });

  describe('Buffer and process in context', () => {
    test('not available if supportModules disabled', async () => {
      const config = getConfig();
      config.supportModules = false;

      await createUploadedBundleForTest();
      await buildVM(uploadedBundlePathForTest());

      let result = await runInVM('typeof Buffer === "undefined"');
      expect(result).toBeTruthy();

      result = await runInVM('typeof process === "undefined"');
      expect(result).toBeTruthy();
    });

    test('available if supportModules enabled', async () => {
      const config = getConfig();
      config.supportModules = true;

      await createUploadedBundleForTest();
      await buildVM(uploadedBundlePathForTest());

      let result = await runInVM('typeof Buffer !== "undefined"');
      expect(result).toBeTruthy();

      result = await runInVM('typeof process !== "undefined"');
      expect(result).toBeTruthy();
    });
  });

  describe('additionalContext', () => {
    test('not available if additionalContext not set', async () => {
      await createUploadedBundleForTest();
      await buildVM(uploadedBundlePathForTest());

      const result = await runInVM('typeof testString === "undefined"');
      expect(result).toBeTruthy();
    });

    test('available if additionalContext set', async () => {
      const config = getConfig();
      config.additionalContext = { testString: 'a string' };

      await createUploadedBundleForTest();
      await buildVM(uploadedBundlePathForTest());

      const result = await runInVM('typeof testString !== "undefined"');
      expect(result).toBeTruthy();
    });
  });

  test('buildVM and runInVM', async () => {
    expect.assertions(14);

    await createUploadedBundleForTest();
    await buildVM(uploadedBundlePathForTest());

    let result = await runInVM('ReactOnRails');
    expect(result).toEqual(JSON.stringify({ dummy: { html: 'Dummy Object' } }));

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
    // @ts-expect-error Intentional comparison
    expect(result !== console).toBeTruthy();

    expect((console as { history?: unknown }).history === undefined).toBeTruthy();

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
    await createUploadedBundleForTest();
    await buildVM(uploadedBundlePathForTest());
    // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
    const result = await runInVM('process.exit()');
    expect(
      isErrorRenderResult(result) && result.exceptionMessage.match(/process is not defined/),
    ).toBeTruthy();
  });

  test('Captured exceptions for a long message', async () => {
    expect.assertions(4);
    await createUploadedBundleForTest();
    await buildVM(uploadedBundlePathForTest());
    // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
    const code = `process.exit()${'\n// 1234567890123456789012345678901234567890'.repeat(
      50,
    )}\n// Finishing Comment`;
    const result = await runInVM(code);
    const exceptionMessage = isErrorRenderResult(result) ? result.exceptionMessage : '';
    expect(exceptionMessage.match(/process is not defined/)).toBeTruthy();
    expect(exceptionMessage.match(/process.exit/)).toBeTruthy();
    expect(exceptionMessage.match(/Finishing Comment/)).toBeTruthy();
    expect(exceptionMessage.match(/\.\.\./)).toBeTruthy();
  });

  test('resetVM', async () => {
    expect.assertions(2);
    await createUploadedBundleForTest();
    await buildVM(uploadedBundlePathForTest());

    const result = await runInVM('ReactOnRails');
    expect(result).toEqual(JSON.stringify({ dummy: { html: 'Dummy Object' } }));

    resetVM();

    expect(getVmBundleFilePath() === undefined).toBeTruthy();
  });

  test('VM console history', async () => {
    expect.assertions(1);
    await createUploadedBundleForTest();
    await buildVM(uploadedBundlePathForTest());

    const vmResult = await runInVM('console.log("Console message inside of VM") || console.history;');
    const consoleHistory = JSON.stringify([
      { level: 'log', arguments: ['[SERVER] Console message inside of VM'] },
    ]);

    expect(vmResult).toEqual(consoleHistory);
  });

  test('getVmBundleFilePath', async () => {
    expect.assertions(1);
    await createVmBundleForTest();

    expect(getVmBundleFilePath()).toBe(path.resolve(__dirname, `./tmp/${testName}/1495063024898.js`));
  });

  test('FriendsAndGuests bundle for commit 1a7fe417 requires supportModules false', async () => {
    expect.assertions(5);

    const project = 'friendsandguests';
    const commit = '1a7fe417';

    const config = getConfig();
    config.supportModules = false;

    await buildVM(path.resolve(__dirname, './fixtures/projects/friendsandguests/1a7fe417/server-bundle.js'));

    // WelcomePage component:
    const welcomePageComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'welcomePageRenderingRequest.js',
    );
    const welcomePageRenderingResult = await runInVM(welcomePageComponentRenderingRequest);
    expect(
      (welcomePageRenderingResult as string).includes('data-react-checksum=\\"800299790\\"'),
    ).toBeTruthy();

    // LayoutNavbar component:
    const layoutNavbarComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'layoutNavbarRenderingRequest.js',
    );
    const layoutNavbarRenderingResult = await runInVM(layoutNavbarComponentRenderingRequest);
    expect(
      (layoutNavbarRenderingResult as string).includes('data-react-checksum=\\"-667058792\\"'),
    ).toBeTruthy();

    // ListingIndex component:
    const listingIndexComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'listingIndexRenderingRequest.js',
    );
    const listingIndexRenderingResult = await runInVM(listingIndexComponentRenderingRequest);
    expect(
      (listingIndexRenderingResult as string).includes('data-react-checksum=\\"452252439\\"'),
    ).toBeTruthy();

    // ListingShow component:
    const listingShowComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'listingsShowRenderingRequest.js',
    );
    const listingShowRenderingResult = await runInVM(listingShowComponentRenderingRequest);
    expect(
      (listingShowRenderingResult as string).includes('data-react-checksum=\\"-324043796\\"'),
    ).toBeTruthy();

    // UserShow component:
    const userShowComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'userShowRenderingRequest.js',
    );
    const userShowRenderingResult = await runInVM(userShowComponentRenderingRequest);
    expect(
      (userShowRenderingResult as string).includes('data-react-checksum=\\"-1039690194\\"'),
    ).toBeTruthy();
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
    expect(
      (navigationBarRenderingResult as string).includes('data-react-checksum=\\"-472831860\\"'),
    ).toBeTruthy();

    // RouterApp component:
    const routerAppComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'routerAppRenderingRequest.js',
    );
    const routerAppRenderingResult = await runInVM(routerAppComponentRenderingRequest);
    expect(
      (routerAppRenderingResult as string).includes('data-react-checksum=\\"-1777286250\\"'),
    ).toBeTruthy();

    // App component:
    const appComponentRenderingRequest = readRenderingRequest(project, commit, 'appRenderingRequest.js');
    const appRenderingResult = await runInVM(appComponentRenderingRequest);
    expect((appRenderingResult as string).includes('data-react-checksum=\\"-490396040\\"')).toBeTruthy();
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
    expect((signInPageWithFlashRenderingResult as string).includes('data-react-checksum=')).toBeTruthy();

    // Landing page component:
    const landingPageRenderingRequest = readRenderingRequest(
      project,
      commit,
      'landingPageRenderingRequest.js',
    );
    const landingPageRenderingResult = await runInVM(landingPageRenderingRequest);
    expect(
      (landingPageRenderingResult as string).includes('data-react-checksum=\\"-1899958456\\"'),
    ).toBeTruthy();

    // Post page component:
    const postPageRenderingRequest = readRenderingRequest(project, commit, 'postPageRenderingRequest.js');
    const postPageRenderingResult = await runInVM(postPageRenderingRequest);
    expect(
      (postPageRenderingResult as string).includes('data-react-checksum=\\"-1296077150\\"'),
    ).toBeTruthy();

    // Authors page component:
    const authorsPageRenderingRequest = readRenderingRequest(
      project,
      commit,
      'authorsPageRenderingRequest.js',
    );
    const authorsPageRenderingResult = await runInVM(authorsPageRenderingRequest);
    expect(
      (authorsPageRenderingResult as string).includes('data-react-checksum=\\"-1066737665\\"'),
    ).toBeTruthy();
  });

  // Testing using a bundle that used a web target for the server bundle
  test('spec/dummy web', async () => {
    expect.assertions(1);

    const project = 'spec-dummy';
    const commit = '9fa89f7';

    await buildVM(
      path.resolve(__dirname, './fixtures/projects/spec-dummy/9fa89f7/server-bundle-web-target.js'),
    );

    // WelcomePage component:
    const reduxAppComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'reduxAppRenderingRequest.js',
    );
    const reduxAppRenderingResult = await runInVM(reduxAppComponentRenderingRequest);

    expect(
      (reduxAppRenderingResult as string).includes(
        '<h3>Redux Hello, <!-- -->Mr. Server Side Rendering<!-- -->!</h3>',
      ),
    ).toBeTruthy();
  });

  describe('spec/dummy node', () => {
    const project = 'spec-dummy';
    const commit = 'e5e10d1';
    const consoleLogsInAsyncServerRequest = readRenderingRequest(
      project,
      commit,
      'consoleLogsInAsyncServerRequest.js',
    );

    const requestId = '6ce0caf9-2691-472a-b59b-5de390bcffdf';

    const prepareVM = async (replayServerAsyncOperationLogs: boolean) => {
      const config = getConfig();
      config.supportModules = true;
      config.stubTimers = false;
      config.replayServerAsyncOperationLogs = replayServerAsyncOperationLogs;

      await buildVM(
        path.resolve(__dirname, './fixtures/projects/spec-dummy/e5e10d1/server-bundle-node-target.js'),
      );
    };

    test('console logs in sync and async server operations', async () => {
      await prepareVM(true);
      const consoleLogsInAsyncServerRequestResult = (await runInVM(
        consoleLogsInAsyncServerRequest,
      )) as string;

      expect(consoleLogsInAsyncServerRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Sync Server\\"]);`,
      );
      expect(consoleLogsInAsyncServerRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Recursive Async Function at level 8\\"]);`,
      );
      expect(consoleLogsInAsyncServerRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Simple Async Function at iteration 7\\"]);`,
      );
      expect(consoleLogsInAsyncServerRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Async Server after calling async functions\\"]);`,
      );
    });

    test('console logs are not leaked to other requests', async () => {
      await prepareVM(true);
      const otherRequestId = '9f3b7e12-5a8d-4c6f-b1e3-2d7f8a6c9e0b';
      const otherconsoleLogsInAsyncServerRequest = consoleLogsInAsyncServerRequest.replace(
        requestId,
        otherRequestId,
      );
      const [firstRequestResult, otherRequestResult] = (await Promise.all([
        runInVM(consoleLogsInAsyncServerRequest),
        runInVM(otherconsoleLogsInAsyncServerRequest),
      ])) as [string, string];

      expect(firstRequestResult).toContain(requestId);
      expect(firstRequestResult).not.toContain(otherRequestId);

      expect(otherRequestResult).not.toContain(requestId);
      expect(otherRequestResult).toContain(otherRequestId);

      expect(otherRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${otherRequestId}] Console log from Sync Server\\"]);`,
      );
      expect(otherRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${otherRequestId}] Console log from Recursive Async Function at level 8\\"]);`,
      );
      expect(otherRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${otherRequestId}] Console log from Simple Async Function at iteration 7\\"]);`,
      );
      expect(otherRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${otherRequestId}] Console log from Async Server after calling async functions\\"]);`,
      );
    });

    test('if replayServerAsyncOperationLogs is false, only sync console logs are replayed', async () => {
      await prepareVM(false);
      const consoleLogsInAsyncServerRequestResult = await runInVM(consoleLogsInAsyncServerRequest);

      expect(consoleLogsInAsyncServerRequestResult as string).toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Sync Server\\"]);`,
      );
      expect(consoleLogsInAsyncServerRequestResult as string).not.toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Simple Async Function at iteration 7\\"]);`,
      );
      expect(consoleLogsInAsyncServerRequestResult as string).not.toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Recursive Async Function at level 8\\"]);`,
      );
      expect(consoleLogsInAsyncServerRequestResult as string).not.toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Async Server after calling async functions\\"]);`,
      );
    });

    test('console logs are not leaked to other requests when replayServerAsyncOperationLogs is false', async () => {
      await prepareVM(false);
      const otherRequestId = '9f3b7e12-5a8d-4c6f-b1e3-2d7f8a6c9e0b';
      const otherconsoleLogsInAsyncServerRequest = consoleLogsInAsyncServerRequest.replace(
        requestId,
        otherRequestId,
      );
      const [firstRequestResult, otherRequestResult] = (await Promise.all([
        runInVM(consoleLogsInAsyncServerRequest),
        runInVM(otherconsoleLogsInAsyncServerRequest),
      ])) as [string, string];

      expect(firstRequestResult).toContain(requestId);
      expect(firstRequestResult).not.toContain(otherRequestId);

      expect(otherRequestResult).not.toContain(requestId);
      expect(otherRequestResult).toContain(otherRequestId);

      expect(firstRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${requestId}] Console log from Sync Server\\"]);`,
      );
      expect(otherRequestResult).toContain(
        `console.log.apply(console, [\\"[SERVER] [${otherRequestId}] Console log from Sync Server\\"]);`,
      );
      expect(otherRequestResult).not.toContain(
        `console.log.apply(console, [\\"[SERVER] [${otherRequestId}] Console log from Recursive Async Function at level 8\\"]);`,
      );
      expect(otherRequestResult).not.toContain(
        `console.log.apply(console, [\\"[SERVER] [${otherRequestId}] Console log from Simple Async Function at iteration 7\\"]);`,
      );
      expect(otherRequestResult).not.toContain(
        `console.log.apply(console, [\\"[SERVER] [${otherRequestId}] Console log from Async Server after calling async functions\\"]);`,
      );
    });
  });
});
