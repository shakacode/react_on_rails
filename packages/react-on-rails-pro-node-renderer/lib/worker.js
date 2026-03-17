"use strict";
/**
 * Entry point for worker process that handles requests.
 * @module worker
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.disableHttp2 = void 0;
exports.configureFastify = configureFastify;
exports.default = run;
const path_1 = __importDefault(require("path"));
const cluster_1 = __importDefault(require("cluster"));
const crypto_1 = require("crypto");
const promises_1 = require("fs/promises");
const fastify_1 = __importDefault(require("fastify"));
const formbody_1 = __importDefault(require("@fastify/formbody"));
const multipart_1 = __importDefault(require("@fastify/multipart"));
const log_js_1 = __importStar(require("./shared/log.js"));
const packageJson_js_1 = __importDefault(require("./shared/packageJson.js"));
const configBuilder_js_1 = require("./shared/configBuilder.js");
const fileExistsAsync_js_1 = __importDefault(require("./shared/fileExistsAsync.js"));
const requestPrechecks_js_1 = require("./worker/requestPrechecks.js");
const authHandler_js_1 = require("./worker/authHandler.js");
const handleRenderRequest_js_1 = require("./worker/handleRenderRequest.js");
const handleGracefulShutdown_js_1 = __importDefault(require("./worker/handleGracefulShutdown.js"));
const handleIncrementalRenderRequest_js_1 = require("./worker/handleIncrementalRenderRequest.js");
const handleIncrementalRenderStream_js_1 = require("./worker/handleIncrementalRenderStream.js");
const constants_js_1 = require("./shared/constants.js");
const utils_js_1 = require("./shared/utils.js");
const errorReporter = __importStar(require("./shared/errorReporter.js"));
const locks_js_1 = require("./shared/locks.js");
const tracing_js_1 = require("./shared/tracing.js");
const fastifyConfigFunctions = [];
/**
 * Configures Fastify instance before starting the server.
 * @param configFunction The configuring function. Normally it will be something like `(app) => { app.register(...); }`
 *  or `(app) => { app.addHook(...); }` to report data from Fastify to an external service.
 *  Note that we call `await app.ready()` in our code, so you don't need to `await` the results.
 */
