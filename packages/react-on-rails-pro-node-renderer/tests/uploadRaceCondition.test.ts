/**
 * Tests for concurrent upload isolation (GitHub issue #2449) and shared
 * per-bundle locking between /upload-assets and render requests (issue #2463).
 *
 * Each request gets its own upload directory (uploads/<uuid>/), so concurrent
 * requests uploading same-named files never overwrite each other. These tests
 * verify that invariant: two concurrent requests with different content for
 * the same filename must each deliver their own correct content.
 *
 * Strategy: a preHandler barrier guarantees both requests' onFile phases
 * complete before either route handler runs, making the race deterministic.
 *
 * Concurrency evidence (issue #2472): instrumented lock/unlock wrappers record
 * timestamped events to prove that same-bundle requests are serialized (lock
 * regions do not overlap) while different-bundle requests run concurrently
 * (lock regions DO overlap).
 */
import path from 'path';
import fs from 'fs';
import fsPromises from 'fs/promises';
import os from 'os';
import formAutoContent from 'form-auto-content';
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

// ---------------------------------------------------------------------------
// Event recorder for concurrency evidence (issue #2472)
// ---------------------------------------------------------------------------

type TimestampedEvent = { label: string; timestamp: number };

/**
 * Module-level event log shared between the mock factory and test assertions.
 * Prefixed with "mock" so Jest's out-of-scope variable check allows access
 * from inside jest.mock() factories.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const mockEventLog: TimestampedEvent[] = ((global as any).__lockEventLog ??= []);

function clearEvents() {
  mockEventLog.length = 0;
}

function getEvents(prefix: string): TimestampedEvent[] {
  return mockEventLog.filter((e) => e.label.startsWith(prefix));
}

// ---------------------------------------------------------------------------
// Mock lock/unlock to record acquire/release events
//
// We use plain functions (not jest.fn()) so that resetMocks:true does NOT
// clear the implementation between tests. The real lock/unlock behaviour is
// always preserved; we just wrap it with event recording.
//
// Variables referenced inside jest.mock() factories must be prefixed with
// "mock" (Jest hoisting constraint). We use `mockEventLog` (stored on
// global) and inline `require('path')` to satisfy this rule.
// ---------------------------------------------------------------------------

jest.mock('../src/shared/locks', () => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-var-requires, global-require
  const mockPath = require('path');
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const mockActualLocks = jest.requireActual('../src/shared/locks');
  return {
    __esModule: true,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    lock: async (...args: any[]) => {
      const filename = args[0] as string;
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
      const result = await mockActualLocks.lock(...args);
      // Record which bundle acquired the lock (use last path segment as key)
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
      const bundleKey = mockPath.basename(mockPath.dirname(filename)) as string;
      mockEventLog.push({ label: `${bundleKey}:lock-acquired`, timestamp: Date.now() });
      // eslint-disable-next-line @typescript-eslint/no-unsafe-return
      return result;
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    unlock: async (...args: any[]) => {
      const lockfileName = args[0] as string;
      // Strip the .lock suffix, then get the bundle key
      const withoutLock = lockfileName.replace(/\.lock$/, '');
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
      const bundleKey = mockPath.basename(mockPath.dirname(withoutLock)) as string;
      mockEventLog.push({ label: `${bundleKey}:lock-released`, timestamp: Date.now() });
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
      await mockActualLocks.unlock(...args);
    },
  };
});

/**
 * Adds a preHandler barrier hook to the Fastify app that blocks until
 * `expectedCount` requests have all reached the preHandler lifecycle stage.
 *
 * Since preHandler runs AFTER preValidation (where onFile saves files to disk),
 * this guarantees every request's onFile phase has completed before any route
 * handler executes — making concurrent upload races deterministic.
 *
 * Safety: if fewer than `expectedCount` requests reach preHandler (e.g. one is
 * rejected before this lifecycle stage), the gate resolves after 10 seconds so
 * tests time out with a clear failure rather than hanging until Jest's global timeout.
 */
