const test = require('tape');
const request = require('supertest');
const path = require('path');
const worker = require('../src/worker');
const { getUploadedBundlePath, createUploadedBundle } = require('./helper');
const { buildVM } = require('../src/worker/vm');

test('POST /render when password is required but no password was provided', (assert) => {
  assert.plan(2);

  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  const app = worker.run({
    bundlePath: path.resolve(__dirname, './tmp'),
    password: 'password',
  });

  request(app)
    .post('/render')
    .type('json')
    .send({
      renderingRequest: 'ReactOnRails.dummy',
      bundleUpdateTimeUtc: 1495063024898,
      password: undefined,
    })
    .end((_err, res) => {
      assert.ok(res.error.status === 401);
      assert.ok(res.error.text === 'Wrong password');
      assert.end();
    });
});

test('POST /render when password is required but wrong password was provided', (assert) => {
  assert.plan(2);

  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  const app = worker.run({
    bundlePath: path.resolve(__dirname, './tmp'),
    password: 'password',
  });

  request(app)
    .post('/render')
    .type('json')
    .send({
      renderingRequest: 'ReactOnRails.dummy',
      bundleUpdateTimeUtc: 1495063024898,
      password: 'wrong',
    })
    .end((_err, res) => {
      assert.ok(res.error.status === 401);
      assert.ok(res.error.text === 'Wrong password');
      assert.end();
    });
});

test('POST /render when password is required and correct password was provided', (assert) => {
  assert.plan(2);

  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  const app = worker.run({
    bundlePath: path.resolve(__dirname, './tmp'),
    password: 'password',
  });

  request(app)
    .post('/render')
    .type('json')
    .send({
      renderingRequest: 'ReactOnRails.dummy',
      bundleUpdateTimeUtc: 1495063024898,
      password: 'password',
    })
    .end((_err, res) => {
      assert.ok(res.status === 200);
      assert.deepEqual(res.body, { renderedHtml: 'Dummy Object' });
      assert.end();
    });
});

test('POST /render when password is not required and no password was provided', (assert) => {
  assert.plan(2);

  createUploadedBundle();
  buildVM(getUploadedBundlePath());

  const app = worker.run({
    bundlePath: path.resolve(__dirname, './tmp'),
  });

  request(app)
    .post('/render')
    .type('json')
    .send({
      renderingRequest: 'ReactOnRails.dummy',
      bundleUpdateTimeUtc: 1495063024898,
      password: undefined,
    })
    .end((_err, res) => {
      assert.ok(res.status === 200);
      assert.deepEqual(res.body, { renderedHtml: 'Dummy Object' });
      assert.end();
    });
});