function configureFastify(configFunction) {
    fastifyConfigFunctions.push(configFunction);
}
function setHeaders(headers, res) {
    // eslint-disable-next-line @typescript-eslint/no-misused-promises -- fixing it with `void` just violates no-void
    Object.entries(headers).forEach(([key, header]) => res.header(key, header));
}
const setResponse = async (result, res) => {
    const { status, data, headers, stream } = result;
    if (status !== 200 && status !== 410) {
        log_js_1.default.info({ msg: 'Sending non-200, non-410 data back', data });
    }
    setHeaders(headers, res);
    res.status(status);
    if (stream) {
        await res.send(stream);
    }
    else {
        res.send(data);
    }
};
const isAsset = (value) => value.type === 'asset';
function assertAsset(value, key) {
    if (!isAsset(value)) {
        throw new Error(`React On Rails Error: Expected an asset for key: ${key}`);
    }
}
// Remove after this issue is resolved: https://github.com/fastify/light-my-request/issues/315
let useHttp2 = true;
// Call before any test using `app.inject()`
const disableHttp2 = () => {
    useHttp2 = false;
};
exports.disableHttp2 = disableHttp2;
const extractBodyArrayField = (body, key) => {
    const value = body[key] ?? body[`${key}[]`];
    if (Array.isArray(value)) {
        return value;
    }
    if (typeof value === 'string' && value.length > 0) {
        return [value];
    }
    return undefined;
};
function run(config) {
    // Store config in app state. From now it can be loaded by any module using
    // getConfig():
    (0, configBuilder_js_1.buildConfig)(config);
    const { serverBundleCachePath, logHttpLevel, port, fastifyServerOptions, workersCount } = (0, configBuilder_js_1.getConfig)();
    const app = (0, fastify_1.default)({
        http2: useHttp2,
        bodyLimit: constants_js_1.BODY_SIZE_LIMIT,
        logger: logHttpLevel !== 'silent' ? { name: 'RORP HTTP', level: logHttpLevel, ...log_js_1.sharedLoggerOptions } : false,
        ...fastifyServerOptions,
    });
    (0, handleGracefulShutdown_js_1.default)(app);
    // We shouldn't have unhandled errors here, but just in case
    app.addHook('onError', (req, res, err, done) => {
        // Not errorReporter.error so that integrations can decide how to log the errors.
        app.log.error({ msg: 'Unhandled Fastify error', err, req, res });
        done();
    });
    // Each request gets its own upload directory to prevent concurrent requests
    // from overwriting each other's files (GitHub issue #2449).
    // The directory path is lazily assigned in onFile (only for requests with file uploads).
    app.decorateRequest('uploadDir', '');
    // Clean up the per-request upload directory after the response is sent.
    // Safe from a rate-limiting perspective (CodeQL js/missing-rate-limiting):
    // this is an internal service not exposed to the internet, the path is
    // server-generated (uploads/<UUID>), and the hook only runs rm when files
    // were actually uploaded (uploadDir is non-empty).
    app.addHook('onResponse', async (req) => {
        if (req.uploadDir) {
            await (0, promises_1.rm)(req.uploadDir, { recursive: true, force: true }).catch((err) => {
                log_js_1.default.warn({ msg: 'Failed to clean up per-request upload directory', uploadDir: req.uploadDir, err });
            });
        }
    });
    // Supports application/x-www-form-urlencoded
    void app.register(formbody_1.default);
    // Supports multipart/form-data
    void app.register(multipart_1.default, {
        attachFieldsToBody: 'keyValues',
        limits: {
            fieldSize: constants_js_1.FIELD_SIZE_LIMIT,
            // For bundles and assets
            fileSize: Infinity,
        },
        // Use regular function (not arrow) because @fastify/multipart binds `this`
        // to the Fastify request in attachFieldsToBody mode.
        // Note: do NOT annotate `this` with the local Http2Server-typed FastifyRequest;
        // the plugin types expect the default (RawServerDefault) FastifyRequest.
        async onFile(part) {
            if (typeof this?.uploadDir !== 'string') {
                throw new Error('onFile: expected `this` to be bound to the Fastify request');
            }
            // Lazily assign a per-request upload directory on first file upload
            if (this.uploadDir === '') {
                this.uploadDir = path_1.default.join(serverBundleCachePath, 'uploads', (0, crypto_1.randomUUID)());
            }
            // Use path.basename to strip any directory components from the filename,
            // preventing path traversal attacks (e.g. filename "../../etc/shadow").
            const safeFilename = path_1.default.basename(part.filename);
            if (!safeFilename) {
                throw new Error(`onFile: received file with empty or invalid filename: ${JSON.stringify(part.filename)}`);
            }
            const destinationPath = path_1.default.join(this.uploadDir, safeFilename);
            await (0, utils_js_1.saveMultipartFile)(part, destinationPath);
            // eslint-disable-next-line no-param-reassign
            part.value = {
                filename: safeFilename,
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
    // See https://github.com/shakacode/react_on_rails_pro/issues/119 for why
    // the digest is part of the request URL. Yes, it's not used here, but the
    // server logs might show it to distinguish different requests.
    app.post('/bundles/:bundleTimestamp/render/:renderRequestDigest', async (req, res) => {
        const precheckResult = (0, requestPrechecks_js_1.performRequestPrechecks)(req.body);
        if (precheckResult) {
            await setResponse(precheckResult, res);
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
        const providedNewBundles = [];
        const assetsToCopy = [];
        Object.entries(req.body).forEach(([key, value]) => {
            if (key === 'bundle') {
                assertAsset(value, key);
                providedNewBundles.push({ timestamp: bundleTimestamp, bundle: value });
            }
            else if (key.startsWith('bundle_')) {
                assertAsset(value, key);
                providedNewBundles.push({ timestamp: key.replace('bundle_', ''), bundle: value });
            }
            else if (isAsset(value)) {
                assetsToCopy.push(value);
            }
        });
        try {
            const dependencyBundleTimestamps = extractBodyArrayField(req.body, 'dependencyBundleTimestamps');
            await (0, tracing_js_1.trace)(async (context) => {
                try {
                    const result = await (0, handleRenderRequest_js_1.handleRenderRequest)({
                        renderingRequest,
                        bundleTimestamp,
                        dependencyBundleTimestamps,
                        providedNewBundles,
                        assetsToCopy,
                    });
                    await setResponse(result.response, res);
                }
                catch (err) {
                    const exceptionMessage = (0, utils_js_1.formatExceptionMessage)(renderingRequest, err, 'UNHANDLED error in handleRenderRequest');
                    errorReporter.message(exceptionMessage, context);
                    await setResponse((0, utils_js_1.errorResponseResult)(exceptionMessage), res);
                }
            }, (0, tracing_js_1.startSsrRequestOptions)({ renderingRequest }));
        }
        catch (theErr) {
            const exceptionMessage = (0, utils_js_1.formatExceptionMessage)(renderingRequest, theErr);
            errorReporter.message(`Unhandled top level error: ${exceptionMessage}`);
            await setResponse((0, utils_js_1.errorResponseResult)(exceptionMessage), res);
        }
    });
    // Streaming NDJSON incremental render endpoint
    app.post('/bundles/:bundleTimestamp/incremental-render/:renderRequestDigest', async (req, res) => {
        const { bundleTimestamp } = req.params;
        // Stream parser state
        let incrementalSink;
        // Track whether we've already started sending a response (streaming or otherwise)
        // If true, we can't send an error response on failure - headers are already sent
        let responseStarted = false;
        try {
            // Handle the incremental render stream
            await (0, handleIncrementalRenderStream_js_1.handleIncrementalRenderStream)({
                request: req,
                onRenderRequestReceived: async (obj) => {
                    // Build a temporary FastifyRequest shape for protocol/auth check
                    const tempReqBody = typeof obj === 'object' && obj !== null ? obj : {};
                    // Perform request prechecks
                    const precheckResult = (0, requestPrechecks_js_1.performRequestPrechecks)(tempReqBody);
                    if (precheckResult) {
                        return {
                            response: precheckResult,
                            shouldContinue: false,
                        };
                    }
                    // Extract data for incremental render request
                    const dependencyBundleTimestamps = extractBodyArrayField(tempReqBody, 'dependencyBundleTimestamps');
                    const initial = {
                        firstRequestChunk: obj,
                        bundleTimestamp,
                        dependencyBundleTimestamps,
                    };
                    try {
                        const { response, sink } = await (0, handleIncrementalRenderRequest_js_1.handleIncrementalRenderRequest)(initial);
                        incrementalSink = sink;
                        return {
                            response,
                            shouldContinue: !!incrementalSink,
                        };
                    }
                    catch (err) {
                        const errorResponse = (0, utils_js_1.errorResponseResult)((0, utils_js_1.formatExceptionMessage)('IncrementalRender', err, 'Error while handling incremental render request'));
                        return {
                            response: errorResponse,
                            shouldContinue: false,
                        };
                    }
                },
                onUpdateReceived: async (obj) => {
                    if (!incrementalSink) {
                        log_js_1.default.error({ msg: 'Unexpected update chunk received after rendering was aborted', obj });
                        return;
                    }
                    try {
                        log_js_1.default.info(`Received a new update chunk ${JSON.stringify(obj)}`);
                        await incrementalSink.add(obj);
                    }
                    catch (err) {
                        // Log error but don't stop processing
                        log_js_1.default.error({ err, msg: 'Error processing update chunk' });
                    }
                },
                onResponseStart: async (response) => {
                    responseStarted = true;
                    await setResponse(response, res);
                },
                onRequestEnded: () => {
                    if (!incrementalSink) {
                        return;
                    }
                    incrementalSink.handleRequestClosed();
                },
            });
        }
        catch (err) {
            // If an error occurred during stream processing, send error response
            const errorMessage = (0, utils_js_1.formatExceptionMessage)('IncrementalRender', err, 'Error while processing incremental render stream');
            if (responseStarted) {
                // Response was already started (streaming), we can't send an error response.
                // This happens when the stream times out or errors after we've already started
                // sending the streaming response. Just log the error.
                log_js_1.default.error({
                    msg: 'Error occurred after response started, cannot send error response',
                    error: errorMessage,
                });
                // CRITICAL: We must call handleRequestClosed() to end the React stream.
                // The React stream is waiting for async props (e.g., asyncPropsManager.getProp("researches")).
                // If we don't call endStream(), the stream will hang forever waiting for props that will never arrive.
                // This causes onResponse to never fire, leaving activeRequestsCount stuck and preventing worker shutdown.
                if (incrementalSink) {
                    incrementalSink.handleRequestClosed();
                }
                // CRITICAL: Destroy the response connection to immediately close it.
                // Without this, the response stream stays open waiting for the client (httpx) to timeout,
                // which can take 30+ seconds. This delays worker shutdown during graceful termination.
                // Destroying the raw response immediately closes the connection and triggers onResponse.
                if (!res.raw.destroyed) {
                    res.raw.destroy();
                }
            }
            else {
                // Response hasn't started yet, we can send an error response
                const errorResponse = (0, utils_js_1.errorResponseResult)(errorMessage);
                await setResponse(errorResponse, res);
            }
        }
    });
    // There can be additional files that might be required at the runtime.
    // Since the remote renderer doesn't contain any assets, they must be uploaded manually.
    app.post('/upload-assets', async (req, res) => {
        const precheckResult = (0, requestPrechecks_js_1.performRequestPrechecks)(req.body);
        if (precheckResult) {
            await setResponse(precheckResult, res);
            return;
        }
        const assets = [];
        // Extract bundles that start with 'bundle_' prefix
        const bundles = [];
        Object.entries(req.body).forEach(([key, value]) => {
            if (isAsset(value)) {
                if (key.startsWith('bundle_')) {
                    const timestamp = key.replace('bundle_', '');
                    bundles.push({ timestamp, bundle: value });
                }
                else {
                    assets.push(value);
                }
            }
        });
        // Handle targetBundles as either a string or an array
        const targetBundles = extractBodyArrayField(req.body, 'targetBundles');
        if (!targetBundles || targetBundles.length === 0) {
            const errorMsg = 'No targetBundles provided. As of protocol version 2.0.0, targetBundles is required.';
            log_js_1.default.error(errorMsg);
            await setResponse((0, utils_js_1.errorResponseResult)(errorMsg), res);
            return;
        }
        const assetsDescription = JSON.stringify(assets.map((asset) => asset.filename));
        const bundlesDescription = bundles.length > 0 ? ` and bundles ${JSON.stringify(bundles.map((b) => b.bundle.filename))}` : '';
        const taskDescription = `Uploading files ${assetsDescription}${bundlesDescription} to bundle directories: ${targetBundles.join(', ')}`;
        log_js_1.default.info(taskDescription);
        try {
            // Use per-bundle locks (same lock key as handleRenderRequest) so that
            // asset copies and render-request bundle writes to the same directory
            // are mutually exclusive. See https://github.com/shakacode/react_on_rails/issues/2463
            //
            // Use allSettled (not Promise.all) to ensure every in-flight copy
            // finishes before the handler returns. Otherwise the onResponse hook
            // can delete req.uploadDir while background copies still read from it.
            const copyPromises = targetBundles.map(async (bundleTimestamp) => {
                const bundleDirectory = (0, utils_js_1.getBundleDirectory)(bundleTimestamp);
                await (0, promises_1.mkdir)(bundleDirectory, { recursive: true });
                const bundleFilePath = (0, utils_js_1.getRequestBundleFilePath)(bundleTimestamp);
                const { lockfileName, wasLockAcquired, errorMessage } = await (0, locks_js_1.lock)(bundleFilePath);
                if (!wasLockAcquired) {
                    const msg = (0, utils_js_1.formatExceptionMessage)(taskDescription, errorMessage, `Failed to acquire lock ${lockfileName}. Worker: ${(0, utils_js_1.workerIdLabel)()}.`);
                    throw new Error(msg);
                }
                try {
                    await (0, utils_js_1.copyUploadedAssets)(assets, bundleDirectory);
                    log_js_1.default.info(`Copied assets to bundle directory: ${bundleDirectory}`);
                }
                finally {
                    try {
                        await (0, locks_js_1.unlock)(lockfileName);
                    }
                    catch (error) {
                        log_js_1.default.warn({
                            msg: `Error unlocking ${lockfileName} from worker ${(0, utils_js_1.workerIdLabel)()}`,
                            err: error,
                            task: taskDescription,
                        });
                    }
                }
            });
            const results = await Promise.allSettled(copyPromises);
            const firstFailure = results.find((r) => r.status === 'rejected');
            if (firstFailure) {
                throw firstFailure.reason;
            }
            // Handle bundles using the existing logic from handleRenderRequest
            if (bundles.length > 0) {
                const providedNewBundles = bundles.map(({ timestamp, bundle }) => ({
                    timestamp,
                    bundle,
                }));
                // Use the existing bundle handling logic
                // Note: handleNewBundlesProvided will handle deleting the uploaded bundle files
                // Pass null for assetsToCopy since we handle assets separately in this endpoint
                const bundleResult = await (0, handleRenderRequest_js_1.handleNewBundlesProvided)('upload-assets', providedNewBundles, null);
                if (bundleResult) {
                    await setResponse(bundleResult, res);
                    return;
                }
            }
            await setResponse({
                status: 200,
                headers: {},
            }, res);
        }
        catch (err) {
            const msg = 'ERROR when trying to copy assets and bundles';
            const message = `${msg}. ${err}. Task: ${taskDescription}`;
            log_js_1.default.error({
                msg,
                err,
                task: taskDescription,
            });
            await setResponse((0, utils_js_1.errorResponseResult)(message), res);
        }
    });
    // Checks if file exist
    app.post('/asset-exists', async (req, res) => {
        const authResult = (0, authHandler_js_1.authenticate)(req.body);
        if (authResult) {
            await setResponse(authResult, res);
            return;
        }
        const { filename } = req.query;
        if (!filename) {
            const message = `ERROR: filename param not provided to GET /asset-exists`;
            log_js_1.default.info(message);
            await setResponse((0, utils_js_1.errorResponseResult)(message), res);
            return;
        }
        // Handle targetBundles as either a string or an array
        const targetBundles = extractBodyArrayField(req.body, 'targetBundles');
        if (!targetBundles || targetBundles.length === 0) {
            const errorMsg = 'No targetBundles provided. As of protocol version 2.0.0, targetBundles is required.';
            log_js_1.default.error(errorMsg);
            await setResponse((0, utils_js_1.errorResponseResult)(errorMsg), res);
            return;
        }
        // Check if the asset exists in each of the target bundles
        const results = await Promise.all(targetBundles.map(async (bundleHash) => {
            const assetPath = (0, utils_js_1.getAssetPath)(bundleHash, filename);
            const exists = await (0, fileExistsAsync_js_1.default)(assetPath);
            if (exists) {
                log_js_1.default.info(`/asset-exists Uploaded asset DOES exist in bundle ${bundleHash}: ${assetPath}`);
            }
            else {
                log_js_1.default.info(`/asset-exists Uploaded asset DOES NOT exist in bundle ${bundleHash}: ${assetPath}`);
            }
            return { bundleHash, exists };
        }));
        // Asset exists if it exists in all target bundles
        const allExist = results.every((result) => result.exists);
        await setResponse({ status: 200, data: { exists: allExist, results }, headers: {} }, res);
    });
    app.get('/info', (_req, res) => {
        res.send({
            node_version: process.version,
            renderer_version: packageJson_js_1.default.version,
        });
    });
    // In tests we will run worker in master thread, so we need to ensure server
    // will not listen:
    // we are extracting worker from cluster to avoid false TS error
    const { worker } = cluster_1.default;
    if (workersCount === 0 || cluster_1.default.isWorker) {
        app.listen({ port }, () => {
            const workerName = worker ? `worker #${worker.id}` : 'master (single-process)';
            log_js_1.default.info(`Node renderer ${workerName} listening on port ${port}!`);
        });
    }
    fastifyConfigFunctions.forEach((configFunction) => {
        configFunction(app);
    });
    return app;
}
//# sourceMappingURL=worker.js.map