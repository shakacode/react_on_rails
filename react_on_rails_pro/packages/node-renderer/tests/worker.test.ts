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
  });
});
