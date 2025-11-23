import formAutoContent from 'form-auto-content';
import fs from 'fs';
import querystring from 'querystring';
import { createReadStream } from 'fs-extra';
// Import this package's version and protocolVersion, not the workspace root's
import packageJson from '../package.json';
import worker, { disableHttp2 } from '../src/worker';
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
  serverBundleCachePath,
  assetPath,
  assetPathOther,
} from './helper';

const testName = 'worker';
const createVmBundleForTest = () => createVmBundle(testName);
const serverBundleCachePathForTest = () => serverBundleCachePath(testName);

const gemVersion = packageJson.version;
const { protocolVersion } = packageJson;
const railsEnv = 'test';

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
      serverBundleCachePath: serverBundleCachePathForTest(),
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      railsEnv,
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
      serverBundleCachePath: serverBundleCachePathForTest(),
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      railsEnv,
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
        serverBundleCachePath: serverBundleCachePathForTest(),
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
          railsEnv,
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
        serverBundleCachePath: serverBundleCachePathForTest(),
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
          railsEnv,
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
        serverBundleCachePath: serverBundleCachePathForTest(),
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
          railsEnv,
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
        serverBundleCachePath: serverBundleCachePathForTest(),
      });

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          password: undefined,
          gemVersion,
          protocolVersion,
          railsEnv,
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
      serverBundleCachePath: serverBundleCachePathForTest(),
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
      serverBundleCachePath: serverBundleCachePathForTest(),
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
      serverBundleCachePath: serverBundleCachePathForTest(),
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
      serverBundleCachePath: serverBundleCachePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      railsEnv,
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
      serverBundleCachePath: serverBundleCachePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      railsEnv,
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

  describe('gem version validation', () => {
    test('allows request when gem version matches package version', async () => {
      await createVmBundleForTest();

      const app = worker({
        serverBundleCachePath: serverBundleCachePathForTest(),
      });

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          gemVersion: packageJson.version,
          protocolVersion,
          railsEnv: 'development',
        });

      expect(res.statusCode).toBe(200);
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });

    test('rejects request in development when gem version does not match', async () => {
      await createVmBundleForTest();

      const app = worker({
        serverBundleCachePath: serverBundleCachePathForTest(),
      });

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          gemVersion: '999.0.0',
          protocolVersion,
          railsEnv: 'development',
        })
        .end();

      expect(res.statusCode).toBe(412);
      expect(res.payload).toContain('Version mismatch error');
      expect(res.payload).toContain('999.0.0');
      expect(res.payload).toContain(packageJson.version);
    });

    test('allows request in production when gem version does not match (with warning)', async () => {
      await createVmBundleForTest();

      const app = worker({
        serverBundleCachePath: serverBundleCachePathForTest(),
      });

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          gemVersion: '999.0.0',
          protocolVersion,
          railsEnv: 'production',
        });

      expect(res.statusCode).toBe(200);
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });

    test('normalizes gem version with dot before prerelease (4.0.0.rc.1 == 4.0.0-rc.1)', async () => {
      await createVmBundleForTest();

      const app = worker({
        serverBundleCachePath: serverBundleCachePathForTest(),
      });

      // If package version is 4.0.0, this tests that 4.0.0.rc.1 gets normalized to 4.0.0-rc.1
      // For this test to work properly, we need to use a version that when normalized matches
      // Let's create a version with .rc. that normalizes to the package version
      const gemVersionWithDot = packageJson.version.replace(/-([a-z]+)/, '.$1');

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          gemVersion: gemVersionWithDot,
          protocolVersion,
          railsEnv: 'development',
        });

      expect(res.statusCode).toBe(200);
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });

    test('normalizes gem version case-insensitively (4.0.0-RC.1 == 4.0.0-rc.1)', async () => {
      await createVmBundleForTest();

      const app = worker({
        serverBundleCachePath: serverBundleCachePathForTest(),
      });

      const gemVersionUpperCase = packageJson.version.toUpperCase();

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          gemVersion: gemVersionUpperCase,
          protocolVersion,
          railsEnv: 'development',
        });

      expect(res.statusCode).toBe(200);
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });

    test('handles whitespace in gem version', async () => {
      await createVmBundleForTest();

      const app = worker({
        serverBundleCachePath: serverBundleCachePathForTest(),
      });

      const gemVersionWithWhitespace = `  ${packageJson.version}  `;

      const res = await app
        .inject()
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .payload({
          renderingRequest: 'ReactOnRails.dummy',
          gemVersion: gemVersionWithWhitespace,
          protocolVersion,
          railsEnv: 'development',
        });

      expect(res.statusCode).toBe(200);
      expect(res.payload).toBe('{"html":"Dummy Object"}');
    });
  });
});
