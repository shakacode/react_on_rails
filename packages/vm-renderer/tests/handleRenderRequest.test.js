import test from 'tape';
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

test('If gem has posted updated bundle and no prior bundle', async (assert) => {
  assert.plan(2);
  resetForTest();
  createUploadedBundle();

  const result = await handleRenderRequest({
    renderingRequest: 'ReactOnRails.dummy',
    bundleTimestamp: BUNDLE_TIMESTAMP,
    providedNewBundle: { file: uploadedBundlePath() },
  });

  assert.deepEqual(
    result,
    {
      status: 200,
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      data: { html: 'Dummy Object' },
    },
    'handleRenderRequest returns status 200 and correct rendered renderedHtmls',
  );
  assert.equal(
    getVmBundleFilePath(),
    path.resolve(__dirname, './tmp/1495063024898.js'),
    'getVmBundleFilePath() should return file path of the bundle loaded to VM',
  );
});

test('If bundle was not uploaded yet and not provided ', async (assert) => {
  assert.plan(1);
  resetForTest();
  createUploadedBundle();

  const result = await handleRenderRequest({
    renderingRequest: 'ReactOnRails.dummy',
    bundleTimestamp: BUNDLE_TIMESTAMP,
  });

  assert.deepEqual(
    result,
    {
      status: 410,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      data: 'No bundle uploaded',
    },
    'handleRenderRequest returns status 410 with "No bundle uploaded"',
  );
});

test('If bundle was already uploaded by another thread', async (assert) => {
  assert.plan(1);
  resetForTest();
  await createVmBundle();

  const result = await handleRenderRequest({
    renderingRequest: 'ReactOnRails.dummy',
    bundleTimestamp: BUNDLE_TIMESTAMP,
  });

  assert.deepEqual(
    result,
    {
      status: 200,
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      data: { html: 'Dummy Object' },
    },
    'handleRenderRequest returns status 200 and correct rendered renderedHtmls',
  );
});

test('If lockfile exists, and is stale', async (assert) => {
  // We're using a lockfile with an artificially old date,
  // so make it use that instead of ctime.
  // Probably you should never do this in production!
  lockfile.filetime = 'mtime';

  assert.plan(2);
  resetForTest();
  touch.sync(lockfilePath(), { time: '1979-07-01T19:10:00.000Z' });
  createUploadedBundle();

  const result = await handleRenderRequest({
    renderingRequest: 'ReactOnRails.dummy',
    bundleTimestamp: BUNDLE_TIMESTAMP,
    providedNewBundle: { file: uploadedBundlePath() },
  });

  assert.deepEqual(
    result,
    {
      status: 200,
      headers: { 'Cache-Control': 'public, max-age=31536000' },
      data: { html: 'Dummy Object' },
    },
    'handleRenderRequest returns status 200 and correct rendered renderedHtmls',
  );
  assert.equal(
    getVmBundleFilePath(),
    path.resolve(__dirname, './tmp/1495063024898.js'),
    'getVmBundleFilePath() should return file path of the bundle loaded to VM',
  );
});

test(
  'If lockfile exists from another thread and bundle provided.',
  { timeout: 1000 },
  async (assert) => {
    assert.plan(2);
    resetForTest();
    createUploadedBundle();

    const lockfileOptions = { pollPeriod: 100, stale: 10000 };
    lockfile.lockSync(lockfilePath(), lockfileOptions);

    sleep(5).then(() => {
      console.log('TEST building VM from sleep');
      createVmBundle().then(() => {
        console.log('TEST DONE building VM from sleep');
        lockfile.unlock(lockfilePath(), (err) => {
          console.log('TEST unlocked lockfile', err);
        });
      });
    });

    const result = await handleRenderRequest({
      renderingRequest: 'ReactOnRails.dummy',
      bundleTimestamp: BUNDLE_TIMESTAMP,
      providedNewBundle: { file: uploadedBundlePath() },
    });

    assert.deepEqual(
      result,
      {
        status: 200,
        headers: { 'Cache-Control': 'public, max-age=31536000' },
        data: { html: 'Dummy Object' },
      },
      'handleRenderRequest returns status 200 and correct rendered renderedHtmls',
    );
    assert.equal(
      getVmBundleFilePath(),
      path.resolve(__dirname, './tmp/1495063024898.js'),
      'getVmBundleFilePath() should return file path of the bundle loaded to VM',
    );
  },
);

