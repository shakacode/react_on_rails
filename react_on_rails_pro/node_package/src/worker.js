/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

const path = require('path');
const cluster = require('cluster');
const express = require('express');
const busBoy = require('express-busboy');
const { buildConfig, getConfig } = require('./worker/configBuilder');
const handleRenderRequest = require('./worker/renderRequestHandler');

exports.run = function run(config) {
  buildConfig(config);
  const { bundlePath, port } = getConfig();

  const app = express();
  busBoy.extend(app, {
    upload: true,
    path: path.join(bundlePath, 'uploads'),
  });

  app.post('/render', (req, res) => {
    const { status, data } = handleRenderRequest(req);
    res.status(status);
    res.send(data);
  });

  app.listen(port, () => {
    console.log(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
  });
};
