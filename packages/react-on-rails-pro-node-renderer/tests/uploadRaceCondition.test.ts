/**
 * Tests for concurrent upload isolation (GitHub issue #2449).
 *
 * These tests assert the CORRECT expected behavior: concurrent requests that
 * upload same-named files should each deliver the correct content without
 * interference.
 *
 * Currently these tests FAIL because all uploads share a single path
 * (<serverBundleCachePath>/uploads/<filename>), causing overwrites, ENOENT
 * errors, and cross-contamination. They will PASS once per-request upload
 * isolation is implemented.
 *
 * Strategy: a preHandler barrier guarantees both requests' onFile phases
 * complete before either route handler runs, making the race deterministic.
 */
import path from 'path';
import fs from 'fs';
import fsPromises from 'fs/promises';
import os from 'os';
import formAutoContent from 'form-auto-content';
import { createReadStream } from 'fs-extra';
// eslint-disable-next-line import/no-relative-packages
import packageJson from '../package.json';
import worker, { disableHttp2 } from '../src/worker';
import { resetForTest, serverBundleCachePath, getFixtureBundle } from './helper';

const testName = 'uploadRaceCondition';
const serverBundleCachePathForTest = () => serverBundleCachePath(testName);

const gemVersion = packageJson.version;
const { protocolVersion } = packageJson;
const railsEnv = 'test';

disableHttp2();

/**
 * Adds a preHandler barrier hook to the Fastify app that blocks until
 * `expectedCount` requests have all reached the preHandler lifecycle stage.
 *
 * Since preHandler runs AFTER preValidation (where onFile saves files to disk),
 * this guarantees every request's onFile phase has completed before any route
 * handler executes — making concurrent upload races deterministic.
 */
function addBarrier(app: ReturnType<typeof worker>, routePrefix: string, expectedCount: number) {
  let arrived = 0;
  let release!: () => void;
  const gate = new Promise<void>((resolve) => {
    release = resolve;
  });

  app.addHook('preHandler', async (req) => {
    if (!req.url.startsWith(routePrefix)) return;
    arrived += 1;
    if (arrived >= expectedCount) {
      release();
    } else {
      await gate;
    }
  });
}

