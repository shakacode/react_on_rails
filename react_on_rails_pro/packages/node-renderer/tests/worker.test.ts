import formAutoContent from 'form-auto-content';
import fs from 'fs';
import path from 'path';
import querystring from 'querystring';
import { createReadStream } from 'fs-extra';
import worker, { disableHttp2 } from '../src/worker';
import packageJson from '../../../package.json';
import {
  BUNDLE_TIMESTAMP,
  SECONDARY_BUNDLE_TIMESTAMP,
  createVmBundle,
  resetForTest,
  vmBundlePath,
  vmSecondaryBundlePath,
  getFixtureBundle,
  getFixtureSecondaryBundle,
  getFixtureAsset,
  getOtherFixtureAsset,
  createAsset,
  bundlePath,
  assetPath,
  assetPathOther,
} from './helper';

const testName = 'worker';
const createVmBundleForTest = () => createVmBundle(testName);
const bundlePathForTest = () => bundlePath(testName);

const gemVersion = packageJson.version;
const { protocolVersion } = packageJson;

disableHttp2();

describe('worker', () => {
  beforeEach(async () => {
    await resetForTest(testName);
  });

  afterAll(async () => {
    await resetForTest(testName);
  });

  test('POST /bundles/:bundleTimestamp/render/:renderRequestDigest when bundle is provided and did not yet exist', async () => {
    const app = worker({
      bundlePath: bundlePathForTest(),
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      renderingRequest: 'ReactOnRails.dummy',
      bundle: createReadStream(getFixtureBundle()),
      asset1: createReadStream(getFixtureAsset()),
      asset2: createReadStream(getOtherFixtureAsset()),
    });
    const res = await app
      .inject()
      .post(`/bundles/${BUNDLE_TIMESTAMP}/render/d41d8cd98f00b204e9800998ecf8427e`)
      .payload(form.payload)
      .headers(form.headers)
      .end();
    expect(res.statusCode).toBe(200);
    expect(res.headers['cache-control']).toBe('public, max-age=31536000');
    expect(res.payload).toBe('{"html":"Dummy Object"}');
    expect(fs.existsSync(vmBundlePath(testName))).toBe(true);
    expect(fs.existsSync(assetPath(testName, String(BUNDLE_TIMESTAMP)))).toBe(true);
    expect(fs.existsSync(assetPathOther(testName, String(BUNDLE_TIMESTAMP)))).toBe(true);
  });

  test('POST /bundles/:bundleTimestamp/render/:renderRequestDigest', async () => {
    const app = worker({
      bundlePath: bundlePathForTest(),
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      renderingRequest: 'ReactOnRails.dummy',
      bundle: createReadStream(getFixtureBundle()),
      [`bundle_${SECONDARY_BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureSecondaryBundle()),
      asset1: createReadStream(getFixtureAsset()),
      asset2: createReadStream(getOtherFixtureAsset()),
    });
    const res = await app
      .inject()
      .post(`/bundles/${BUNDLE_TIMESTAMP}/render/d41d8cd98f00b204e9800998ecf8427e`)
      .payload(form.payload)
      .headers(form.headers)
      .end();
    expect(res.statusCode).toBe(200);
    expect(res.headers['cache-control']).toBe('public, max-age=31536000');
    expect(res.payload).toBe('{"html":"Dummy Object"}');
    expect(fs.existsSync(vmBundlePath(testName))).toBe(true);
    expect(fs.existsSync(assetPath(testName, String(BUNDLE_TIMESTAMP)))).toBe(true);
    expect(fs.existsSync(assetPathOther(testName, String(BUNDLE_TIMESTAMP)))).toBe(true);
    expect(fs.existsSync(assetPath(testName, String(SECONDARY_BUNDLE_TIMESTAMP)))).toBe(true);
    expect(fs.existsSync(assetPathOther(testName, String(SECONDARY_BUNDLE_TIMESTAMP)))).toBe(true);
  });

  test(
    'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
      'when password is required but no password was provided',
    async () => {
      await createVmBundleForTest();

      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'password',
      });

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          password: undefined,
          gemVersion,
          protocolVersion,
        })
        .end();
      expect(res.statusCode).toBe(401);
      expect(res.payload).toBe('Wrong password');
    },
  );

  test(
    'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
      'when password is required but wrong password was provided',
    async () => {
      await createVmBundleForTest();

      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'password',
      });

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          password: 'wrong',
          gemVersion,
          protocolVersion,
        })
        .end();
      expect(res.statusCode).toBe(401);
      expect(res.payload).toBe('Wrong password');
    },
  );

  test(
    'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
      'when password is required and correct password was provided',
    async () => {
      await createVmBundleForTest();

      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          password: 'my_password',
          gemVersion,
          protocolVersion,
        })
        .end();
      expect(res.statusCode).toBe(200);
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    },
  );

  test(
    'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
      'when password is not required and no password was provided',
    async () => {
      await createVmBundleForTest();

      const app = worker({
        bundlePath: bundlePathForTest(),
      });

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          password: undefined,
          gemVersion,
          protocolVersion,
        });
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.statusCode).toBe(200);
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    },
  );

  test('post /asset-exists when asset exists', async () => {
    const bundleHash = 'some-bundle-hash';
    await createAsset(testName, bundleHash);

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const query = querystring.stringify({ filename: 'loadable-stats.json' });

    const res = await app
      .inject()
      .post(`/asset-exists?${query}`)
      .payload({
        password: 'my_password',
        targetBundles: [bundleHash],
      })
      .end();
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      exists: true,
      results: [{ bundleHash, exists: true }],
    });
  });

  test('post /asset-exists when asset not exists', async () => {
    const bundleHash = 'some-bundle-hash';
    await createAsset(testName, bundleHash);

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const query = querystring.stringify({ filename: 'foobar.json' });

    const res = await app
      .inject()
      .post(`/asset-exists?${query}`)
      .payload({
        password: 'my_password',
        targetBundles: [bundleHash],
      })
      .end();
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      exists: false,
      results: [{ bundleHash, exists: false }],
    });
  });

  test('post /asset-exists requires targetBundles (protocol version 2.0.0)', async () => {
    await createAsset(testName, String(BUNDLE_TIMESTAMP));
    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const query = querystring.stringify({ filename: 'loadable-stats.json' });

    const res = await app
      .inject()
      .post(`/asset-exists?${query}`)
      .payload({
        password: 'my_password',
      })
      .end();
    expect(res.statusCode).toBe(400);

    expect(res.payload).toContain('No targetBundles provided');
  });

  test('post /upload-assets', async () => {
    const bundleHash = 'some-bundle-hash';

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      targetBundles: [bundleHash],
      asset1: createReadStream(getFixtureAsset()),
      asset2: createReadStream(getOtherFixtureAsset()),
    });
    const res = await app.inject().post(`/upload-assets`).payload(form.payload).headers(form.headers).end();
    expect(res.statusCode).toBe(200);
    expect(fs.existsSync(assetPath(testName, bundleHash))).toBe(true);
    expect(fs.existsSync(assetPathOther(testName, bundleHash))).toBe(true);
  });

  test('post /upload-assets with multiple bundles and assets', async () => {
    const bundleHash = 'some-bundle-hash';
    const bundleHashOther = 'some-other-bundle-hash';

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      targetBundles: [bundleHash, bundleHashOther],
      asset1: createReadStream(getFixtureAsset()),
      asset2: createReadStream(getOtherFixtureAsset()),
    });

    const res = await app.inject().post(`/upload-assets`).payload(form.payload).headers(form.headers).end();
    expect(res.statusCode).toBe(200);
    expect(fs.existsSync(assetPath(testName, bundleHash))).toBe(true);
    expect(fs.existsSync(assetPathOther(testName, bundleHash))).toBe(true);
    expect(fs.existsSync(assetPath(testName, bundleHashOther))).toBe(true);
    expect(fs.existsSync(assetPathOther(testName, bundleHashOther))).toBe(true);
  });

  test('post /upload-assets with bundles and assets', async () => {
    const bundleHash = 'some-bundle-hash';
    const secondaryBundleHash = 'secondary-bundle-hash';

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      targetBundles: [bundleHash, secondaryBundleHash],
      [`bundle_${bundleHash}`]: createReadStream(getFixtureBundle()),
      [`bundle_${secondaryBundleHash}`]: createReadStream(getFixtureSecondaryBundle()),
      asset1: createReadStream(getFixtureAsset()),
      asset2: createReadStream(getOtherFixtureAsset()),
    });

    const res = await app.inject().post(`/upload-assets`).payload(form.payload).headers(form.headers).end();
    expect(res.statusCode).toBe(200);

    // Verify assets are copied to both bundle directories
    expect(fs.existsSync(assetPath(testName, bundleHash))).toBe(true);
    expect(fs.existsSync(assetPathOther(testName, bundleHash))).toBe(true);
    expect(fs.existsSync(assetPath(testName, secondaryBundleHash))).toBe(true);
    expect(fs.existsSync(assetPathOther(testName, secondaryBundleHash))).toBe(true);

    // Verify bundles are placed in their correct directories
    const bundle1Path = path.join(bundlePathForTest(), bundleHash, `${bundleHash}.js`);
    const bundle2Path = path.join(bundlePathForTest(), secondaryBundleHash, `${secondaryBundleHash}.js`);
    expect(fs.existsSync(bundle1Path)).toBe(true);
    expect(fs.existsSync(bundle2Path)).toBe(true);

    // Verify the directory structure is correct
    const bundle1Dir = path.join(bundlePathForTest(), bundleHash);
    const bundle2Dir = path.join(bundlePathForTest(), secondaryBundleHash);

    // Each bundle directory should contain: 1 bundle file + 2 assets = 3 files total
    const bundle1Files = fs.readdirSync(bundle1Dir);
    const bundle2Files = fs.readdirSync(bundle2Dir);

    expect(bundle1Files).toHaveLength(3); // bundle file + 2 assets
    expect(bundle2Files).toHaveLength(3); // bundle file + 2 assets

    // Verify the specific files exist in each directory
    expect(bundle1Files).toContain(`${bundleHash}.js`);
    expect(bundle1Files).toContain('loadable-stats.json');
    expect(bundle1Files).toContain('loadable-stats-other.json');

    expect(bundle2Files).toContain(`${secondaryBundleHash}.js`);
    expect(bundle2Files).toContain('loadable-stats.json');
    expect(bundle2Files).toContain('loadable-stats-other.json');
  });

  test('post /upload-assets with only bundles (no assets)', async () => {
    const bundleHash = 'bundle-only-hash';

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      targetBundles: [bundleHash],
      [`bundle_${bundleHash}`]: createReadStream(getFixtureBundle()),
    });

    const res = await app.inject().post(`/upload-assets`).payload(form.payload).headers(form.headers).end();
    expect(res.statusCode).toBe(200);

    // Verify bundle is placed in the correct directory
    const bundleFilePath = path.join(bundlePathForTest(), bundleHash, `${bundleHash}.js`);
    expect(fs.existsSync(bundleFilePath)).toBe(true);

    // Verify the directory structure is correct
    const bundleDir = path.join(bundlePathForTest(), bundleHash);
    const files = fs.readdirSync(bundleDir);

    // Should only contain the bundle file, no assets
    expect(files).toHaveLength(1);
    expect(files[0]).toBe(`${bundleHash}.js`);

    // Verify no asset files were accidentally copied
    expect(files).not.toContain('loadable-stats.json');
    expect(files).not.toContain('loadable-stats-other.json');
  });

  test('post /upload-assets with no assets and no bundles (empty request)', async () => {
    const bundleHash = 'empty-request-hash';

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      targetBundles: [bundleHash],
      // No assets or bundles uploaded
    });

    const res = await app.inject().post(`/upload-assets`).payload(form.payload).headers(form.headers).end();
    expect(res.statusCode).toBe(200);

    // Verify bundle directory is created
    const bundleDirectory = path.join(bundlePathForTest(), bundleHash);
    expect(fs.existsSync(bundleDirectory)).toBe(true);

    // Verify no files were copied (since none were uploaded)
    const files = fs.readdirSync(bundleDirectory);
    expect(files).toHaveLength(0);
  });

  test('post /upload-assets with duplicate bundle hash silently skips overwrite and returns 200', async () => {
    const bundleHash = 'duplicate-bundle-hash';

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    // First upload with bundle
    const form1 = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      targetBundles: [bundleHash],
      [`bundle_${bundleHash}`]: createReadStream(getFixtureBundle()),
    });

    const res1 = await app
      .inject()
      .post(`/upload-assets`)
      .payload(form1.payload)
      .headers(form1.headers)
      .end();
    expect(res1.statusCode).toBe(200);
    expect(res1.body).toBe(''); // Empty body on success

    // Verify first bundle was created correctly
    const bundleDir = path.join(bundlePathForTest(), bundleHash);
    expect(fs.existsSync(bundleDir)).toBe(true);
    const bundleFilePath = path.join(bundleDir, `${bundleHash}.js`);
    expect(fs.existsSync(bundleFilePath)).toBe(true);

    // Get file stats to verify it's the first bundle
    const firstBundleStats = fs.statSync(bundleFilePath);
    const firstBundleSize = firstBundleStats.size;
    const firstBundleModTime = firstBundleStats.mtime.getTime();

    // Second upload with the same bundle hash but different content
    // This logs: "File exists when trying to overwrite bundle... Assuming bundle written by other thread"
    // Then silently skips the overwrite operation and returns 200 success
    const form2 = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      targetBundles: [bundleHash],
      [`bundle_${bundleHash}`]: createReadStream(getFixtureSecondaryBundle()), // Different content
    });

    const res2 = await app
      .inject()
      .post(`/upload-assets`)
      .payload(form2.payload)
      .headers(form2.headers)
      .end();
    expect(res2.statusCode).toBe(200); // Still returns 200 success (no error)
    expect(res2.body).toBe(''); // Empty body, no error message returned to client

    // Verify the bundle directory still exists
    expect(fs.existsSync(bundleDir)).toBe(true);

    // Verify the bundle file still exists
    expect(fs.existsSync(bundleFilePath)).toBe(true);

    // Verify the file was NOT overwritten (original bundle is preserved)
    const secondBundleStats = fs.statSync(bundleFilePath);
    const secondBundleSize = secondBundleStats.size;
    const secondBundleModTime = secondBundleStats.mtime.getTime();

    // The file size should be the same as the first upload (no overwrite occurred)
    expect(secondBundleSize).toBe(firstBundleSize);

    // The modification time should be the same (file wasn't touched)
    expect(secondBundleModTime).toBe(firstBundleModTime);

    // Verify the directory only contains one file (the original bundle)
    const files = fs.readdirSync(bundleDir);
    expect(files).toHaveLength(1);
    expect(files[0]).toBe(`${bundleHash}.js`);

    // Verify the original content is preserved (62 bytes from bundle.js, not 84 from secondary-bundle.js)
    expect(secondBundleSize).toBe(62); // Size of getFixtureBundle(), not getFixtureSecondaryBundle()
  });

  test('post /upload-assets with bundles placed in their own hash directories, not targetBundles directories', async () => {
    const bundleHash = 'actual-bundle-hash';
    const targetBundleHash = 'target-bundle-hash'; // Different from actual bundle hash

    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      targetBundles: [targetBundleHash], // This should NOT affect where the bundle is placed
      [`bundle_${bundleHash}`]: createReadStream(getFixtureBundle()), // Bundle with its own hash
    });

    const res = await app.inject().post(`/upload-assets`).payload(form.payload).headers(form.headers).end();
    expect(res.statusCode).toBe(200);

    // Verify the bundle was placed in its OWN hash directory, not the targetBundles directory
    const actualBundleDir = path.join(bundlePathForTest(), bundleHash);
    const targetBundleDir = path.join(bundlePathForTest(), targetBundleHash);

    // Bundle should exist in its own hash directory
    expect(fs.existsSync(actualBundleDir)).toBe(true);
    const bundleFilePath = path.join(actualBundleDir, `${bundleHash}.js`);
    expect(fs.existsSync(bundleFilePath)).toBe(true);

    // Target bundle directory should also exist (created for assets)
    expect(fs.existsSync(targetBundleDir)).toBe(true);

    // But the bundle file should NOT be in the target bundle directory
    const targetBundleFilePath = path.join(targetBundleDir, `${bundleHash}.js`);
    expect(fs.existsSync(targetBundleFilePath)).toBe(false);

    // Verify the bundle is in the correct location with correct name
    const files = fs.readdirSync(actualBundleDir);
    expect(files).toHaveLength(1);
    expect(files[0]).toBe(`${bundleHash}.js`);

    // Verify the target bundle directory is empty (no assets uploaded)
    const targetFiles = fs.readdirSync(targetBundleDir);
    expect(targetFiles).toHaveLength(0);
  });

  // Incremental Render Endpoint Tests
  describe('POST /bundles/:bundleTimestamp/incremental-render/:renderRequestDigest', () => {
    test('renders successfully when bundle and assets are pre-uploaded', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // First, upload the bundle and assets using the upload-assets endpoint
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
        asset1: createReadStream(getFixtureAsset()),
        asset2: createReadStream(getOtherFixtureAsset()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Verify bundle and assets are in place
      expect(fs.existsSync(vmBundlePath(testName))).toBe(true);
      expect(fs.existsSync(assetPath(testName, String(BUNDLE_TIMESTAMP)))).toBe(true);
      expect(fs.existsSync(assetPathOther(testName, String(BUNDLE_TIMESTAMP)))).toBe(true);

      // Now test the incremental render endpoint with NDJSON content
      const ndjsonPayload = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(200);
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });

    test('renders successfully with multiple dependency bundles', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload both bundles and assets
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP), String(SECONDARY_BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
        [`bundle_${SECONDARY_BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureSecondaryBundle()),
        asset1: createReadStream(getFixtureAsset()),
        asset2: createReadStream(getOtherFixtureAsset()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Verify both bundles and assets are in place
      expect(fs.existsSync(vmBundlePath(testName))).toBe(true);
      expect(fs.existsSync(vmSecondaryBundlePath(testName))).toBe(true);
      expect(fs.existsSync(assetPath(testName, String(BUNDLE_TIMESTAMP)))).toBe(true);
      expect(fs.existsSync(assetPath(testName, String(SECONDARY_BUNDLE_TIMESTAMP)))).toBe(true);

      // Test incremental render with multiple dependency bundles
      const ndjsonPayload = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP), String(SECONDARY_BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(200);
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });

    test('fails when bundle is not pre-uploaded', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Don't upload any bundles - just try to render
      const ndjsonPayload = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(410);
      expect(res.payload).toContain('No bundle uploaded');
    });

    test('fails when password is required but not provided', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Try incremental render without password
      const ndjsonPayload = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(401);
      expect(res.payload).toBe('Wrong password');
    });

    test('fails when password is required but wrong password provided', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Try incremental render with wrong password
      const ndjsonPayload = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        password: 'wrong_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(401);
      expect(res.payload).toBe('Wrong password');
    });

    test('succeeds when password is required and correct password provided', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Try incremental render with correct password
      const ndjsonPayload = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(200);
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });

    test('succeeds when password is not required and no password provided', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        // No password required
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Try incremental render without password
      const ndjsonPayload = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(200);
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });

    test('fails with invalid JSON in first chunk', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Try incremental render with invalid JSON
      const invalidJsonPayload = '{"invalid": json, missing quotes}' + '\n';

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(invalidJsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(400);
      expect(res.payload).toContain('Invalid JSON chunk');
    });

    test('fails with missing required fields in first chunk', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Try incremental render with missing renderingRequest
      const incompletePayload = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        // Missing renderingRequest
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(incompletePayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(400);
      expect(res.payload).toContain('INVALID NIL or NULL result for rendering');
    });

    // TODO: Implement incremental updates and update this test
    test('handles multiple NDJSON chunks but only processes first one for now', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Send multiple NDJSON chunks (only first one should be processed for now)
      const firstChunk = `${JSON.stringify({
        gemVersion,
        protocolVersion,
        password: 'my_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const secondChunk = `${JSON.stringify({
        update: 'data',
        timestamp: Date.now(),
      })}\n`;

      const thirdChunk = `${JSON.stringify({
        anotherUpdate: 'more data',
        sequence: 2,
      })}\n`;

      const multiChunkPayload = firstChunk + secondChunk + thirdChunk;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(multiChunkPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      // Should succeed because first chunk is valid and bundle exists
      expect(res.statusCode).toBe(200);
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.payload).toBe('{"html":"Dummy Object"}');

      // Note: Additional chunks are not processed yet (incremental functionality not implemented)
      // This test will need to be updated when incremental updates are implemented
    });

    test('fails when protocol version is missing', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        gemVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(412);

      // Try incremental render without protocol version
      const ndjsonPayload = `${JSON.stringify({
        gemVersion,
        password: 'my_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(412);
      expect(res.payload).toContain('Unsupported renderer protocol version MISSING');
    });

    test('fails when gem version is missing', async () => {
      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
      });

      // Upload bundle first
      const uploadForm = formAutoContent({
        protocolVersion,
        password: 'my_password',
        targetBundles: [String(BUNDLE_TIMESTAMP)],
        [`bundle_${BUNDLE_TIMESTAMP}`]: createReadStream(getFixtureBundle()),
      });

      const uploadRes = await app
        .inject()
        .post('/upload-assets')
        .payload(uploadForm.payload)
        .headers(uploadForm.headers)
        .end();
      expect(uploadRes.statusCode).toBe(200);

      // Try incremental render without gem version
      const ndjsonPayload = `${JSON.stringify({
        protocolVersion,
        password: 'my_password',
        renderingRequest: 'ReactOnRails.dummy',
        dependencyBundleTimestamps: [String(BUNDLE_TIMESTAMP)],
      })}\n`;

      const res = await app
        .inject()
        .post(`/bundles/${BUNDLE_TIMESTAMP}/incremental-render/d41d8cd98f00b204e9800998ecf8427e`)
        .payload(ndjsonPayload)
        .headers({
          'Content-Type': 'application/x-ndjson',
        })
        .end();

      expect(res.statusCode).toBe(200);
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });
  });
});
