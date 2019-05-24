const request = require('supertest');
const path = require('path');

const worker = require('../lib/worker');
const {
  BUNDLE_TIMESTAMP,
  createVmBundle,
  resetForTest,
  uploadedBundlePath,
  createUploadedBundle,
} = require('./helper');

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../../package.json'));

const gemVersion = packageJson.version;
const { protocolVersion } = packageJson;

test('POST /bundles/:bundleTimestamp/render/:renderRequestDigest when bundle is provided', async done => {
  expect.assertions(3);

  resetForTest();
  createUploadedBundle();

  const app = worker({
    bundlePath: path.resolve(__dirname, './tmp'),
  });

  request(app)
    .post(`/bundles/${BUNDLE_TIMESTAMP}/render/d41d8cd98f00b204e9800998ecf8427e`)
    .type('json')
    .field('renderingRequest', 'ReactOnRails.dummy')
    .field('gemVersion', gemVersion)
    .field('protocolVersion', protocolVersion)
    .attach('bundle', uploadedBundlePath())
    .end((_err, res) => {
      expect(res.headers['cache-control']).toBe('public, max-age=31536000');
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ html: 'Dummy Object' });
      done();
    });
});

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is required but no password was provided',
  async done => {
    expect.assertions(2);
    resetForTest();
    await createVmBundle();

    const app = worker({
      bundlePath: path.resolve(__dirname, './tmp'),
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
  async done => {
    expect.assertions(2);
    resetForTest();

    await createVmBundle();

    const app = worker({
      bundlePath: path.resolve(__dirname, './tmp'),
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
  async done => {
    expect.assertions(3);
    resetForTest();

    await createVmBundle();

    const app = worker({
      bundlePath: path.resolve(__dirname, './tmp'),
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
        expect(res.body).toEqual({ html: 'Dummy Object' });
        done();
      });
  },
);

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is not required and no password was provided',
  async done => {
    expect.assertions(3);
    resetForTest();

    await createVmBundle();

    const app = worker({
      bundlePath: path.resolve(__dirname, './tmp'),
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
        expect(res.body).toEqual({ html: 'Dummy Object' });
        done();
      });
  },
);