describe('concurrent upload isolation (issue #2449)', () => {
  let tmpDirA: string;
  let tmpDirB: string;

  beforeEach(async () => {
    await resetForTest(testName);
    tmpDirA = path.join(os.tmpdir(), `race-test-A-${Date.now()}`);
    tmpDirB = path.join(os.tmpdir(), `race-test-B-${Date.now()}`);
    await fsPromises.mkdir(tmpDirA, { recursive: true });
    await fsPromises.mkdir(tmpDirB, { recursive: true });
  });

  afterEach(async () => {
    await resetForTest(testName);
    await fsPromises.rm(tmpDirA, { recursive: true, force: true }).catch(() => {});
    await fsPromises.rm(tmpDirB, { recursive: true, force: true }).catch(() => {});
    // Clean up lockfile in case the test failed mid-lock
    await fsPromises.unlink('transferring-assets.lock').catch(() => {});
  });

  describe('/upload-assets endpoint', () => {
    // Race: both onFile handlers write to uploads/loadable-stats.json.
    // Last writer overwrites first. The 'transferring-assets' lock serializes
    // handlers, but both read from the same overwritten file → wrong content
    // in at least one bundle directory.

    test('concurrent requests each deliver correct single asset to their target bundle', async () => {
      const assetContentA = JSON.stringify({ version: 'A', data: 'first-request' });
      const assetContentB = JSON.stringify({ version: 'B', data: 'second-request' });
      fs.writeFileSync(path.join(tmpDirA, 'loadable-stats.json'), assetContentA);
      fs.writeFileSync(path.join(tmpDirB, 'loadable-stats.json'), assetContentB);

      const app = worker({ serverBundleCachePath: serverBundleCachePathForTest() });
      addBarrier(app, '/upload-assets', 2);

      const bundleHashA = 'bundle-race-A';
      const bundleHashB = 'bundle-race-B';

      const formA = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleHashA],
        asset1: createReadStream(path.join(tmpDirA, 'loadable-stats.json')),
      });
      const formB = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleHashB],
        asset1: createReadStream(path.join(tmpDirB, 'loadable-stats.json')),
      });

      const [resA, resB] = await Promise.all([
        app.inject().post('/upload-assets').payload(formA.payload).headers(formA.headers).end(),
        app.inject().post('/upload-assets').payload(formB.payload).headers(formB.headers).end(),
      ]);

      // Both requests should succeed
      expect(resA.statusCode).toBe(200);
      expect(resB.statusCode).toBe(200);

      // Each bundle directory should contain its own asset — no cross-contamination
      const bundleDirA = path.join(serverBundleCachePathForTest(), bundleHashA);
      const bundleDirB = path.join(serverBundleCachePathForTest(), bundleHashB);

      expect(fs.existsSync(path.join(bundleDirA, 'loadable-stats.json'))).toBe(true);
      expect(fs.existsSync(path.join(bundleDirB, 'loadable-stats.json'))).toBe(true);

      const actualContentA = fs.readFileSync(path.join(bundleDirA, 'loadable-stats.json'), 'utf-8');
      const actualContentB = fs.readFileSync(path.join(bundleDirB, 'loadable-stats.json'), 'utf-8');

      expect(actualContentA).toBe(assetContentA);
      expect(actualContentB).toBe(assetContentB);
    });

    test('concurrent requests with multiple assets each deliver all correct assets', async () => {
      const statsA = JSON.stringify({ version: 'A', file: 'stats' });
      const statsB = JSON.stringify({ version: 'B', file: 'stats' });
      const manifestA = JSON.stringify({ version: 'A', file: 'manifest' });
      const manifestB = JSON.stringify({ version: 'B', file: 'manifest' });

      fs.writeFileSync(path.join(tmpDirA, 'loadable-stats.json'), statsA);
      fs.writeFileSync(path.join(tmpDirA, 'manifest.json'), manifestA);
      fs.writeFileSync(path.join(tmpDirB, 'loadable-stats.json'), statsB);
      fs.writeFileSync(path.join(tmpDirB, 'manifest.json'), manifestB);

      const app = worker({ serverBundleCachePath: serverBundleCachePathForTest() });
      addBarrier(app, '/upload-assets', 2);

      const bundleHashA = 'bundle-multi-A';
      const bundleHashB = 'bundle-multi-B';

      const formA = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleHashA],
        asset1: createReadStream(path.join(tmpDirA, 'loadable-stats.json')),
        asset2: createReadStream(path.join(tmpDirA, 'manifest.json')),
      });
      const formB = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleHashB],
        asset1: createReadStream(path.join(tmpDirB, 'loadable-stats.json')),
        asset2: createReadStream(path.join(tmpDirB, 'manifest.json')),
      });

      const [resA, resB] = await Promise.all([
        app.inject().post('/upload-assets').payload(formA.payload).headers(formA.headers).end(),
        app.inject().post('/upload-assets').payload(formB.payload).headers(formB.headers).end(),
      ]);

      expect(resA.statusCode).toBe(200);
      expect(resB.statusCode).toBe(200);

      const bundleDirA = path.join(serverBundleCachePathForTest(), bundleHashA);
      const bundleDirB = path.join(serverBundleCachePathForTest(), bundleHashB);

      // All four assets should exist
      expect(fs.existsSync(path.join(bundleDirA, 'loadable-stats.json'))).toBe(true);
      expect(fs.existsSync(path.join(bundleDirA, 'manifest.json'))).toBe(true);
      expect(fs.existsSync(path.join(bundleDirB, 'loadable-stats.json'))).toBe(true);
      expect(fs.existsSync(path.join(bundleDirB, 'manifest.json'))).toBe(true);

      // Each bundle directory should have its own content — no cross-contamination
      expect(fs.readFileSync(path.join(bundleDirA, 'loadable-stats.json'), 'utf-8')).toBe(statsA);
      expect(fs.readFileSync(path.join(bundleDirA, 'manifest.json'), 'utf-8')).toBe(manifestA);
      expect(fs.readFileSync(path.join(bundleDirB, 'loadable-stats.json'), 'utf-8')).toBe(statsB);
      expect(fs.readFileSync(path.join(bundleDirB, 'manifest.json'), 'utf-8')).toBe(manifestB);
    });
  });

  describe('/bundles/:bundleTimestamp/render/:renderRequestDigest endpoint', () => {
    // Race manifests in two ways:
    // 1. Bundle move ENOENT: both onFile write to uploads/bundle.js. One handler
    //    move()s it first; the other gets ENOENT → error response.
    // 2. Asset cross-contamination: both onFile write to uploads/loadable-stats.json.
    //    Last writer overwrites → handler copies wrong content to bundle directory.
    //
    // Different bundle timestamps use different per-bundle locks, so both
    // handlers run fully concurrently with no mutual exclusion.

    test('concurrent render requests each deliver correct assets to their bundle directory', async () => {
      const assetContentA = JSON.stringify({ version: 'A', source: 'render-request-1' });
      const assetContentB = JSON.stringify({ version: 'B', source: 'render-request-2' });
      fs.writeFileSync(path.join(tmpDirA, 'loadable-stats.json'), assetContentA);
      fs.writeFileSync(path.join(tmpDirB, 'loadable-stats.json'), assetContentB);

      const app = worker({ serverBundleCachePath: serverBundleCachePathForTest() });
      addBarrier(app, '/bundles/', 2);

      const bundleTimestampA = '1000000000001';
      const bundleTimestampB = '1000000000002';

      const formA = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        renderingRequest: 'ReactOnRails.dummy',
        bundle: createReadStream(getFixtureBundle()),
        asset1: createReadStream(path.join(tmpDirA, 'loadable-stats.json')),
      });
      const formB = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        renderingRequest: 'ReactOnRails.dummy',
        bundle: createReadStream(getFixtureBundle()),
        asset1: createReadStream(path.join(tmpDirB, 'loadable-stats.json')),
      });

      const [resA, resB] = await Promise.all([
        app
          .inject()
          .post(`/bundles/${bundleTimestampA}/render/d41d8cd98f00b204e9800998ecf8427e`)
          .payload(formA.payload)
          .headers(formA.headers)
          .end(),
        app
          .inject()
          .post(`/bundles/${bundleTimestampB}/render/d41d8cd98f00b204e9800998ecf8427e`)
          .payload(formB.payload)
          .headers(formB.headers)
          .end(),
      ]);

      // Both requests should succeed and render correctly
      expect(resA.statusCode).toBe(200);
      expect(resB.statusCode).toBe(200);
      expect(resA.payload).toBe('{"html":"Dummy Object"}');
      expect(resB.payload).toBe('{"html":"Dummy Object"}');

      // Each bundle directory should have the correct asset content
      const bundleDirA = path.join(serverBundleCachePathForTest(), bundleTimestampA);
      const bundleDirB = path.join(serverBundleCachePathForTest(), bundleTimestampB);

      expect(fs.existsSync(path.join(bundleDirA, 'loadable-stats.json'))).toBe(true);
      expect(fs.existsSync(path.join(bundleDirB, 'loadable-stats.json'))).toBe(true);

      const actualA = fs.readFileSync(path.join(bundleDirA, 'loadable-stats.json'), 'utf-8');
      const actualB = fs.readFileSync(path.join(bundleDirB, 'loadable-stats.json'), 'utf-8');

      expect(actualA).toBe(assetContentA);
      expect(actualB).toBe(assetContentB);
    });
  });
});
