/**
 * Entry point for worker process that handles requests.
 * @module worker
 */

import path from 'path';
import cluster from 'cluster';
import { mkdir } from 'fs/promises';
import fastify from 'fastify';
import fastifyFormbody from '@fastify/formbody';
import fastifyMultipart from '@fastify/multipart';
import log, { sharedLoggerOptions } from './shared/log.js';
import packageJson from './shared/packageJson.js';
import { buildConfig, Config, getConfig } from './shared/configBuilder.js';
import fileExistsAsync from './shared/fileExistsAsync.js';
import type { FastifyInstance, FastifyReply, FastifyRequest } from './worker/types.js';
import checkProtocolVersion from './worker/checkProtocolVersionHandler.js';
import authenticate from './worker/authHandler.js';
import { handleRenderRequest, type ProvidedNewBundle } from './worker/handleRenderRequest.js';
import handleGracefulShutdown from './worker/handleGracefulShutdown.js';
import {
  handleIncrementalRenderRequest,
  type IncrementalRenderInitialRequest,
} from './worker/handleIncrementalRenderRequest.js';
import { handleIncrementalRenderStream } from './worker/handleIncrementalRenderStream.js';
import {
  errorResponseResult,
  formatExceptionMessage,
  copyUploadedAssets,
  ResponseResult,
  workerIdLabel,
  saveMultipartFile,
  Asset,
  getAssetPath,
  getBundleDirectory,
  deleteUploadedAssets,
  validateBundlesExist,
} from './shared/utils.js';
import * as errorReporter from './shared/errorReporter.js';
import { lock, unlock } from './shared/locks.js';
import { startSsrRequestOptions, trace } from './shared/tracing.js';

// Uncomment the below for testing timeouts:
// import { delay } from './shared/utils.js';
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

export type FastifyConfigFunction = (app: FastifyInstance) => void;

const fastifyConfigFunctions: FastifyConfigFunction[] = [];

/**
 * Configures Fastify instance before starting the server.
 * @param configFunction The configuring function. Normally it will be something like `(app) => { app.register(...); }`
 *  or `(app) => { app.addHook(...); }` to report data from Fastify to an external service.
 *  Note that we call `await app.ready()` in our code, so you don't need to `await` the results.
 */
export function configureFastify(configFunction: FastifyConfigFunction) {
  fastifyConfigFunctions.push(configFunction);
}

function setHeaders(headers: ResponseResult['headers'], res: FastifyReply) {
  // eslint-disable-next-line @typescript-eslint/no-misused-promises -- fixing it with `void` just violates no-void
  Object.entries(headers).forEach(([key, header]) => res.header(key, header));
}

