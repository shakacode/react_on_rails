import test from 'tape';
import request from 'supertest';
import path from 'path';

import worker from '../src/worker';
import { BUNDLE_TIMESTAMP, createVmBundle, resetForTest, uploadedBundlePath, createUploadedBundle } from './helper';

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../../package.json'));

const gemVersion = packageJson.version;
const { protocolVersion } = packageJson;

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
  'when bundle is provided',
  async (assert) => {
    assert.plan(3);

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
        assert.equal(res.headers['cache-control'], 'public, max-age=31536000');
        assert.equal(res.status, 200);
        assert.deepEqual(res.body, { html: 'Dummy Object' });
        assert.end();
      });
  },
);

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is required but no password was provided',
  async (assert) => {
    assert.plan(2);
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
        assert.equals(res.error.status, 401);
        assert.equals(res.error.text, 'Wrong password');
        assert.end();
      });
  },
);

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is required but wrong password was provided',
  async (assert) => {
    assert.plan(2);
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
        assert.equal(res.error.status, 401);
        assert.equal(res.error.text, 'Wrong password');
        assert.end();
      });
  },
);

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is required and correct password was provided',
  async (assert) => {
    assert.plan(3);
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
        assert.equal(res.headers['cache-control'], 'public, max-age=31536000');
        assert.equal(res.status, 200);
        assert.deepEqual(res.body, { html: 'Dummy Object' });
        assert.end();
      });
  },
);

test(
  'POST /bundles/:bundleTimestamp/render/:renderRequestDigest ' +
    'when password is not required and no password was provided',
  async (assert) => {
    assert.plan(3);
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
        assert.equal(res.headers['cache-control'], 'public, max-age=31536000');
        assert.equal(res.status, 200);
        assert.deepEqual(res.body, { html: 'Dummy Object' });
        assert.end();
      });
  },
);
