/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

const fs = require('fs');
const mv = require('mv');
const path = require('path');
const cluster = require('cluster');
const express = require('express');
const busBoy = require('express-busboy');
const { buildVMNew, getBundleUpdateTimeUtc, runInVM } = require('./worker/vm');
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

  app.post('/render', (req, res) => {
    console.log(`worker #${cluster.worker.id} received render request with with code ${req.body.renderingRequest}`);
    const bundlePath = path.resolve(__dirname, '../../tmp/bundle.js');

    // If gem has posted updated bundle:
    if (req.files.bundle) {
      mv(req.files.bundle.file, bundlePath, {mkdirp: true}, (err) => {});
      buildVMNew(bundlePath);
    }

    // If bundle was updated:
    if (getBundleUpdateTimeUtc() < Number(req.bundleUpdateTimeUtc)) {
      // Check if bundle was uploaded:
      if (!fs.existsSync(bundlePath)) {
        res.status(410);
        res.send('No bundle uploaded');
      }

      // Check if another thread has already updated bundle and we don't need to request it form the gem:
      const bundleUpdateTime = +(fs.statSync(bundlePath).mtime);
      if (bundleUpdateTime < Number(req.bundleUpdateTimeUtc)) {
        res.status(410);
        res.send('Bundle is outdated');
      }

      // If there is a fresh bundle, simply update VM:
      buildVMNew(bundlePath);
    }

    const result = runInVM(req.body.renderingRequest);

    res.send({
      renderedHtml: result,
    });
  });

  app.listen(port, () => {
    console.log(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
  });
};
