const path = require('path');
const touch = require('touch');
const lockfile = require('lockfile');
const sleep = require('sleep-promise');

const {
  createVmBundle,
  uploadedBundlePath,
  createUploadedBundle,
  resetForTest,
  BUNDLE_TIMESTAMP,
  lockfilePath,
} = require('./helper');

const testName = 'handleRenderRequest';
const uploadedBundlePathForTest = () => uploadedBundlePath(testName);
const createUploadedBundleForTest = () => createUploadedBundle(testName);
const lockfilePathForTest = () => lockfilePath(testName);
const createVmBundleForTest = () => createVmBundle(testName);

const { getVmBundleFilePath } = require('../src/worker/vm');
const handleRenderRequest = require('../src/worker/handleRenderRequest');

const renderResult = {
  status: 200,
  headers: { 'Cache-Control': 'public, max-age=31536000' },
  data: JSON.stringify({ html: 'Dummy Object' }),
};

describe(testName, () => {
  beforeEach(async () => {
    await resetForTest(testName);
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
      providedNewBundle: { file: uploadedBundlePathForTest() },
    });

    expect(result).toEqual(renderResult);
    expect(getVmBundleFilePath()).toBe(path.resolve(__dirname, `./tmp/${testName}/1495063024898.js`));
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
    lockfile.filetime = 'mtime';

    expect.assertions(2);
    touch.sync(lockfilePathForTest(), { time: '1979-07-01T19:10:00.000Z' });
    await createUploadedBundleForTest();

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      providedNewBundle: { file: uploadedBundlePathForTest() },
    });

    expect(result).toEqual(renderResult);
    expect(getVmBundleFilePath()).toBe(path.resolve(__dirname, `./tmp/${testName}/1495063024898.js`));
  });

  test('If lockfile exists from another thread and bundle provided.', async () => {
    expect.assertions(2);
    await createUploadedBundleForTest();

    const lockfileOptions = { pollPeriod: 100, stale: 10000 };
    lockfile.lockSync(lockfilePathForTest(), lockfileOptions);

    sleep(5).then(() => {
      console.log('TEST building VM from sleep');
      createVmBundleForTest().then(() => {
        console.log('TEST DONE building VM from sleep');
        lockfile.unlock(lockfilePathForTest(), (err) => {
          console.log('TEST unlocked lockfile', err);
        });
      });
    });

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      providedNewBundle: { file: uploadedBundlePathForTest() },
    });

    expect(result).toEqual(renderResult);
    expect(getVmBundleFilePath()).toBe(path.resolve(__dirname, `./tmp/${testName}/1495063024898.js`));
  });
});
