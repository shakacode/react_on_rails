import path from 'path';
import {
  uploadedBundlePath,
  createUploadedBundle,
  readRenderingRequest,
  createVmBundle,
  resetForTest,
  BUNDLE_TIMESTAMP,
} from './helper';
import { buildVM, hasVMContextForBundle, resetVM, runInVM, getVMContext } from '../src/worker/vm';
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

      let result = await runInVM('typeof Buffer === "undefined"', uploadedBundlePathForTest());
      expect(result).toBeTruthy();

      result = await runInVM('typeof process === "undefined"', uploadedBundlePathForTest());
      expect(result).toBeTruthy();
    });

    test('available if supportModules enabled', async () => {
      const config = getConfig();
      config.supportModules = true;

      await createUploadedBundleForTest();
      await buildVM(uploadedBundlePathForTest());

      let result = await runInVM('typeof Buffer !== "undefined"', uploadedBundlePathForTest());
      expect(result).toBeTruthy();

      result = await runInVM('typeof process !== "undefined"', uploadedBundlePathForTest());
      expect(result).toBeTruthy();
    });
  });

  describe('additionalContext', () => {
    test('not available if additionalContext not set', async () => {
      await createUploadedBundleForTest();
      await buildVM(uploadedBundlePathForTest());

      const result = await runInVM('typeof testString === "undefined"', uploadedBundlePathForTest());
      expect(result).toBeTruthy();
    });

    test('available if additionalContext set', async () => {
      const config = getConfig();
      config.additionalContext = { testString: 'a string' };

      await createUploadedBundleForTest();
      await buildVM(uploadedBundlePathForTest());

      const result = await runInVM('typeof testString !== "undefined"', uploadedBundlePathForTest());
      expect(result).toBeTruthy();
    });
  });

  test('buildVM and runInVM', async () => {
    expect.assertions(14);

    await createUploadedBundleForTest();
    await buildVM(uploadedBundlePathForTest());

    let result = await runInVM('ReactOnRails', uploadedBundlePathForTest());
    expect(result).toEqual(JSON.stringify({ dummy: { html: 'Dummy Object' } }));

    expect(global.ReactOnRails === undefined).toBeTruthy();

    result = await runInVM('typeof global !== undefined', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    result = await runInVM('Math === global.Math', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    result = await runInVM('ReactOnRails === global.ReactOnRails', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    await runInVM('global.testVar = "test"', uploadedBundlePathForTest());
    result = await runInVM('this.testVar === "test"', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    result = await runInVM('testVar === "test"', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    result = await runInVM('console', uploadedBundlePathForTest());
    // @ts-expect-error Intentional comparison
    expect(result !== console).toBeTruthy();

    expect((console as { history?: unknown }).history === undefined).toBeTruthy();

    result = await runInVM('console.history !== undefined', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    result = await runInVM('getStackTrace !== undefined', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    result = await runInVM('setInterval !== undefined', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    result = await runInVM('setTimeout !== undefined', uploadedBundlePathForTest());
    expect(result).toBeTruthy();

    result = await runInVM('clearTimeout !== undefined', uploadedBundlePathForTest());
    expect(result).toBeTruthy();
  });

  test('VM security and captured exceptions', async () => {
    expect.assertions(1);
    await createUploadedBundleForTest();
    await buildVM(uploadedBundlePathForTest());
    // Adopted form https://github.com/patriksimek/vm2/blob/master/test/tests.js:
    const result = await runInVM('process.exit()', uploadedBundlePathForTest());
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
    const result = await runInVM(code, uploadedBundlePathForTest());
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

    const result = await runInVM('ReactOnRails', uploadedBundlePathForTest());
    expect(result).toEqual(JSON.stringify({ dummy: { html: 'Dummy Object' } }));

    resetVM();

    expect(hasVMContextForBundle(uploadedBundlePathForTest())).toBeFalsy();
  });

  test('VM console history', async () => {
    expect.assertions(1);
    await createUploadedBundleForTest();
    await buildVM(uploadedBundlePathForTest());

    const vmResult = await runInVM(
      'console.log("Console message inside of VM") || console.history;',
      uploadedBundlePathForTest(),
    );
    const consoleHistory = JSON.stringify([
      { level: 'log', arguments: ['[SERVER] Console message inside of VM'] },
    ]);

    expect(vmResult).toEqual(consoleHistory);
  });

  test('getVmBundleFilePath', async () => {
    expect.assertions(1);
    await createVmBundleForTest();

    expect(
      hasVMContextForBundle(
        path.resolve(__dirname, `./tmp/${testName}/${BUNDLE_TIMESTAMP}/${BUNDLE_TIMESTAMP}.js`),
      ),
    ).toBeTruthy();
  });

  test('FriendsAndGuests bundle for commit 1a7fe417 requires supportModules false', async () => {
    // Testing 5 components with 3 assertions each (HTML structure, no rendering errors, length check)
    expect.assertions(15);

    const project = 'friendsandguests';
    const commit = '1a7fe417';

    const config = getConfig();
    config.supportModules = false;

    const serverBundlePath = path.resolve(
      __dirname,
      './fixtures/projects/friendsandguests/1a7fe417/server-bundle.js',
    );
    await buildVM(serverBundlePath);

    // WelcomePage component:
    const welcomePageComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'welcomePageRenderingRequest.js',
    );
    const welcomePageRenderingResult = await runInVM(welcomePageComponentRenderingRequest, serverBundlePath);
    // React 19 removed data-react-checksum, verify component rendered successfully
    expect(welcomePageRenderingResult as string).toContain('<div');
    expect(welcomePageRenderingResult as string).not.toContain('hasErrors');
    expect((welcomePageRenderingResult as string).length).toBeGreaterThan(100);

    // LayoutNavbar component:
    const layoutNavbarComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'layoutNavbarRenderingRequest.js',
    );
    const layoutNavbarRenderingResult = await runInVM(
      layoutNavbarComponentRenderingRequest,
      serverBundlePath,
    );
    // React 19 removed data-react-checksum, verify component rendered successfully
    expect(layoutNavbarRenderingResult as string).toContain('<div');
    expect(layoutNavbarRenderingResult as string).not.toContain('hasErrors');
    expect((layoutNavbarRenderingResult as string).length).toBeGreaterThan(100);

    // ListingIndex component:
    const listingIndexComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'listingIndexRenderingRequest.js',
    );
    const listingIndexRenderingResult = await runInVM(
      listingIndexComponentRenderingRequest,
      serverBundlePath,
    );
    // React 19 removed data-react-checksum, verify component rendered successfully
    expect(listingIndexRenderingResult as string).toContain('<div');
    expect(listingIndexRenderingResult as string).not.toContain('hasErrors');
    expect((listingIndexRenderingResult as string).length).toBeGreaterThan(100);

    // ListingShow component:
    const listingShowComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'listingsShowRenderingRequest.js',
    );
    const listingShowRenderingResult = await runInVM(listingShowComponentRenderingRequest, serverBundlePath);
    // React 19 removed data-react-checksum, verify component rendered successfully
    expect(listingShowRenderingResult as string).toContain('<div');
    expect(listingShowRenderingResult as string).not.toContain('hasErrors');
    expect((listingShowRenderingResult as string).length).toBeGreaterThan(100);

    // UserShow component:
    const userShowComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'userShowRenderingRequest.js',
    );
    const userShowRenderingResult = await runInVM(userShowComponentRenderingRequest, serverBundlePath);
    // React 19 removed data-react-checksum, verify component rendered successfully
    expect(userShowRenderingResult as string).toContain('<div');
    expect(userShowRenderingResult as string).not.toContain('hasErrors');
    expect((userShowRenderingResult as string).length).toBeGreaterThan(100);
  });

  test('ReactWebpackRailsTutorial bundle for commit ec974491', async () => {
    // Testing 3 components with 3 assertions each (HTML structure, no rendering errors, length check)
    expect.assertions(9);

    const project = 'react-webpack-rails-tutorial';
    const commit = 'ec974491';

    const serverBundlePath = path.resolve(
      __dirname,
      './fixtures/projects/react-webpack-rails-tutorial/ec974491/server-bundle.js',
    );
    await buildVM(serverBundlePath);

    // NavigationBar component:
    const navigationBarComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'navigationBarAppRenderingRequest.js',
    );
    const navigationBarRenderingResult = await runInVM(
      navigationBarComponentRenderingRequest,
      serverBundlePath,
    );
    // React 19 removed data-react-checksum, verify component rendered successfully
    expect(navigationBarRenderingResult as string).toContain('<div');
    expect(navigationBarRenderingResult as string).not.toContain('hasErrors');
    expect((navigationBarRenderingResult as string).length).toBeGreaterThan(100);

    // RouterApp component:
    const routerAppComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'routerAppRenderingRequest.js',
    );
    const routerAppRenderingResult = await runInVM(routerAppComponentRenderingRequest, serverBundlePath);
    // React 19 removed data-react-checksum, verify component rendered successfully
    expect(routerAppRenderingResult as string).toContain('<div');
    expect(routerAppRenderingResult as string).not.toContain('hasErrors');
    expect((routerAppRenderingResult as string).length).toBeGreaterThan(100);

    // App component:
    const appComponentRenderingRequest = readRenderingRequest(project, commit, 'appRenderingRequest.js');
    const appRenderingResult = await runInVM(appComponentRenderingRequest, serverBundlePath);
    // React 19 removed data-react-checksum, verify component rendered successfully
    expect(appRenderingResult as string).toContain('<div');
    expect(appRenderingResult as string).not.toContain('hasErrors');
    expect((appRenderingResult as string).length).toBeGreaterThan(100);
  });

  test('BionicWorkshop bundle for commit fa6ccf6b', async () => {
    // Testing 4 components with 3 assertions each (HTML structure, no rendering errors, length check)
    expect.assertions(12);

    const project = 'bionicworkshop';
    const commit = 'fa6ccf6b';

    const serverBundlePath = path.resolve(
      __dirname,
      './fixtures/projects/bionicworkshop/fa6ccf6b/server-bundle.js',
    );
    await buildVM(serverBundlePath);

    // SignIn page with flash component:
    const signInPageWithFlashRenderingRequest = readRenderingRequest(
      project,
      commit,
      'signInPageWithFlashRenderingRequest.js',
    );
    const signInPageWithFlashRenderingResult = await runInVM(
      signInPageWithFlashRenderingRequest,
      serverBundlePath,
    );

    // React 19 removed data-react-checksum, check that component rendered successfully
    expect(signInPageWithFlashRenderingResult as string).toContain('<div');
    expect(signInPageWithFlashRenderingResult as string).not.toContain('hasErrors');
    expect((signInPageWithFlashRenderingResult as string).length).toBeGreaterThan(100);

    // Landing page component:
    const landingPageRenderingRequest = readRenderingRequest(
      project,
      commit,
      'landingPageRenderingRequest.js',
    );
    const landingPageRenderingResult = await runInVM(landingPageRenderingRequest, serverBundlePath);
    // React 19 removed data-react-checksum, check that component rendered successfully
    expect(landingPageRenderingResult as string).toContain('<div');
    expect(landingPageRenderingResult as string).not.toContain('hasErrors');
    expect((landingPageRenderingResult as string).length).toBeGreaterThan(100);

    // Post page component:
    const postPageRenderingRequest = readRenderingRequest(project, commit, 'postPageRenderingRequest.js');
    const postPageRenderingResult = await runInVM(postPageRenderingRequest, serverBundlePath);
    // React 19 removed data-react-checksum, check that component rendered successfully
    expect(postPageRenderingResult as string).toContain('<div');
    expect(postPageRenderingResult as string).not.toContain('hasErrors');
    expect((postPageRenderingResult as string).length).toBeGreaterThan(100);

    // Authors page component:
    const authorsPageRenderingRequest = readRenderingRequest(
      project,
      commit,
      'authorsPageRenderingRequest.js',
    );
    const authorsPageRenderingResult = await runInVM(authorsPageRenderingRequest, serverBundlePath);
    // React 19 removed data-react-checksum, check that component rendered successfully
    expect(authorsPageRenderingResult as string).toContain('<div');
    expect(authorsPageRenderingResult as string).not.toContain('hasErrors');
    expect((authorsPageRenderingResult as string).length).toBeGreaterThan(100);
  });

  // Testing using a bundle that used a web target for the server bundle
  test('spec/dummy web', async () => {
    expect.assertions(1);

    const project = 'spec-dummy';
    const commit = '9fa89f7';

    const serverBundlePath = path.resolve(
      __dirname,
      './fixtures/projects/spec-dummy/9fa89f7/server-bundle-web-target.js',
    );
    await buildVM(serverBundlePath);

    // WelcomePage component:
    const reduxAppComponentRenderingRequest = readRenderingRequest(
      project,
      commit,
      'reduxAppRenderingRequest.js',
    );
    const reduxAppRenderingResult = await runInVM(reduxAppComponentRenderingRequest, serverBundlePath);

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
    const serverBundlePath = path.resolve(
      __dirname,
      './fixtures/projects/spec-dummy/e5e10d1/server-bundle-node-target.js',
    );

    const requestId = '6ce0caf9-2691-472a-b59b-5de390bcffdf';

    const prepareVM = async (replayServerAsyncOperationLogs: boolean) => {
      const config = getConfig();
      config.supportModules = true;
      config.stubTimers = false;
      config.replayServerAsyncOperationLogs = replayServerAsyncOperationLogs;

      await buildVM(serverBundlePath);
    };

    test('console logs in sync and async server operations', async () => {
      await prepareVM(true);
      const consoleLogsInAsyncServerRequestResult = (await runInVM(
        consoleLogsInAsyncServerRequest,
        serverBundlePath,
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
        runInVM(consoleLogsInAsyncServerRequest, serverBundlePath),
        runInVM(otherconsoleLogsInAsyncServerRequest, serverBundlePath),
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
      const consoleLogsInAsyncServerRequestResult = await runInVM(
        consoleLogsInAsyncServerRequest,
        serverBundlePath,
      );

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
        runInVM(consoleLogsInAsyncServerRequest, serverBundlePath),
        runInVM(otherconsoleLogsInAsyncServerRequest, serverBundlePath),
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

    test('calling multiple buildVM in parallel creates the same VM context', async () => {
      const buildAndGetVmContext = async () => {
        await prepareVM(true);
        return getVMContext(serverBundlePath);
      };

      const [vmContext1, vmContext2] = await Promise.all([buildAndGetVmContext(), buildAndGetVmContext()]);
      expect(vmContext1).toBe(vmContext2);
    });

    test('running runInVM before buildVM', async () => {
      resetVM();
      void prepareVM(true);
      // If the bundle is parsed, ReactOnRails object will be globally available and has the serverRenderReactComponent method
      const ReactOnRails = await runInVM(
        'typeof ReactOnRails !== "undefined" && ReactOnRails && typeof ReactOnRails.serverRenderReactComponent',
        serverBundlePath,
      );
      expect(ReactOnRails).toBe('function');
    });

    test("running multiple buildVM in parallel doesn't cause runInVM to return partial results", async () => {
      resetVM();
      void Promise.all([prepareVM(true), prepareVM(true), prepareVM(true), prepareVM(true)]);
      // If the bundle is parsed, ReactOnRails object will be globally available and has the serverRenderReactComponent method
      const runCodeInVM = () =>
        runInVM(
          'typeof ReactOnRails !== "undefined" && ReactOnRails && typeof ReactOnRails.serverRenderReactComponent',
          serverBundlePath,
        );
      const [runCodeInVM1, runCodeInVM2, runCodeInVM3] = await Promise.all([
        runCodeInVM(),
        runCodeInVM(),
        runCodeInVM(),
      ]);
      expect(runCodeInVM1).toBe('function');
      expect(runCodeInVM2).toBe('function');
      expect(runCodeInVM3).toBe('function');
    });
  });

  describe('VM Pool Management', () => {
    beforeEach(async () => {
      await resetForTest(testName);
      const config = getConfig();
      config.supportModules = true;
      config.maxVMPoolSize = 2; // Set a small pool size for testing
    });

    afterEach(async () => {
      await resetForTest(testName);
      resetVM();
    });

    test('respects maxVMPoolSize limit', async () => {
      const bundle1 = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/9fa89f7/server-bundle-web-target.js',
      );
      const bundle2 = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/e5e10d1/server-bundle-node-target.js',
      );
      const bundle3 = path.resolve(__dirname, './fixtures/projects/bionicworkshop/fa6ccf6b/server-bundle.js');

      // Build VMs up to and beyond the pool limit
      await buildVM(bundle1);
      await buildVM(bundle2);
      await buildVM(bundle3);

      // Only the two most recently used bundles should have contexts
      expect(hasVMContextForBundle(bundle1)).toBeFalsy();
      expect(hasVMContextForBundle(bundle2)).toBeTruthy();
      expect(hasVMContextForBundle(bundle3)).toBeTruthy();
    });

    test('calling buildVM with the same bundle path does not create a new VM', async () => {
      const bundle1 = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/9fa89f7/server-bundle-web-target.js',
      );
      const bundle2 = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/e5e10d1/server-bundle-node-target.js',
      );
      await buildVM(bundle1);
      await buildVM(bundle2);
      await buildVM(bundle2);
      await buildVM(bundle2);

      expect(hasVMContextForBundle(bundle1)).toBeTruthy();
      expect(hasVMContextForBundle(bundle2)).toBeTruthy();
    });

    test('updates lastUsed timestamp when accessing existing VM', async () => {
      const bundle1 = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/9fa89f7/server-bundle-web-target.js',
      );
      const bundle2 = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/e5e10d1/server-bundle-node-target.js',
      );
      const bundle3 = path.resolve(__dirname, './fixtures/projects/bionicworkshop/fa6ccf6b/server-bundle.js');

      // Create initial VMs
      await buildVM(bundle1);
      await buildVM(bundle2);

      // Wait a bit to ensure timestamp difference
      await new Promise((resolve) => {
        setTimeout(resolve, 100);
      });

      // Access bundle1 again to update its timestamp
      await buildVM(bundle1);

      // Add a new VM - should remove bundle2 as it's the oldest
      await buildVM(bundle3);

      // Bundle1 should still exist as it was accessed more recently
      expect(hasVMContextForBundle(bundle1)).toBeTruthy();
      expect(hasVMContextForBundle(bundle2)).toBeFalsy();
      expect(hasVMContextForBundle(bundle3)).toBeTruthy();
    });

    test('updates lastUsed timestamp when running code in VM', async () => {
      const bundle1 = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/9fa89f7/server-bundle-web-target.js',
      );
      const bundle2 = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/e5e10d1/server-bundle-node-target.js',
      );
      const bundle3 = path.resolve(__dirname, './fixtures/projects/bionicworkshop/fa6ccf6b/server-bundle.js');

      // Create initial VMs
      await buildVM(bundle1);
      await buildVM(bundle2);

      // Wait a bit to ensure timestamp difference
      await new Promise((resolve) => {
        setTimeout(resolve, 100);
      });

      // Run code in bundle1 to update its timestamp
      await runInVM('1 + 1', bundle1);

      // Add a new VM - should remove bundle2 as it's the oldest
      await buildVM(bundle3);

      // Bundle1 should still exist as it was used more recently
      expect(hasVMContextForBundle(bundle1)).toBeTruthy();
      expect(hasVMContextForBundle(bundle2)).toBeFalsy();
      expect(hasVMContextForBundle(bundle3)).toBeTruthy();
    });

    test('reuses existing VM context', async () => {
      const bundle = path.resolve(
        __dirname,
        './fixtures/projects/spec-dummy/9fa89f7/server-bundle-web-target.js',
      );

      // Build VM first time
      await buildVM(bundle);

      // Set a variable in the VM context
      await runInVM('global.testVar = "test value"', bundle);

      // Build VM second time - should reuse existing context
      await buildVM(bundle);

      // Variable should still exist if context was reused
      const result = await runInVM('global.testVar', bundle);
      expect(result).toBe('test value');
    });
  });
});
