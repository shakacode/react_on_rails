import path from 'path';
import touch from 'touch';
import lockfile from 'lockfile';
import {
  createVmBundle,
  createSecondaryVmBundle,
  uploadedBundlePath,
  uploadedSecondaryBundlePath,
  createUploadedBundle,
  createUploadedSecondaryBundle,
  createUploadedAsset,
  uploadedAssetPath,
  uploadedAssetOtherPath,
  resetForTest,
  BUNDLE_TIMESTAMP,
  SECONDARY_BUNDLE_TIMESTAMP,
  lockfilePath,
  mkdirAsync,
  vmBundlePath,
  vmSecondaryBundlePath,
  ASSET_UPLOAD_FILE,
  ASSET_UPLOAD_OTHER_FILE,
} from './helper';
import { hasVMContextForBundle } from '../src/worker/vm';
import { handleRenderRequest } from '../src/worker/handleRenderRequest';
import { delay, Asset } from '../src/shared/utils';

const testName = 'handleRenderRequest';
const uploadedBundleForTest = (): Asset => ({
  filename: '', // Not used in these tests
  savedFilePath: uploadedBundlePath(testName),
  type: 'asset',
});
const createUploadedBundleForTest = () => createUploadedBundle(testName);
const lockfilePathForTest = () => lockfilePath(testName);
const createVmBundleForTest = () => createVmBundle(testName);
const renderResult = {
  status: 200,
  headers: { 'Cache-Control': 'public, max-age=31536000' },
  data: JSON.stringify({ html: 'Dummy Object' }),
};

const renderResultFromBothBundles = {
  status: 200,
  headers: { 'Cache-Control': 'public, max-age=31536000' },
  data: JSON.stringify({
    mainBundleResult: { html: 'Dummy Object' },
    secondaryBundleResult: { html: 'Dummy Object from secondary bundle' },
  }),
};

