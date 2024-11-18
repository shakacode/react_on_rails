import formAutoContent from 'form-auto-content';
import fs from 'fs';
import querystring from 'querystring';
import { createReadStream } from 'fs-extra';
import worker, { disableHttp2 } from '../src/worker';
import packageJson from '../../../package.json';
import {
  BUNDLE_TIMESTAMP,
  createVmBundle,
  resetForTest,
  vmBundlePath,
  getFixtureBundle,
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
    expect(res.payload).toEqual('{"html":"Dummy Object"}');
    expect(fs.existsSync(vmBundlePath(testName))).toEqual(true);
    expect(fs.existsSync(assetPath(testName))).toEqual(true);
    expect(fs.existsSync(assetPathOther(testName))).toEqual(true);
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
      expect(res.payload).toEqual('{"html":"Dummy Object"}');
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
      expect(res.payload).toEqual('{"html":"Dummy Object"}');
    },
  );

  test('post /asset-exists when asset exists', async () => {
    await createAsset(testName);
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
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ exists: true });
  });

  test('post /asset-exists when asset not exists', async () => {
    await createAsset(testName);
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
      })
      .end();
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ exists: false });
  });

  test('post /upload-assets', async () => {
    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const form = formAutoContent({
      gemVersion,
      protocolVersion,
      password: 'my_password',
      asset1: createReadStream(getFixtureAsset()),
      asset2: createReadStream(getOtherFixtureAsset()),
    });
    const res = await app.inject().post(`/upload-assets`).payload(form.payload).headers(form.headers).end();
    expect(res.statusCode).toBe(200);
    expect(fs.existsSync(assetPath(testName))).toEqual(true);
    expect(fs.existsSync(assetPathOther(testName))).toEqual(true);
  });
});
