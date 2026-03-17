"use strict";
/**
 * Isolates logic for handling render request. We don't want this module to
 * Fastify server and its Request and Reply objects. This allows to test
 * module in isolation and without async calls.
 * @module worker/handleRenderRequest
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
exports.handleNewBundlesProvided = handleNewBundlesProvided;
exports.handleRenderRequest = handleRenderRequest;
const cluster_1 = __importDefault(require("cluster"));
const path_1 = __importDefault(require("path"));
const promises_1 = require("fs/promises");
const locks_js_1 = require("../shared/locks.js");
const fileExistsAsync_js_1 = __importDefault(require("../shared/fileExistsAsync.js"));
const log_js_1 = __importDefault(require("../shared/log.js"));
const utils_js_1 = require("../shared/utils.js");
const configBuilder_js_1 = require("../shared/configBuilder.js");
const errorReporter = __importStar(require("../shared/errorReporter.js"));
const vm_js_1 = require("./vm.js");
async function prepareResult(renderingRequest, bundleFilePathPerTimestamp, executionContext) {
    try {
        const result = await executionContext.runInVM(renderingRequest, bundleFilePathPerTimestamp, cluster_1.default);
        let exceptionMessage = null;
        if (!result) {
            const error = new Error('INVALID NIL or NULL result for rendering');
            exceptionMessage = (0, utils_js_1.formatExceptionMessage)(renderingRequest, error, 'INVALID result for prepareResult');
        }
        else if ((0, utils_js_1.isErrorRenderResult)(result)) {
            ({ exceptionMessage } = result);
        }
        if (exceptionMessage) {
            return (0, utils_js_1.errorResponseResult)(exceptionMessage);
        }
        if ((0, utils_js_1.isReadableStream)(result)) {
            return {
                headers: { 'Cache-Control': 'public, max-age=31536000' },
                status: 200,
                stream: result,
            };
        }
        return {
            headers: { 'Cache-Control': 'public, max-age=31536000' },
            status: 200,
            data: result,
        };
    }
    catch (err) {
        const exceptionMessage = (0, utils_js_1.formatExceptionMessage)(renderingRequest, err, 'Unknown error calling runInVM');
        return (0, utils_js_1.errorResponseResult)(exceptionMessage);
    }
}
/**
 * @param bundleFilePathPerTimestamp
 * @param providedNewBundle
 * @param renderingRequest
 * @param assetsToCopy might be null
 */
async function handleNewBundleProvided(renderingRequest, providedNewBundle, assetsToCopy) {
    const bundleFilePathPerTimestamp = (0, utils_js_1.getRequestBundleFilePath)(providedNewBundle.timestamp);
    const bundleDirectory = path_1.default.dirname(bundleFilePathPerTimestamp);
    await (0, promises_1.mkdir)(bundleDirectory, { recursive: true });
    log_js_1.default.info('Worker received new bundle: %s', bundleFilePathPerTimestamp);
    let lockAcquired = false;
    let lockfileName;
    try {
        const { lockfileName: name, wasLockAcquired, errorMessage } = await (0, locks_js_1.lock)(bundleFilePathPerTimestamp);
        lockfileName = name;
        lockAcquired = wasLockAcquired;
        if (!wasLockAcquired) {
            const msg = (0, utils_js_1.formatExceptionMessage)(renderingRequest, errorMessage, `Failed to acquire lock ${lockfileName}. Worker: ${(0, utils_js_1.workerIdLabel)()}.`);
            return (0, utils_js_1.errorResponseResult)(msg);
        }
        try {
            log_js_1.default.info(`Moving uploaded file ${providedNewBundle.bundle.savedFilePath} to ${bundleFilePathPerTimestamp}`);
            await (0, utils_js_1.moveUploadedAsset)(providedNewBundle.bundle, bundleFilePathPerTimestamp);
            if (assetsToCopy) {
                await (0, utils_js_1.copyUploadedAssets)(assetsToCopy, bundleDirectory);
            }
            log_js_1.default.info(`Completed moving uploaded file ${providedNewBundle.bundle.savedFilePath} to ${bundleFilePathPerTimestamp}`);
        }
        catch (error) {
            const fileExists = await (0, fileExistsAsync_js_1.default)(bundleFilePathPerTimestamp);
            if (!fileExists) {
                const msg = (0, utils_js_1.formatExceptionMessage)(renderingRequest, error, `Unexpected error when moving the bundle from ${providedNewBundle.bundle.savedFilePath} \
to ${bundleFilePathPerTimestamp})`);
                log_js_1.default.error(msg);
                return (0, utils_js_1.errorResponseResult)(msg);
            }
            log_js_1.default.info('File exists when trying to overwrite bundle %s. Assuming bundle written by other thread', bundleFilePathPerTimestamp);
        }
        return undefined;
    }
    finally {
        if (lockAcquired && lockfileName) {
            log_js_1.default.info('About to unlock %s from worker %s', lockfileName, (0, utils_js_1.workerIdLabel)());
            try {
                await (0, locks_js_1.unlock)(lockfileName);
            }
            catch (error) {
                const msg = (0, utils_js_1.formatExceptionMessage)(renderingRequest, error, `Error unlocking ${lockfileName} from worker ${(0, utils_js_1.workerIdLabel)()}.`);
                log_js_1.default.warn(msg);
            }
        }
    }
}
async function handleNewBundlesProvided(renderingRequest, providedNewBundles, assetsToCopy) {
    log_js_1.default.info('Worker received new bundles: %s', providedNewBundles);
    const handlingPromises = providedNewBundles.map((providedNewBundle) => handleNewBundleProvided(renderingRequest, providedNewBundle, assetsToCopy));
    // Defensive: use allSettled so that if handleNewBundleProvided ever throws
    // unexpectedly, all in-flight operations still complete before the handler
    // returns and the onResponse hook deletes req.uploadDir. Currently
    // handleNewBundleProvided catches its own errors, so Promise.all would also
    // wait for every promise.
    const settled = await Promise.allSettled(handlingPromises);
    const firstFailure = settled.find((r) => r.status === 'rejected');
    if (firstFailure) {
        throw firstFailure.reason;
    }
    // handleNewBundleProvided returns undefined on success or a ResponseResult on
    // failure (e.g., lock timeout). Find the first error response, if any.
    const results = settled
        .filter((r) => r.status === 'fulfilled')
        .map((r) => r.value);
    return results.find((result) => result !== undefined);
}
/**
 * Creates the result for the Fastify server to use.
 * @returns Promise where the result contains { status, data, headers } to
 * send back to the browser.
 */
