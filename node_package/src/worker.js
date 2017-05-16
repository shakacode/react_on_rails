/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

const path = require('path');
const cluster = require('cluster');
const express = require('express');
const busBoy = require('express-busboy');
const { buildConfig, getConfig } = require('./worker/configBuilder');
const { initiConsoleHistory } = require('./worker/consoleHistory');
const handleRenderRequest = require('./worker/renderRequestHandler');
const handleRenderRequestNew = require('./worker/renderRequestHandlerNew');

/**
 *
 */
exports.run = function run(config) {
  // Patch console to store the history in react_on_rails compartibe format:
  initiConsoleHistory();

  // Store config in app state. From now it can be loaded by any module using getConfig():
  buildConfig(config);

  const { bundlePath, port } = getConfig();

  const app = express();
  busBoy.extend(app, {
    upload: true,
    path: path.join(bundlePath, 'uploads'),
  });

  app.post('/render', (req, res) => {
    const { status, data, die } = handleRenderRequestNew(req);
    res.status(status);
    res.send(data);

    if (die) process.exit();
  });

  app.listen(port, () => {
    console.log(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
  });
};
