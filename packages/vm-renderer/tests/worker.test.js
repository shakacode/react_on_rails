const test = require('tape');
const request = require('supertest');
const path = require('path');
const worker = require('../src/worker');
const { getUploadedBundlePath, createUploadedBundle } = require('./helper');
const { buildVM } = require('../src/worker/vm');

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../../package.json'));

const gemVersion = packageJson.version;
const protocolVersion = packageJson.protocolVersion;

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is required but no password was provided',
  assert => {
    assert.plan(2);

    createUploadedBundle();
    buildVM(getUploadedBundlePath());

    const app = worker.run({
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
        assert.ok(res.error.status === 401);
        assert.ok(res.error.text === 'Wrong password');
        assert.end();
      });
  },
);

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is required but wrong password was provided',
  assert => {
    assert.plan(2);

    createUploadedBundle();
    buildVM(getUploadedBundlePath());

    const app = worker.run({
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
        assert.ok(res.error.status === 401);
        assert.ok(res.error.text === 'Wrong password');
        assert.end();
      });
  },
);

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is required and correct password was provided',
  assert => {
    assert.plan(3);

    createUploadedBundle();
    buildVM(getUploadedBundlePath());

    const app = worker.run({
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
        assert.ok(res.headers['cache-control'] === 'public, max-age=31536000');
        assert.ok(res.status === 200);
        assert.deepEqual(res.body, { html: 'Dummy Object' });
        assert.end();
      });
  },
);

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is not required and no password was provided',
  assert => {
    assert.plan(3);

    createUploadedBundle();
    buildVM(getUploadedBundlePath());

    const app = worker.run({
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
        assert.ok(res.headers['cache-control'] === 'public, max-age=31536000');
        assert.ok(res.status === 200);
        assert.deepEqual(res.body, { html: 'Dummy Object' });
        assert.end();
      });
  },
);
