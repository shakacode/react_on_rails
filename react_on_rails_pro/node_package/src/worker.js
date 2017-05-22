/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

'use strict';

const path = require('path');
const cluster = require('cluster');
const express = require('express');
const busBoy = require('express-busboy');
const log = require('winston');
const { buildConfig, getConfig } = require('./shared/configBuilder');
const authenticate = require('./worker/authHandler');
const handleRenderRequest = require('./worker/renderRequestHandlerVm');

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../package.json'));

// Turn on colorized log:
log.remove(log.transports.Console);
log.add(log.transports.Console, { colorize: true });

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

  //
  app.route('/bundles/:bundleTimestamp/render/:renderRequestDigest').post((req, res) => {
    // Authenticate Ruby client:
    const authResult = authenticate(req);

    if (typeof authResult === 'object') {
      const { status, data } = authResult;
      res.status(status);
      res.send(data);
      return;
    }

    // Hahdle rendering request:
    const { status, data, headers, die } = handleRenderRequest(req);

    // eslint-disable-next-line guard-for-in, no-restricted-syntax
    for (const key in headers) res.set(key, headers[key]);
    res.status(status);
    res.send(data);

    if (die) {
      cluster.worker.disconnect();
    }
  });

  //
  app.get('/info', (_req, res) => {
    res.send({
      node_version: process.version,
      renderer_version: packageJson.version,
    });
  });

  // In tests we will run worker in master thread, so we need to ensure server will not listen:
  if (!cluster.isMaster) {
    app.listen(port, () => {
      log.info(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
    });
  }

  return app;
};
