const request = require('supertest');
const fs = require('fs');
const path = require('path');
const querystring = require('querystring');

const worker = require('../src/worker');
const {
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
} = require('./helper');

const testName = 'worker';
const createVmBundleForTest = () => createVmBundle(testName);
const bundlePathForTest = () => bundlePath(testName);

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../../package.json'));

const gemVersion = packageJson.version;
const { protocolVersion } = packageJson;

describe('express worker', () => {
  beforeEach(async () => {
    await resetForTest(testName);
  });

  afterAll(async () => {
    await resetForTest(testName);
  });

  test('POST /bundles/:bundleTimestamp/render/:renderRequestDigest when bundle is provided and did not yet exist', async (done) => {
    expect.assertions(6);

    const app = worker({
      bundlePath: bundlePathForTest(),
    });

    request(app)
      .post(`/bundles/${BUNDLE_TIMESTAMP}/render/d41d8cd98f00b204e9800998ecf8427e`)
      .type('json')
      .field('renderingRequest', 'ReactOnRails.dummy')
      .field('gemVersion', gemVersion)
      .field('protocolVersion', protocolVersion)
      .attach('bundle', getFixtureBundle())
      .attach('asset1', getFixtureAsset())
      .attach('asset2', getOtherFixtureAsset())
      .end((_err, res) => {
        expect(res.headers['cache-control']).toBe('public, max-age=31536000');
        expect(res.status).toBe(200);
        expect(res.text).toEqual('{"html":"Dummy Object"}');
        expect(fs.existsSync(vmBundlePath(testName))).toEqual(true);
        expect(fs.existsSync(assetPath(testName))).toEqual(true);
        expect(fs.existsSync(assetPathOther(testName))).toEqual(true);
        done();
      });
  });

  test(
    'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
      'when password is required but no password was provided',
    async (done) => {
      expect.assertions(2);
      await createVmBundleForTest();

      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'password',
      });

      request(app)
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .type('json')
        .send({
          renderingRequest: 'ReactOnRails.dummy',
          password: undefined,
          gemVersion,
          protocolVersion,
        })
        .end((_err, res) => {
          expect(res.error.status).toBe(401);
          expect(res.error.text).toBe('Wrong password');
          done();
        });
    },
  );

  test(
    'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
      'when password is required but wrong password was provided',
    async (done) => {
      expect.assertions(2);

      await createVmBundleForTest();

      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'password',
      });

      request(app)
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .type('json')
        .send({
          renderingRequest: 'ReactOnRails.dummy',
          password: 'wrong',
          gemVersion,
          protocolVersion,
        })
        .end((_err, res) => {
          console.log('res', JSON.stringify(res));
          expect(res.error.status).toBe(401);
          expect(res.error.text).toBe('Wrong password');
          done();
        });
    },
  );

  test(
    'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
      'when password is required and correct password was provided',
    async (done) => {
      expect.assertions(3);

      await createVmBundleForTest();

      const app = worker({
        bundlePath: bundlePathForTest(),
        password: 'my_password',
        gemVersion,
        protocolVersion,
      });

      request(app)
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .type('json')
        .send({
          renderingRequest: 'ReactOnRails.dummy',
          password: 'my_password',
          gemVersion,
          protocolVersion,
        })
        .end((_err, res) => {
          expect(res.headers['cache-control']).toBe('public, max-age=31536000');
          expect(res.status).toBe(200);
          expect(res.text).toEqual('{"html":"Dummy Object"}');
          done();
        });
    },
  );

  test(
    'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
      'when password is not required and no password was provided',
    async (done) => {
      expect.assertions(3);

      await createVmBundleForTest();

      const app = worker({
        bundlePath: bundlePathForTest(),
      });

      request(app)
        .post('/bundles/1495063024898/render/d41d8cd98f00b204e9800998ecf8427e')
        .type('json')
        .send({
          renderingRequest: 'ReactOnRails.dummy',
          password: undefined,
          gemVersion,
          protocolVersion,
        })
        .end((_err, res) => {
          expect(res.headers['cache-control']).toBe('public, max-age=31536000');
          expect(res.status).toBe(200);
          expect(res.text).toEqual('{"html":"Dummy Object"}');
          done();
        });
    },
  );

  test('post /asset-exists when asset exists', async (done) => {
    expect.assertions(2);
    await createAsset(testName);
    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const query = querystring.stringify({ filename: 'loadable-stats.json' });

    request(app)
      .post(`/asset-exists?${query}`)
      .type('json')
      .send({
        password: 'my_password',
      })
      .end((_err, res) => {
        expect(res.status).toBe(200);
        expect(res.body).toEqual({ exists: true });
        done();
      });
  });

  test('post /asset-exists when asset not exists', async (done) => {
    expect.assertions(2);
    await createAsset(testName);
    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    const query = querystring.stringify({ filename: 'foobar.json' });

    request(app)
      .post(`/asset-exists?${query}`)
      .type('json')
      .send({
        password: 'my_password',
      })
      .end((_err, res) => {
        expect(res.status).toBe(200);
        expect(res.body).toEqual({ exists: false });
        done();
      });
  });

  test('post /upload-assets', async (done) => {
    expect.assertions(3);
    const app = worker({
      bundlePath: bundlePathForTest(),
      password: 'my_password',
    });

    request(app)
      .post(`/upload-assets`)
      .type('json')
      .field('gemVersion', gemVersion)
      .field('protocolVersion', protocolVersion)
      .field('password', 'my_password')
      .attach('asset1', getFixtureAsset())
      .attach('asset2', getOtherFixtureAsset())
      .end((_err, res) => {
        expect(res.status).toBe(200);
        expect(fs.existsSync(assetPath(testName))).toEqual(true);
        expect(fs.existsSync(assetPathOther(testName))).toEqual(true);
        done();
      });
  });
});
