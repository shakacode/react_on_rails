/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

const path = require('path');
const cluster = require('cluster');
const express = require('express');
const busBoy = require('express-busboy');
const log = require('winston');
const { buildConfig, getConfig } = require('./shared/configBuilder');
const handleRenderRequest = require('./worker/renderRequestHandlerVm');
const packageJson = require(__dirname + '/../../package.json');

// Turn on colorized log:
log.remove(log.transports.Console);
log.add(log.transports.Console, {colorize: true});

/**
 *
 */
exports.run = function run(config) {
  // Store config in app state. From now it can be loaded by any module using getConfig():
  buildConfig(config);

  const { bundlePath, port, logLevel } = getConfig();

  // Turn on colorized log:
  log.remove(log.transports.Console);
  log.add(log.transports.Console, { colorize: true });

  // Set log level from config:
  log.level = logLevel;

  const app = express();
  busBoy.extend(app, {
    upload: true,
    path: path.join(bundlePath, 'uploads'),
  });

  app.post('/render', (req, res) => {
    const { status, data, die } = handleRenderRequest(req);
    res.status(status);
    res.send(data);

    if (die) {
      cluster.worker.disconnect();
    }
  });

  app.get('/', (req, res) => {
    res.send({
      node_version: process.version,
      renderer_version: packageJson.version,
    });
  })

  app.listen(port, () => {
    log.info(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
  });
};
