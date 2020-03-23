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
const asyncHandler = require('./shared/expressAsyncHandler');
const fileExistsAsync = require('./shared/fileExistsAsync');

const checkProtocolVersion = require('./worker/checkProtocolVersionHandler');
const authenticate = require('./worker/authHandler');
const handleRenderRequest = require('./worker/handleRenderRequest');
const {
  errorResponseResult,
  formatExceptionMessage,
  workerIdLabel,
  moveUploadedAssets,
} = require('./shared/utils');
const errorReporter = require('./shared/errorReporter');
const { lock, unlock } = require('./shared/locks');

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

  const isProtocolVersionMatch = (req, res) => {
    // Check protocol version
    const protocolVersionCheckingResult = checkProtocolVersion(req);

    if (typeof protocolVersionCheckingResult === 'object') {
      setResponse(protocolVersionCheckingResult, res);
      return false;
    }

    return true;
  };

  const isAuthenticated = (req, res) => {
    // Authenticate Ruby client
    const authResult = authenticate(req);

    if (typeof authResult === 'object') {
      setResponse(authResult, res);
      return false;
    }

    return true;
  };

  const requestPrechecks = (req, res) => {
    if (!isProtocolVersionMatch(req, res)) {
      return false;
    }

    if (!isAuthenticated(req, res)) {
      return false;
    }

    return true;
  };

  //
  app.route('/bundles/:bundleTimestamp/render/:renderRequestDigest').post(
    asyncHandler(async (req, res, _next) => {
      if (!requestPrechecks(req, res)) {
        return;
      }

      const { renderingRequest } = req.body;
      const { bundleTimestamp } = req.params;
      const { bundle: providedNewBundle, ...assetsToCopyObj } = req.files;

      try {
        const assetsToCopy = Object.values(assetsToCopyObj);
        handleRenderRequest({ renderingRequest, bundleTimestamp, providedNewBundle, assetsToCopy })
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
    }),
  );

  // There can be additional files that might be required
  // in the runtime. Since remote renderer doesn't contain
  // any assets, they must be uploaded manually.
  app.route('/upload-assets').post(
    asyncHandler(async (req, res, _next) => {
      if (!requestPrechecks(req, res)) {
        return;
      }
      let lockAcquired;
      let lockfileName;
      const assets = Object.values(req.files);
      const assetsDescription = JSON.stringify(assets.map(asset => asset.filename));
      const taskDescription = `Uploading files ${assetsDescription} to ${bundlePath}`;
      try {
        const { lockfileName: name, wasLockAcquired, errorMessage } = await lock('transferring-assets');
        lockfileName = name;
        lockAcquired = wasLockAcquired;

        if (!lockAcquired) {
          const msg = formatExceptionMessage(
            taskDescription,
            errorMessage,
            `Failed to acquire lock ${lockfileName}. Worker: ${workerIdLabel()}.`,
          );
          setResponse(errorResponseResult(msg), res);
        } else {
          log.info(taskDescription);
          try {
            await moveUploadedAssets(assets);
            setResponse(
              {
                status: 200,
                headers: {},
              },
              res,
            );
          } catch (err) {
            const message = `ERROR when trying to copy assets. ${err}. Task: ${taskDescription}`;
            log.info(message);
            setResponse(errorResponseResult(message), res);
          }
        }
      } finally {
        if (lockAcquired) {
          try {
            await unlock(lockfileName);
          } catch (error) {
            const msg = formatExceptionMessage(
              taskDescription,
              error,
              `Error unlocking ${lockfileName} from worker ${workerIdLabel()}.`,
            );
            log.warn(msg);
          }
        }
      }
    }),
  );

  // Checks if file exist
  app.route('/asset-exists').post(
    asyncHandler(async (req, res, _next) => {
      if (!isAuthenticated(req, res)) {
        return;
      }

      const { filename } = req.query;

      if (!filename) {
        const message = `ERROR: filename param not provided to GET /asset-exists`;
        log.info(message);
        setResponse(errorResponseResult(message), res);
        return;
      }

      const assetPath = path.join(bundlePath, filename);

      const fileExists = await fileExistsAsync(assetPath);

      if (fileExists) {
        log.info(`/asset-exists Uploaded asset DOES exist: ${assetPath}`);
        setResponse({ status: 200, data: { exists: true }, headers: {} }, res);
      } else {
        log.info(`/asset-exists Uploaded asset DOES NOT exist: ${assetPath}`);
        setResponse({ status: 200, data: { exists: false }, headers: {} }, res);
      }
    }),
  );

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
