/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

const fs = require('fs');
const fsExtra = require('fs-extra');
const path = require('path');
const cluster = require('cluster');
const express = require('express');
const busBoy = require('express-busboy');
const { buildVM, runInVM, getBundleUpdateTimeUtc } = require('./worker/vm');
const { buildConfig, getConfig } = require('./worker/configBuilder');

exports.run = function run(config) {
  buildConfig(config);
  const { bundlePath, port } = getConfig();

  const app = express();
  busBoy.extend(app, {
    upload: true,
    path: path.join(bundlePath, 'uploads'),
  });

  app.post('/render', (req, res) => {
    console.log(`worker #${cluster.worker.id} received render request with with code ${req.body.renderingRequest}`);
    const bundleFilePath = path.join(bundlePath, 'bundle.js');

    // If gem has posted updated bundle:
    if (req.files.bundle) {
      console.log('Worker received new bundle');
      fsExtra.copySync(req.files.bundle.file, bundleFilePath);
      buildVM(bundleFilePath);
      const result = runInVM(req.body.renderingRequest);

      res.send({
        renderedHtml: result,
      });

      return;
    }

    // If bundle was updated:
    if (!getBundleUpdateTimeUtc() ||
        (getBundleUpdateTimeUtc() < Number(req.body.bundleUpdateTimeUtc))) {
      console.log('Bundle was updated');

      // Check if bundle was uploaded:
      if (!fs.existsSync(bundleFilePath)) {
        res.status(410);
        res.send('No bundle uploaded');
        return;
      }

      // Check if another thread has already updated bundle and we don't need
      // to request it form the gem:
      const bundleUpdateTime = +(fs.statSync(bundleFilePath).mtime);
      if (bundleUpdateTime < Number(req.body.bundleUpdateTimeUtc)) {
        console.log('Bundle is outated');

        res.status(410);
        res.send('Bundle is outdated');
        return;
      }

      // If there is a fresh bundle, simply update VM:
      buildVM(bundleFilePath);
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
