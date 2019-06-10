/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

const path = require('path');
const cluster = require('cluster');
const express = require('express');
const busBoy = require('express-busboy');
const log = require('./shared/log');
const packageJson = require('./shared/packageJson');
const { buildConfig, getConfig } = require('./shared/configBuilder');
const checkProtocolVersion = require('./worker/checkProtocolVersionHandler');
const authenticate = require('./worker/authHandler');
const handleRenderRequest = require('./worker/handleRenderRequest');
const { errorResponseResult, formatExceptionMessage } = require('./shared/utils');
const errorReporter = require('./shared/errorReporter');

function setHeaders(headers, res) {
  Object.keys(headers).forEach(key => res.set(key, headers[key]));
}

const setResponse = (result, res) => {
  const { status, data, headers } = result;
  if (status !== 200 && status !== 410) {
    log.info(data);
  }
  setHeaders(headers, res);
  res.status(status);
  res.send(data);
};

module.exports = function run(config) {
  // Store config in app state. From now it can be loaded by any module using
  // getConfig():
  buildConfig(config);

  const { bundlePath, port } = getConfig();

  const app = express();

  // 10 MB limit for code including props
  const fieldSizeLimit = 1024 * 1024 * 10;

  busBoy.extend(app, {
    upload: true,
    path: path.join(bundlePath, 'uploads'),
    limits: {
      fieldSize: fieldSizeLimit,
    },
  });

  //
  app.route('/bundles/:bundleTimestamp/render/:renderRequestDigest').post((req, res) => {
    // Check protocol version
    const protocolVersionCheckingResult = checkProtocolVersion(req);

    if (typeof protocolVersionCheckingResult === 'object') {
      setResponse(protocolVersionCheckingResult, res);
      return;
    }

    // Authenticate Ruby client
    const authResult = authenticate(req);

    if (typeof authResult === 'object') {
      setResponse(authResult, res);
      return;
    }

    const { renderingRequest } = req.body;
    const { bundleTimestamp } = req.params;
    const { bundle: providedNewBundle } = req.files;

    try {
      handleRenderRequest({ renderingRequest, bundleTimestamp, providedNewBundle })
        .then(result => {
          setResponse(result, res);
        })
        .catch(err => {
          const exceptionMessage = formatExceptionMessage(
            renderingRequest,
            err,
            'UNHANDLED error in handleRenderRequest',
          );
          log.error(exceptionMessage);
          errorReporter.notify(exceptionMessage);
          setResponse(errorResponseResult(exceptionMessage), res);
        });
    } catch (theErr) {
      const exceptionMessage = formatExceptionMessage(renderingRequest, theErr);
      log.error(`UNHANDLED TOP LEVEL error ${exceptionMessage}`);
      errorReporter.notify(exceptionMessage);
      setResponse(errorResponseResult(exceptionMessage), res);
    }
  });

  app.get('/info', (_req, res) => {
    res.send({
      node_version: process.version,
      renderer_version: packageJson.version,
    });
  });

  // In tests we will run worker in master thread, so we need to ensure server
  // will not listen:
  if (!cluster.isMaster) {
    app.listen(port, () => {
      log.info(`Node renderer worker #${cluster.worker.id} listening on port ${port}!`);
    });
  }

  return app;
};