// eslint-disable-next-line jest/valid-title
describe(testName, () => {
  beforeEach(async () => {
    await resetForTest(testName);
    const bundleDirectory = path.dirname(vmBundlePath(testName));
    await mkdirAsync(bundleDirectory, { recursive: true });
    const secondaryBundleDirectory = path.dirname(vmSecondaryBundlePath(testName));
    await mkdirAsync(secondaryBundleDirectory, { recursive: true });
  });

  afterAll(async () => {
    await resetForTest(testName);
  });

  test('If gem has posted updated bundle and no prior bundle', async () => {
    expect.assertions(2);
    await createUploadedBundleForTest();

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      providedNewBundles: [
        {
          bundle: uploadedBundleForTest(),
          timestamp: BUNDLE_TIMESTAMP,
        },
      ],
    });

    expect(result).toEqual(renderResult);
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024898/1495063024898.js`)),
    ).toBeTruthy();
  });

  test('If bundle was not uploaded yet and not provided', async () => {
    expect.assertions(1);

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
    });

    expect(result).toEqual({
      status: 410,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      data: 'No bundle uploaded',
    });
  });

  test('If bundle was already uploaded by another thread', async () => {
    expect.assertions(1);
    await createVmBundleForTest();

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
    });

    expect(result).toEqual(renderResult);
  });

  test('If lockfile exists, and is stale', async () => {
    // We're using a lockfile with an artificially old date,
    // so make it use that instead of ctime.
    // Probably you should never do this in production!
    // @ts-expect-error Not allowed by the types
    lockfile.filetime = 'mtime';

    expect.assertions(2);
    touch.sync(lockfilePathForTest(), { time: '1979-07-01T19:10:00.000Z' });
    await createUploadedBundleForTest();

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      providedNewBundles: [
        {
          bundle: uploadedBundleForTest(),
          timestamp: BUNDLE_TIMESTAMP,
        },
      ],
    });

    expect(result).toEqual(renderResult);
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024898/1495063024898.js`)),
    ).toBeTruthy();
  });

  test('If lockfile exists from another thread and bundle provided.', async () => {
    expect.assertions(2);
    await createUploadedBundleForTest();

    const lockfileOptions = { pollPeriod: 100, stale: 10000 };
    lockfile.lockSync(lockfilePathForTest(), lockfileOptions);

    await delay(5);
    console.log('TEST building VM from sleep');
    await createVmBundleForTest();
    console.log('TEST DONE building VM from sleep');
    lockfile.unlock(lockfilePathForTest(), (err) => {
      console.log('TEST unlocked lockfile', err);
    });

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      providedNewBundles: [
        {
          bundle: uploadedBundleForTest(),
          timestamp: BUNDLE_TIMESTAMP,
        },
      ],
    });

    expect(result).toEqual(renderResult);
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024898/1495063024898.js`)),
    ).toBeTruthy();
  });

  test('If multiple bundles are provided', async () => {
    expect.assertions(3);
    await createUploadedBundle(testName);
    await createUploadedSecondaryBundle(testName);

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      providedNewBundles: [
        {
          bundle: {
            filename: '',
            savedFilePath: uploadedBundlePath(testName),
            type: 'asset',
          },
          timestamp: BUNDLE_TIMESTAMP,
        },
        {
          bundle: {
            filename: '',
            savedFilePath: uploadedSecondaryBundlePath(testName),
            type: 'asset',
          },
          timestamp: SECONDARY_BUNDLE_TIMESTAMP,
        },
      ],
    });

    expect(result).toEqual(renderResult);
    // only the primary bundle should be in the VM context
    // The secondary bundle will be processed only if the rendering request requests it
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024898/1495063024898.js`)),
    ).toBeTruthy();
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024899/1495063024899.js`)),
    ).toBeFalsy();
  });

  test('If multiple bundles are provided and multiple assets are provided as well', async () => {
    await createUploadedBundle(testName);
    await createUploadedSecondaryBundle(testName);

    // Create additional uploaded assets using helper functions
    await createUploadedAsset(testName);

    const additionalAssets = [
      {
        filename: ASSET_UPLOAD_FILE,
        savedFilePath: uploadedAssetPath(testName),
        type: 'asset' as const,
      },
      {
        filename: ASSET_UPLOAD_OTHER_FILE,
        savedFilePath: uploadedAssetOtherPath(testName),
        type: 'asset' as const,
      },
    ];

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      providedNewBundles: [
        {
          bundle: {
            filename: '',
            savedFilePath: uploadedBundlePath(testName),
            type: 'asset',
          },
          timestamp: BUNDLE_TIMESTAMP,
        },
        {
          bundle: {
            filename: '',
            savedFilePath: uploadedSecondaryBundlePath(testName),
            type: 'asset',
          },
          timestamp: SECONDARY_BUNDLE_TIMESTAMP,
        },
      ],
      assetsToCopy: additionalAssets,
    });

    expect(result).toEqual(renderResult);

    // Only the primary bundle should be in the VM context
    // The secondary bundle will be processed only if the rendering request requests it
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024898/1495063024898.js`)),
    ).toBeTruthy();
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024899/1495063024899.js`)),
    ).toBeFalsy();

    // Verify that the additional assets were copied to both bundle directories
    const mainBundleDir = path.dirname(
      path.resolve(__dirname, `./tmp/${testName}/1495063024898/1495063024898.js`),
    );
    const secondaryBundleDir = path.dirname(
      path.resolve(__dirname, `./tmp/${testName}/1495063024899/1495063024899.js`),
    );
    const mainAsset1Path = path.join(mainBundleDir, ASSET_UPLOAD_FILE);
    const mainAsset2Path = path.join(mainBundleDir, ASSET_UPLOAD_OTHER_FILE);
    const secondaryAsset1Path = path.join(secondaryBundleDir, ASSET_UPLOAD_FILE);
    const secondaryAsset2Path = path.join(secondaryBundleDir, ASSET_UPLOAD_OTHER_FILE);

    const fsModule = await import('fs/promises');
    const mainAsset1Exists = await fsModule
      .access(mainAsset1Path)
      .then(() => true)
      .catch(() => false);
    const mainAsset2Exists = await fsModule
      .access(mainAsset2Path)
      .then(() => true)
      .catch(() => false);
    const secondaryAsset1Exists = await fsModule
      .access(secondaryAsset1Path)
      .then(() => true)
      .catch(() => false);
    const secondaryAsset2Exists = await fsModule
      .access(secondaryAsset2Path)
      .then(() => true)
      .catch(() => false);

    expect(mainAsset1Exists).toBeTruthy();
    expect(mainAsset2Exists).toBeTruthy();
    expect(secondaryAsset1Exists).toBeTruthy();
    expect(secondaryAsset2Exists).toBeTruthy();
  });

  test('If dependency bundle timestamps are provided but not uploaded yet', async () => {
    expect.assertions(1);

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      dependencyBundleTimestamps: [SECONDARY_BUNDLE_TIMESTAMP],
    });

    expect(result).toEqual({
      status: 410,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      data: 'No bundle uploaded',
    });
  });

  test('If dependency bundle timestamps are provided and already uploaded', async () => {
    expect.assertions(1);
    await createVmBundle(testName);
    await createSecondaryVmBundle(testName);

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      dependencyBundleTimestamps: [SECONDARY_BUNDLE_TIMESTAMP],
    });

    expect(result).toEqual(renderResult);
  });

  test('rendering request can call runOnOtherBundle', async () => {
    await createVmBundle(testName);
    await createSecondaryVmBundle(testName);

    const renderingRequest = `
      runOnOtherBundle(${SECONDARY_BUNDLE_TIMESTAMP}, 'ReactOnRails.dummy').then((secondaryBundleResult) => ({
        mainBundleResult: ReactOnRails.dummy,
        secondaryBundleResult: JSON.parse(secondaryBundleResult),
      }));
    `;

    const result = await handleRenderRequest({
      renderingRequest,
      bundleTimestamp: BUNDLE_TIMESTAMP,
      dependencyBundleTimestamps: [SECONDARY_BUNDLE_TIMESTAMP],
    });

    expect(result).toEqual(renderResultFromBothBundles);
    // Both bundles should be in the VM context
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024898/1495063024898.js`)),
    ).toBeTruthy();
    expect(
      hasVMContextForBundle(path.resolve(__dirname, `./tmp/${testName}/1495063024899/1495063024899.js`)),
    ).toBeTruthy();
  });

  test('renderingRequest is globally accessible inside the VM', async () => {
    await createVmBundle(testName);

    const renderingRequest = `
      renderingRequest;
    `;

    const result = await handleRenderRequest({
      renderingRequest,
      bundleTimestamp: BUNDLE_TIMESTAMP,
    });

    expect(result).toEqual({
      status: 200,
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      data: renderingRequest,
    });
  });

  // The renderingRequest variable is automatically reset after synchronous execution to prevent data leakage
  // between requests in the shared VM context. This means it will be undefined in any async callbacks.
  //
  // If you need to access renderingRequest in an async context, save it to a local variable first:
  //
  // const renderingRequest = `
  //   const savedRequest = renderingRequest; // Save synchronously
  //   Promise.resolve().then(() => {
  //     return savedRequest; // Access async
  //   });
  // `;
  test('renderingRequest is reset after the sync execution (not accessible from async functions)', async () => {
    await createVmBundle(testName);

    // Since renderingRequest is undefined in async callbacks, we return the string 'undefined'
    // to demonstrate this behavior (as undefined cannot be returned from the VM)
    const renderingRequest = `
      Promise.resolve().then(() => renderingRequest ?? 'undefined');
    `;

    const result = await handleRenderRequest({
      renderingRequest,
      bundleTimestamp: BUNDLE_TIMESTAMP,
    });

    expect(result).toEqual({
      status: 200,
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      data: JSON.stringify('undefined'),
    });
  });

  test('If main bundle exists but dependency bundle does not exist', async () => {
    expect.assertions(1);
    // Only create the main bundle, not the secondary/dependency bundle
    await createVmBundle(testName);

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      dependencyBundleTimestamps: [SECONDARY_BUNDLE_TIMESTAMP],
    });

    expect(result).toEqual({
      status: 410,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      data: 'No bundle uploaded',
    });
  });
});