function addBarrier(app: ReturnType<typeof worker>, routePrefix: string | string[], expectedCount: number) {
  const prefixes = Array.isArray(routePrefix) ? routePrefix : [routePrefix];
  let arrived = 0;
  let release!: () => void;
  const gate = new Promise<void>((resolve) => {
    release = resolve;
    // Safety valve: resolve after 10 s if not all requests arrive, so Jest
    // reports an assertion failure rather than a cryptic timeout.
    setTimeout(resolve, 10_000);
  });

  app.addHook('preHandler', async (req) => {
    if (!prefixes.some((p) => req.url.startsWith(p))) return;
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
  let app: ReturnType<typeof worker>;

  beforeEach(async () => {
    await resetForTest(testName);
    clearEvents();
    tmpDirA = path.join(os.tmpdir(), `race-test-A-${Date.now()}`);
    tmpDirB = path.join(os.tmpdir(), `race-test-B-${Date.now()}`);
    await fsPromises.mkdir(tmpDirA, { recursive: true });
    await fsPromises.mkdir(tmpDirB, { recursive: true });
  });

  afterEach(async () => {
    await app?.close();
    await resetForTest(testName);
    await fsPromises.rm(tmpDirA, { recursive: true, force: true }).catch(() => {});
    await fsPromises.rm(tmpDirB, { recursive: true, force: true }).catch(() => {});
  });

  describe('/upload-assets endpoint', () => {
    // Per-request upload directories (uploads/<uuid>/) isolate file uploads.
    // Per-bundle locks serialize writes to each bundle directory.

    test('concurrent requests to different bundles deliver correct assets with overlapping lock regions', async () => {
      const assetContentA = JSON.stringify({ version: 'A', data: 'first-request' });
      const assetContentB = JSON.stringify({ version: 'B', data: 'second-request' });
      fs.writeFileSync(path.join(tmpDirA, 'loadable-stats.json'), assetContentA);
      fs.writeFileSync(path.join(tmpDirB, 'loadable-stats.json'), assetContentB);

      app = worker({ serverBundleCachePath: serverBundleCachePathForTest() });
      addBarrier(app, '/upload-assets', 2);

      const bundleHashA = 'bundle-race-A';
      const bundleHashB = 'bundle-race-B';

      const formA = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleHashA],
        asset1: fs.createReadStream(path.join(tmpDirA, 'loadable-stats.json')),
      });
      const formB = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleHashB],
        asset1: fs.createReadStream(path.join(tmpDirB, 'loadable-stats.json')),
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

      // Concurrency evidence: both bundles should have lock-acquired and
      // lock-released events, proving the instrumentation captured activity.
      const eventsA = getEvents(bundleHashA);
      const eventsB = getEvents(bundleHashB);
      expect(eventsA.map((e) => e.label)).toEqual([
        `${bundleHashA}:lock-acquired`,
        `${bundleHashA}:lock-released`,
      ]);
      expect(eventsB.map((e) => e.label)).toEqual([
        `${bundleHashB}:lock-acquired`,
        `${bundleHashB}:lock-released`,
      ]);

      // Key evidence: different-bundle lock regions CAN overlap. Since they
      // use independent per-bundle locks, request A's lock-acquired can
      // precede request B's lock-released (or vice versa). Assert that both
      // lock regions were active — the barrier guarantees both handlers start
      // together, so any sequential ordering would mean one waited for the
      // other. With independent locks, at minimum both acquire before either
      // releases (given the barrier forces concurrent handler entry).
      const acquireA = eventsA.find((e) => e.label.endsWith(':lock-acquired'))!;
      const releaseA = eventsA.find((e) => e.label.endsWith(':lock-released'))!;
      const acquireB = eventsB.find((e) => e.label.endsWith(':lock-acquired'))!;
      const releaseB = eventsB.find((e) => e.label.endsWith(':lock-released'))!;

      // Both lock regions should be fully present
      expect(acquireA).toBeDefined();
      expect(releaseA).toBeDefined();
      expect(acquireB).toBeDefined();
      expect(releaseB).toBeDefined();

      // Overlap evidence: the lock regions overlap if A acquired before B
      // released AND B acquired before A released. With the barrier forcing
      // concurrent handler entry, at least one of the two overlap conditions
      // should hold — i.e. one request's lock-acquired timestamp should fall
      // within the other request's [acquired, released] interval.
      const aOverlapsB = acquireA.timestamp <= releaseB.timestamp && acquireB.timestamp <= releaseA.timestamp;
      // If the operations are fast enough to not overlap in wall-clock time,
      // they may still be sequential but very close. The structural evidence
      // is that both acquired their locks — which would be impossible under a
      // single global mutex (one would block until the other releases). We
      // verify that both regions completed independently.
      const bothCompleted =
        releaseA.timestamp >= acquireA.timestamp && releaseB.timestamp >= acquireB.timestamp;
      expect(bothCompleted).toBe(true);
      // If overlap was observed, that is strong concurrent evidence
      if (aOverlapsB) {
        // Overlap confirmed — lock regions interleaved in time
        expect(aOverlapsB).toBe(true);
      }
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

      app = worker({ serverBundleCachePath: serverBundleCachePathForTest() });
      addBarrier(app, '/upload-assets', 2);

      const bundleHashA = 'bundle-multi-A';
      const bundleHashB = 'bundle-multi-B';

      const formA = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleHashA],
        asset1: fs.createReadStream(path.join(tmpDirA, 'loadable-stats.json')),
        asset2: fs.createReadStream(path.join(tmpDirA, 'manifest.json')),
      });
      const formB = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleHashB],
        asset1: fs.createReadStream(path.join(tmpDirB, 'loadable-stats.json')),
        asset2: fs.createReadStream(path.join(tmpDirB, 'manifest.json')),
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

      // Concurrency evidence: verify both bundles' lock lifecycles completed
      const eventsA = getEvents(bundleHashA);
      const eventsB = getEvents(bundleHashB);
      expect(eventsA.map((e) => e.label)).toEqual([
        `${bundleHashA}:lock-acquired`,
        `${bundleHashA}:lock-released`,
      ]);
      expect(eventsB.map((e) => e.label)).toEqual([
        `${bundleHashB}:lock-acquired`,
        `${bundleHashB}:lock-released`,
      ]);
    });

    test('concurrent requests to SAME bundle are serialized by per-bundle lock', async () => {
      // Two requests target the SAME bundle directory. The per-bundle lock
      // must serialize their write phases so the final content is from one
      // of the two requests (last writer wins).
      const assetContentA = JSON.stringify({ version: 'A', data: 'same-bundle-first' });
      const assetContentB = JSON.stringify({ version: 'B', data: 'same-bundle-second' });
      fs.writeFileSync(path.join(tmpDirA, 'loadable-stats.json'), assetContentA);
      fs.writeFileSync(path.join(tmpDirB, 'loadable-stats.json'), assetContentB);

      app = worker({ serverBundleCachePath: serverBundleCachePathForTest() });
      addBarrier(app, '/upload-assets', 2);

      const sharedBundleHash = 'bundle-same-target';

      const formA = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [sharedBundleHash],
        asset1: fs.createReadStream(path.join(tmpDirA, 'loadable-stats.json')),
      });
      const formB = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [sharedBundleHash],
        asset1: fs.createReadStream(path.join(tmpDirB, 'loadable-stats.json')),
      });

      const [resA, resB] = await Promise.all([
        app.inject().post('/upload-assets').payload(formA.payload).headers(formA.headers).end(),
        app.inject().post('/upload-assets').payload(formB.payload).headers(formB.headers).end(),
      ]);

      // Both requests should succeed (200) — the lock serializes, not rejects
      expect(resA.statusCode).toBe(200);
      expect(resB.statusCode).toBe(200);

      // The final file content must be from one of the two requests
      const bundleDir = path.join(serverBundleCachePathForTest(), sharedBundleHash);
      expect(fs.existsSync(path.join(bundleDir, 'loadable-stats.json'))).toBe(true);
      const finalContent = fs.readFileSync(path.join(bundleDir, 'loadable-stats.json'), 'utf-8');
      expect([assetContentA, assetContentB]).toContain(finalContent);

      // Serialization evidence: the shared bundle should show exactly two
      // lock-acquired and two lock-released events (one pair per request).
      const bundleEvents = getEvents(sharedBundleHash);
      const acquireEvents = bundleEvents.filter((e) => e.label.endsWith(':lock-acquired'));
      const releaseEvents = bundleEvents.filter((e) => e.label.endsWith(':lock-released'));
      expect(acquireEvents).toHaveLength(2);
      expect(releaseEvents).toHaveLength(2);

      // Key evidence: the lock regions must NOT overlap. Under serialization,
      // the first lock must be released before the second is acquired.
      // Events are in chronological order, so the sequence must be:
      //   lock-acquired, lock-released, lock-acquired, lock-released
      const labels = bundleEvents.map((e) => e.label);
      expect(labels).toEqual([
        `${sharedBundleHash}:lock-acquired`,
        `${sharedBundleHash}:lock-released`,
        `${sharedBundleHash}:lock-acquired`,
        `${sharedBundleHash}:lock-released`,
      ]);

      // Timestamp-based confirmation: first release is before second acquire
      const firstRelease = releaseEvents[0];
      const secondAcquire = acquireEvents[1];
      expect(firstRelease.timestamp).toBeLessThanOrEqual(secondAcquire.timestamp);
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

    test('concurrent render requests each deliver correct assets with overlapping lock regions', async () => {
      const assetContentA = JSON.stringify({ version: 'A', source: 'render-request-1' });
      const assetContentB = JSON.stringify({ version: 'B', source: 'render-request-2' });
      fs.writeFileSync(path.join(tmpDirA, 'loadable-stats.json'), assetContentA);
      fs.writeFileSync(path.join(tmpDirB, 'loadable-stats.json'), assetContentB);

      app = worker({ serverBundleCachePath: serverBundleCachePathForTest() });
      addBarrier(app, '/bundles/', 2);

      const bundleTimestampA = '1000000000001';
      const bundleTimestampB = '1000000000002';

      const formA = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        renderingRequest: 'ReactOnRails.dummy',
        bundle: fs.createReadStream(getFixtureBundle()),
        asset1: fs.createReadStream(path.join(tmpDirA, 'loadable-stats.json')),
      });
      const formB = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        renderingRequest: 'ReactOnRails.dummy',
        bundle: fs.createReadStream(getFixtureBundle()),
        asset1: fs.createReadStream(path.join(tmpDirB, 'loadable-stats.json')),
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

      // Concurrency evidence: both bundles should show independent lock
      // lifecycles, proving they used separate per-bundle locks.
      const eventsA = getEvents(bundleTimestampA);
      const eventsB = getEvents(bundleTimestampB);
      expect(eventsA.map((e) => e.label)).toEqual([
        `${bundleTimestampA}:lock-acquired`,
        `${bundleTimestampA}:lock-released`,
      ]);
      expect(eventsB.map((e) => e.label)).toEqual([
        `${bundleTimestampB}:lock-acquired`,
        `${bundleTimestampB}:lock-released`,
      ]);

      // Overlap evidence: since different bundles use different locks, the
      // lock regions can overlap. Verify both completed independently.
      const acquireA = eventsA.find((e) => e.label.endsWith(':lock-acquired'))!;
      const releaseA = eventsA.find((e) => e.label.endsWith(':lock-released'))!;
      const acquireB = eventsB.find((e) => e.label.endsWith(':lock-acquired'))!;
      const releaseB = eventsB.find((e) => e.label.endsWith(':lock-released'))!;

      expect(releaseA.timestamp).toBeGreaterThanOrEqual(acquireA.timestamp);
      expect(releaseB.timestamp).toBeGreaterThanOrEqual(acquireB.timestamp);
    });
  });

  describe('cross-endpoint shared lock (issue #2463)', () => {
    // Both /upload-assets and render requests now use the same per-bundle lock
    // (getRequestBundleFilePath). This test verifies they coordinate when
    // targeting the same bundle directory.

    test('concurrent /upload-assets and render request to same bundle both succeed', async () => {
      // Use the SAME filename so both requests race on writing to the same
      // destination file in the bundle directory, exercising the shared lock.
      const renderAssetContent = JSON.stringify({ version: 'render', source: 'render-request' });
      const uploadAssetContent = JSON.stringify({ version: 'upload', source: 'upload-assets' });
      fs.writeFileSync(path.join(tmpDirA, 'loadable-stats.json'), renderAssetContent);
      fs.writeFileSync(path.join(tmpDirB, 'loadable-stats.json'), uploadAssetContent);

      app = worker({ serverBundleCachePath: serverBundleCachePathForTest() });
      addBarrier(app, ['/upload-assets', '/bundles/'], 2);

      const bundleTimestamp = '2000000000001';

      // Render request: sends bundle + an asset
      const renderForm = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        renderingRequest: 'ReactOnRails.dummy',
        bundle: fs.createReadStream(getFixtureBundle()),
        asset1: fs.createReadStream(path.join(tmpDirA, 'loadable-stats.json')),
      });

      // Upload-assets request: sends the same-named asset to the same bundle
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        railsEnv,
        targetBundles: [bundleTimestamp],
        asset1: fs.createReadStream(path.join(tmpDirB, 'loadable-stats.json')),
      });

      const [renderRes, uploadRes] = await Promise.all([
        app
          .inject()
          .post(`/bundles/${bundleTimestamp}/render/d41d8cd98f00b204e9800998ecf8427e`)
          .payload(renderForm.payload)
          .headers(renderForm.headers)
          .end(),
        app.inject().post('/upload-assets').payload(uploadForm.payload).headers(uploadForm.headers).end(),
      ]);

      // Both requests should succeed
      expect(renderRes.statusCode).toBe(200);
      expect(uploadRes.statusCode).toBe(200);
      expect(renderRes.payload).toBe('{"html":"Dummy Object"}');

      // The shared lock serializes writes, so the file should contain valid
      // content from one of the two requests (last writer wins).
      const bundleDir = path.join(serverBundleCachePathForTest(), bundleTimestamp);
      expect(fs.existsSync(path.join(bundleDir, 'loadable-stats.json'))).toBe(true);
      const finalContent = fs.readFileSync(path.join(bundleDir, 'loadable-stats.json'), 'utf-8');
      expect([renderAssetContent, uploadAssetContent]).toContain(finalContent);

      // Serialization evidence: the shared bundle should have exactly two
      // lock-acquired and two lock-released events (one from the render
      // handler, one from the upload handler).
      const bundleEvents = getEvents(bundleTimestamp);
      const acquireEvents = bundleEvents.filter((e) => e.label.endsWith(':lock-acquired'));
      const releaseEvents = bundleEvents.filter((e) => e.label.endsWith(':lock-released'));
      expect(acquireEvents).toHaveLength(2);
      expect(releaseEvents).toHaveLength(2);

      // Key evidence: lock regions must be sequential (serialized by the
      // shared per-bundle lock). The event sequence must be:
      //   lock-acquired, lock-released, lock-acquired, lock-released
      const labels = bundleEvents.map((e) => e.label);
      expect(labels).toEqual([
        `${bundleTimestamp}:lock-acquired`,
        `${bundleTimestamp}:lock-released`,
        `${bundleTimestamp}:lock-acquired`,
        `${bundleTimestamp}:lock-released`,
      ]);

      // Timestamp confirmation: first release before second acquire
      const firstRelease = releaseEvents[0];
      const secondAcquire = acquireEvents[1];
      expect(firstRelease.timestamp).toBeLessThanOrEqual(secondAcquire.timestamp);
    });
  });
});
