/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

import path from 'path';
import cluster from 'cluster';
import fastify from 'fastify';
import fastifyFormbody from '@fastify/formbody';
import fastifyMultipart from '@fastify/multipart';
import log from './shared/log';
import packageJson from './shared/packageJson';
import { buildConfig, Config, getConfig } from './shared/configBuilder';
import fileExistsAsync from './shared/fileExistsAsync';
import type { FastifyReply, FastifyRequest } from './worker/types';
import checkProtocolVersion from './worker/checkProtocolVersionHandler';
import authenticate from './worker/authHandler';
import handleRenderRequest from './worker/handleRenderRequest';
import {
  errorResponseResult,
  formatExceptionMessage,
  moveUploadedAssets,
  ResponseResult,
  workerIdLabel,
  saveMultipartFile,
  Asset,
} from './shared/utils';
import errorReporter from './shared/errorReporter';
import tracing from './shared/tracing';
import { lock, unlock } from './shared/locks';

// Uncomment next 2 functions for testing timeouts
// function sleep(ms) {
//   return new Promise((resolve) => {
//     setTimeout(resolve, ms);
//   });
// }
//
// function getRandomInt(max) {
//   return Math.floor(Math.random() * Math.floor(max));
// }

declare module '@fastify/multipart' {
  interface MultipartFile {
    // We save all uploaded files and store this value
    value: Asset;
  }
}

function setHeaders(headers: ResponseResult['headers'], res: FastifyReply) {
  // eslint-disable-next-line @typescript-eslint/no-misused-promises -- fixing it with `void` just violates no-void
  Object.entries(headers).forEach(([key, header]) => res.header(key, header));
}

const setResponse = async (result: ResponseResult, res: FastifyReply) => {
  const { status, data, headers, stream } = result;
  if (status !== 200 && status !== 410) {
    log.info(`Sending non-200, non-410 data back: ${typeof data === 'string' ? data : JSON.stringify(data)}`);
  }
  setHeaders(headers, res);
  res.status(status);
  if (stream) {
    await res.send(stream);
  } else {
    res.send(data);
  }
};

const isAsset = (value: unknown): value is Asset => (value as { type?: string }).type === 'asset';

// Remove after this issue is resolved: https://github.com/fastify/light-my-request/issues/315
let useHttp2 = true;

// Call before any test using `app.inject()`
export const disableHttp2 = () => {
  useHttp2 = false;
};

