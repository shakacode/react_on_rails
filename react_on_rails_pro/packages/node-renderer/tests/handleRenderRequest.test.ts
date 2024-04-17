import path from 'path';
import touch from 'touch';
import lockfile from 'lockfile';
import sleep from 'sleep-promise';
import {
  createVmBundle,
  uploadedBundlePath,
  createUploadedBundle,
  resetForTest,
  BUNDLE_TIMESTAMP,
  lockfilePath,
} from './helper';
import { getVmBundleFilePath } from '../src/worker/vm';
import handleRenderRequest from '../src/worker/handleRenderRequest';

const testName = 'handleRenderRequest';
const uploadedBundlePathForTest = () => uploadedBundlePath(testName);
const createUploadedBundleForTest = () => createUploadedBundle(testName);
const lockfilePathForTest = () => lockfilePath(testName);
const createVmBundleForTest = () => createVmBundle(testName);
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
    // @ts-expect-error Not allowed by the types
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

    await sleep(5);
    console.log('TEST building VM from sleep');
    await createVmBundleForTest();
    console.log('TEST DONE building VM from sleep');
    lockfile.unlock(lockfilePathForTest(), (err) => {
      console.log('TEST unlocked lockfile', err);
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