async function handleRenderRequest({ renderingRequest, bundleTimestamp, dependencyBundleTimestamps, providedNewBundles, assetsToCopy, }) {
    try {
        // const bundleFilePathPerTimestamp = getRequestBundleFilePath(bundleTimestamp);
        const allBundleFilePaths = Array.from(new Set([...(dependencyBundleTimestamps ?? []), bundleTimestamp].map(utils_js_1.getRequestBundleFilePath)));
        const entryBundleFilePath = (0, utils_js_1.getRequestBundleFilePath)(bundleTimestamp);
        const { maxVMPoolSize } = (0, configBuilder_js_1.getConfig)();
        if (allBundleFilePaths.length > maxVMPoolSize) {
            return {
                response: {
                    headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
                    status: 410,
                    data: `Too many bundles uploaded. The maximum allowed is ${maxVMPoolSize}. Please reduce the number of bundles or increase maxVMPoolSize in your configuration.`,
                },
            };
        }
        try {
            const executionContext = await (0, vm_js_1.buildExecutionContext)(allBundleFilePaths, /* buildVmsIfNeeded */ false);
            return {
                response: await prepareResult(renderingRequest, entryBundleFilePath, executionContext),
                executionContext,
            };
        }
        catch (e) {
            // Ignore VMContextNotFoundError, it means the bundle does not exist.
            // The following code will handle this case.
            if (!(e instanceof vm_js_1.VMContextNotFoundError)) {
                throw e;
            }
        }
        // If gem has posted updated bundle:
        if (providedNewBundles && providedNewBundles.length > 0) {
            const result = await handleNewBundlesProvided(renderingRequest, providedNewBundles, assetsToCopy);
            if (result) {
                return { response: result };
            }
        }
        // Check if the bundle exists:
        const missingBundleError = await (0, utils_js_1.validateBundlesExist)(bundleTimestamp, dependencyBundleTimestamps);
        if (missingBundleError) {
            return { response: missingBundleError };
        }
        // The bundle exists, but the VM has not yet been created.
        // Another worker must have written it or it was saved during deployment.
        log_js_1.default.info('Bundle %s exists. Building ExecutionContext for worker %s.', entryBundleFilePath, (0, utils_js_1.workerIdLabel)());
        const executionContext = await (0, vm_js_1.buildExecutionContext)(allBundleFilePaths, /* buildVmsIfNeeded */ true);
        return {
            response: await prepareResult(renderingRequest, entryBundleFilePath, executionContext),
            executionContext,
        };
    }
    catch (error) {
        const msg = (0, utils_js_1.formatExceptionMessage)(renderingRequest, error, 'Caught top level error in handleRenderRequest');
        errorReporter.message(msg);
        return Promise.reject(error);
    }
}
//# sourceMappingURL=handleRenderRequest.js.map