export default function run(config: Partial<Config>) {
  // Store config in app state. From now it can be loaded by any module using
  // getConfig():
  buildConfig(config);

  const { bundlePath, logLevel, port } = getConfig();

  const app = fastify({
    http2: useHttp2 as true,
    logger: logLevel === 'debug',
  });

  // 10 MB limit for code including props
  const fieldSizeLimit = 1024 * 1024 * 10;

  // Supports application/x-www-form-urlencoded
  void app.register(fastifyFormbody);
  // Supports multipart/form-data
  void app.register(fastifyMultipart, {
    attachFieldsToBody: 'keyValues',
    limits: {
      fieldSize: fieldSizeLimit,
      fileSize: fieldSizeLimit,
    },
    onFile: async (part) => {
      const destinationPath = path.join(bundlePath, 'uploads', part.filename);
      // TODO: inline here
      await saveMultipartFile(part, destinationPath);
      // eslint-disable-next-line no-param-reassign
      part.value = {
        filename: part.filename,
        savedFilePath: destinationPath,
        type: 'asset',
      };
    },
  });

  const isProtocolVersionMatch = async (req: FastifyRequest, res: FastifyReply) => {
    // Check protocol version
    const protocolVersionCheckingResult = checkProtocolVersion(req);

    if (typeof protocolVersionCheckingResult === 'object') {
      await setResponse(protocolVersionCheckingResult, res);
      return false;
    }

    return true;
  };

  const isAuthenticated = async (req: FastifyRequest, res: FastifyReply) => {
    // Authenticate Ruby client
    const authResult = authenticate(req);

    if (typeof authResult === 'object') {
      await setResponse(authResult, res);
      return false;
    }

    return true;
  };

  const requestPrechecks = async (req: FastifyRequest, res: FastifyReply) => {
    if (!(await isProtocolVersionMatch(req, res))) {
      return false;
    }

    if (!(await isAuthenticated(req, res))) {
      return false;
    }

    return true;
  };

  // See https://github.com/shakacode/react_on_rails_pro/issues/119 for why
  // the digest is part of the request URL. Yes, it's not used here, but the
  // server logs might show it to distinguish different requests.
  app.post<{
    Body: { renderingRequest: string } & Record<string, Asset>;
    // Can't infer from the route like Express can
    Params: { bundleTimestamp: string; renderRequestDigest: string };
  }>('/bundles/:bundleTimestamp/render/:renderRequestDigest', async (req, res) => {
    if (!(await requestPrechecks(req, res))) {
      return;
    }

    // DO NOT REMOVE (REQUIRED FOR TIMEOUT TESTING)
    // if(TESTING_TIMEOUTS && getRandomInt(2) === 1) {
    //   console.log(
    //     'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ');
    //   console.log(`Sleeping, to test timeouts`);
    //   console.log(
    //     'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ');
    //
    //   await sleep(100000);
    // }

    const { renderingRequest } = req.body;
    const { bundleTimestamp } = req.params;
    let providedNewBundle: Asset | undefined;
    const assetsToCopy: Asset[] = [];
    Object.entries(req.body).forEach(([key, value]) => {
      if (key === 'bundle') {
        providedNewBundle = value as Asset;
      } else if (isAsset(value)) {
        assetsToCopy.push(value);
      }
    });

    try {
      await tracing.withinTransaction(
        async (transaction) => {
          try {
            const result = await handleRenderRequest({
              renderingRequest,
              bundleTimestamp,
              providedNewBundle,
              assetsToCopy,
            });
            await setResponse(result, res);
          } catch (err) {
            const exceptionMessage = formatExceptionMessage(
              renderingRequest,
              err,
              'UNHANDLED error in handleRenderRequest',
            );
            log.error(exceptionMessage);
            errorReporter.notify(exceptionMessage, {}, (scope) => {
              if (transaction) {
                scope.setSpan(transaction);
              }
              return scope;
            });
            await setResponse(errorResponseResult(exceptionMessage), res);
          }
        },
        'handleRenderRequest',
        'SSR Request',
      );
    } catch (theErr) {
      const exceptionMessage = formatExceptionMessage(renderingRequest, theErr);
      log.error(`UNHANDLED TOP LEVEL error ${exceptionMessage}`);
      errorReporter.notify(exceptionMessage);
      await setResponse(errorResponseResult(exceptionMessage), res);
    }
  });

  // There can be additional files that might be required at the runtime.
  // Since the remote renderer doesn't contain any assets, they must be uploaded manually.
  app.post<{
    Body: Record<string, Asset>;
  }>('/upload-assets', async (req, res) => {
    if (!(await requestPrechecks(req, res))) {
      return;
    }
    let lockAcquired = false;
    let lockfileName: string | undefined;
    const assets: Asset[] = Object.values(req.body).filter(isAsset);
    const assetsDescription = JSON.stringify(assets.map((asset) => asset.filename));
    const taskDescription = `Uploading files ${assetsDescription} to ${bundlePath}`;
    try {
      const { lockfileName: name, wasLockAcquired, errorMessage } = await lock('transferring-assets');
      lockfileName = name;
      lockAcquired = wasLockAcquired;

      if (!wasLockAcquired) {
        const msg = formatExceptionMessage(
          taskDescription,
          errorMessage,
          `Failed to acquire lock ${lockfileName}. Worker: ${workerIdLabel()}.`,
        );
        await setResponse(errorResponseResult(msg), res);
      } else {
        log.info(taskDescription);
        try {
          await moveUploadedAssets(assets);
          await setResponse(
            {
              status: 200,
              headers: {},
            },
            res,
          );
        } catch (err) {
          const message = `ERROR when trying to copy assets. ${err}. Task: ${taskDescription}`;
          log.info(message);
          await setResponse(errorResponseResult(message), res);
        }
      }
    } finally {
      if (lockAcquired) {
        try {
          if (lockfileName) {
            await unlock(lockfileName);
          }
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
  });

  // Checks if file exist
  app.post<{
    Querystring: { filename: string };
  }>('/asset-exists', async (req, res) => {
    if (!(await isAuthenticated(req, res))) {
      return;
    }

    const { filename } = req.query;

    if (!filename) {
      const message = `ERROR: filename param not provided to GET /asset-exists`;
      log.info(message);
      await setResponse(errorResponseResult(message), res);
      return;
    }

    const assetPath = path.join(bundlePath, filename);

    const fileExists = await fileExistsAsync(assetPath);

    if (fileExists) {
      log.info(`/asset-exists Uploaded asset DOES exist: ${assetPath}`);
      await setResponse({ status: 200, data: { exists: true }, headers: {} }, res);
    } else {
      log.info(`/asset-exists Uploaded asset DOES NOT exist: ${assetPath}`);
      await setResponse({ status: 200, data: { exists: false }, headers: {} }, res);
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
  // we are extracting worker from cluster to avoid false TS error
  const { worker } = cluster;
  if (cluster.isWorker && worker !== undefined) {
    app.listen({ port }, () => {
      log.info(`Node renderer worker #${worker.id} listening on port ${port}!`);
    });
  }

  return app;
}
