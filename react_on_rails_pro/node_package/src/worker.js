/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

const cluster = require('cluster');
const express = require('express');
var busBoy = require('express-busboy');
const { runInVM } = require('./worker/vm');
const configBuilder = require('./worker/configBuilder');
const bundleWatcher = require('./worker/bundleWatcher');

exports.run = function run() {
  const { bundlePath, bundleFileName, port } = configBuilder();
  bundleWatcher(bundlePath, bundleFileName);

  const app = express();
  busBoy.extend(app, {
    upload: true,
    path: 'tmp/uploads',
  });

  app.post('/bundle', (req, res) => {
    console.log(`worker #${cluster.worker.id} received bundle update request`);
    console.log('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!', req.files)
    res.send('blah');
  });

  app.post('/render', (req, res) => {
    console.log(`worker #${cluster.worker.id} received render request with with code ${req.body.renderingRequest}`);
    const result = runInVM(req.body.renderingRequest);

    res.send({
      renderedHtml: result,
    });
  });

  app.listen(port, () => {
    console.log(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
  });
};