const setResponse = async (result: ResponseResult, res: FastifyReply) => {
  const { status, data, headers, stream } = result;
  if (status !== 200 && status !== 410) {
    log.info({ msg: 'Sending non-200, non-410 data back', data });
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

function assertAsset(value: unknown, key: string): asserts value is Asset {
  if (!isAsset(value)) {
    throw new Error(`React On Rails Error: Expected an asset for key: ${key}`);
  }
}

// Remove after this issue is resolved: https://github.com/fastify/light-my-request/issues/315
let useHttp2 = true;

// Call before any test using `app.inject()`
export const disableHttp2 = () => {
  useHttp2 = false;
};

type WithBodyArrayField<T, K extends string> = T & { [P in K | `${K}[]`]?: string | string[] };

const extractBodyArrayField = <Key extends string>(
  body: WithBodyArrayField<Record<string, unknown>, Key>,
  key: Key,
): string[] | undefined => {
  const value = body[key] ?? body[`${key}[]`];
  if (Array.isArray(value)) {
    return value;
  }
  if (typeof value === 'string' && value.length > 0) {
    return [value];
  }
  return undefined;
};

export default function run(config: Partial<Config>) {
  // Store config in app state. From now it can be loaded by any module using
  // getConfig():
  buildConfig(config);

  const { serverBundleCachePath, logHttpLevel, port, fastifyServerOptions, workersCount } = getConfig();

  const app = fastify({
    http2: useHttp2 as true,
    bodyLimit: 104857600, // 100 MB
    logger:
      logHttpLevel !== 'silent' ? { name: 'RORP HTTP', level: logHttpLevel, ...sharedLoggerOptions } : false,
    ...fastifyServerOptions,
  });

  handleGracefulShutdown(app);

  // We shouldn't have unhandled errors here, but just in case
  app.addHook('onError', (req, res, err, done) => {
    // Not errorReporter.error so that integrations can decide how to log the errors.
    app.log.error({ msg: 'Unhandled Fastify error', err, req, res });
    done();
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
      // For bundles and assets
      fileSize: Infinity,
    },
    onFile: async (part) => {
      const destinationPath = path.join(serverBundleCachePath, 'uploads', part.filename);
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

  // Ensure NDJSON bodies are not buffered and are available as a stream immediately
  app.addContentTypeParser('application/x-ndjson', (req, payload, done) => {
    // Pass through the raw stream; the route will consume req.raw
    done(null, payload);
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
    Body: WithBodyArrayField<
      {
        renderingRequest: string;
      },
      'dependencyBundleTimestamps'
    >;
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
    //   await delay(100000);
    // }

    const { renderingRequest } = req.body;
    const { bundleTimestamp } = req.params;
    const providedNewBundles: ProvidedNewBundle[] = [];
    const assetsToCopy: Asset[] = [];
    Object.entries(req.body).forEach(([key, value]) => {
      if (key === 'bundle') {
        assertAsset(value, key);
        providedNewBundles.push({ timestamp: bundleTimestamp, bundle: value });
      } else if (key.startsWith('bundle_')) {
        assertAsset(value, key);
        providedNewBundles.push({ timestamp: key.replace('bundle_', ''), bundle: value });
      } else if (isAsset(value)) {
        assetsToCopy.push(value);
      }
    });

    try {
      const dependencyBundleTimestamps = extractBodyArrayField(req.body, 'dependencyBundleTimestamps');
      await trace(async (context) => {
        try {
          const result = await handleRenderRequest({
            renderingRequest,
            bundleTimestamp,
            dependencyBundleTimestamps,
            providedNewBundles,
            assetsToCopy,
          });
          await setResponse(result, res);
        } catch (err) {
          const exceptionMessage = formatExceptionMessage(
            renderingRequest,
            err,
            'UNHANDLED error in handleRenderRequest',
          );
          errorReporter.message(exceptionMessage, context);
          await setResponse(errorResponseResult(exceptionMessage), res);
        }
      }, startSsrRequestOptions({ renderingRequest }));
    } catch (theErr) {
      const exceptionMessage = formatExceptionMessage(renderingRequest, theErr);
      errorReporter.message(`Unhandled top level error: ${exceptionMessage}`);
      await setResponse(errorResponseResult(exceptionMessage), res);
    }
  });

  // Streaming NDJSON incremental render endpoint
  app.post<{
    Params: { bundleTimestamp: string; renderRequestDigest: string };
  }>('/bundles/:bundleTimestamp/incremental-render/:renderRequestDigest', async (req, res) => {
    const { bundleTimestamp } = req.params;

    // Perform protocol + auth checks as early as possible. For protocol check,
    // we need the first NDJSON object; thus defer protocol/auth until first chunk is parsed.
    // Headers and status will be set after validation passes to avoid premature 200 status.

    // Stream parser state
    let renderResult: Awaited<ReturnType<typeof handleIncrementalRenderRequest>> | null = null;

    try {
      // Handle the incremental render stream
      await handleIncrementalRenderStream({
        request: req,
        onRenderRequestReceived: async (obj: unknown) => {
          // Build a temporary FastifyRequest shape for protocol/auth check
          const tempReqBody = typeof obj === 'object' && obj !== null ? (obj as Record<string, unknown>) : {};

          // Protocol check
          const protoResult = checkProtocolVersion({ ...req, body: tempReqBody } as unknown as FastifyRequest);
          if (typeof protoResult === 'object') {
            return {
              response: protoResult,
              shouldContinue: false,
            };
          }

          // Auth check
          const authResult = authenticate({ ...req, body: tempReqBody } as unknown as FastifyRequest);
          if (typeof authResult === 'object') {
            return {
              response: authResult,
              shouldContinue: false,
            };
          }

          // Bundle validation
          const dependencyBundleTimestamps = extractBodyArrayField(
            tempReqBody as WithBodyArrayField<Record<string, unknown>, 'dependencyBundleTimestamps'>,
            'dependencyBundleTimestamps',
          );
          const missingBundleError = await validateBundlesExist(bundleTimestamp, dependencyBundleTimestamps);
          if (missingBundleError) {
            return {
              response: missingBundleError,
              shouldContinue: false,
            };
          }

          // All validation passed - get response stream
          const initial: IncrementalRenderInitialRequest = {
            renderingRequest: String((tempReqBody as { renderingRequest?: string }).renderingRequest ?? ''),
            bundleTimestamp,
            dependencyBundleTimestamps,
          };

          try {
            renderResult = await handleIncrementalRenderRequest(initial);
            return {
              response: renderResult.response,
              shouldContinue: true,
            };
          } catch (err) {
            const errorResponse = errorResponseResult(
              formatExceptionMessage(
                'IncrementalRender',
                err,
                'Error while handling incremental render request',
              ),
            );
            return {
              response: errorResponse,
              shouldContinue: false,
            };
          }
        },

        onUpdateReceived: (obj: unknown) => {
          // Only process updates if we have a render result
          if (!renderResult) {
            return undefined;
          }

          try {
            renderResult.sink.add(obj);
          } catch (err) {
            // Log error but don't stop processing
            log.error({ err, msg: 'Error processing update chunk' });
          }
          return undefined;
        },

        onResponseStart: async (response: ResponseResult) => {
          await setResponse(response, res);
        },

        onRequestEnded: () => {
          try {
            if (renderResult) {
              renderResult.sink.end();
            }
          } catch (err) {
            log.error({ err, msg: 'Error ending render sink' });
          }
          return undefined;
        },
      });
    } catch (err) {
      // If an error occurred during stream processing, send error response
      const errorResponse = errorResponseResult(
        formatExceptionMessage('IncrementalRender', err, 'Error while processing incremental render stream'),
      );
      await setResponse(errorResponse, res);
    }
  });

  // There can be additional files that might be required at the runtime.
  // Since the remote renderer doesn't contain any assets, they must be uploaded manually.
  app.post<{
    Body: WithBodyArrayField<Record<string, Asset>, 'targetBundles'>;
  }>('/upload-assets', async (req, res) => {
    if (!(await requestPrechecks(req, res))) {
      return;
    }
    let lockAcquired = false;
    let lockfileName: string | undefined;
    const assets: Asset[] = Object.values(req.body).filter(isAsset);

    // Handle targetBundles as either a string or an array
    const targetBundles = extractBodyArrayField(req.body, 'targetBundles');
    if (!targetBundles || targetBundles.length === 0) {
      const errorMsg = 'No targetBundles provided. As of protocol version 2.0.0, targetBundles is required.';
      log.error(errorMsg);
      await setResponse(errorResponseResult(errorMsg), res);
      return;
    }

    const assetsDescription = JSON.stringify(assets.map((asset) => asset.filename));
    const taskDescription = `Uploading files ${assetsDescription} to bundle directories: ${targetBundles.join(', ')}`;

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
          // Prepare all directories first
          const directoryPromises = targetBundles.map(async (bundleTimestamp) => {
            const bundleDirectory = getBundleDirectory(bundleTimestamp);

            // Check if bundle directory exists, create if not
            if (!(await fileExistsAsync(bundleDirectory))) {
              log.info(`Creating bundle directory: ${bundleDirectory}`);
              await mkdir(bundleDirectory, { recursive: true });
            }
            return bundleDirectory;
          });

          const bundleDirectories = await Promise.all(directoryPromises);

          // Copy assets to each bundle directory
          const assetCopyPromises = bundleDirectories.map(async (bundleDirectory) => {
            await copyUploadedAssets(assets, bundleDirectory);
            log.info(`Copied assets to bundle directory: ${bundleDirectory}`);
          });

          await Promise.all(assetCopyPromises);

          // Delete assets from uploads directory
          await deleteUploadedAssets(assets);

          await setResponse(
            {
              status: 200,
              headers: {},
            },
            res,
          );
        } catch (err) {
          const msg = 'ERROR when trying to copy assets';
          const message = `${msg}. ${err}. Task: ${taskDescription}`;
          log.error({
            msg,
            err,
            task: taskDescription,
          });
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
          log.warn({
            msg: `Error unlocking ${lockfileName} from worker ${workerIdLabel()}`,
            err: error,
            task: taskDescription,
          });
        }
      }
    }
  });

  // Checks if file exist
  app.post<{
    Querystring: { filename: string };
    Body: WithBodyArrayField<Record<string, unknown>, 'targetBundles'>;
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

    // Handle targetBundles as either a string or an array
    const targetBundles = extractBodyArrayField(req.body, 'targetBundles');
    if (!targetBundles || targetBundles.length === 0) {
      const errorMsg = 'No targetBundles provided. As of protocol version 2.0.0, targetBundles is required.';
      log.error(errorMsg);
      await setResponse(errorResponseResult(errorMsg), res);
      return;
    }

    // Check if the asset exists in each of the target bundles
    const results = await Promise.all(
      targetBundles.map(async (bundleHash) => {
        const assetPath = getAssetPath(bundleHash, filename);
        const exists = await fileExistsAsync(assetPath);

        if (exists) {
          log.info(`/asset-exists Uploaded asset DOES exist in bundle ${bundleHash}: ${assetPath}`);
        } else {
          log.info(`/asset-exists Uploaded asset DOES NOT exist in bundle ${bundleHash}: ${assetPath}`);
        }

        return { bundleHash, exists };
      }),
    );

    // Asset exists if it exists in all target bundles
    const allExist = results.every((result) => result.exists);

    await setResponse({ status: 200, data: { exists: allExist, results }, headers: {} }, res);
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
  if (workersCount === 0 || cluster.isWorker) {
    app.listen({ port }, () => {
      const workerName = worker ? `worker #${worker.id}` : 'master (single-process)';
      log.info(`Node renderer ${workerName} listening on port ${port}!`);
    });
  }

  fastifyConfigFunctions.forEach((configFunction) => {
    configFunction(app);
  });

  return app;
}
