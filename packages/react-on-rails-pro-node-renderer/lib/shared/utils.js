"use strict";
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
exports.delay = exports.majorVersion = exports.isErrorRenderResult = exports.handleStreamError = exports.isReadableStream = exports.SHUTDOWN_WORKER_MESSAGE = exports.TRUNCATION_FILLER = void 0;
exports.workerIdLabel = workerIdLabel;
exports.smartTrim = smartTrim;
exports.errorResponseResult = errorResponseResult;
exports.formatExceptionMessage = formatExceptionMessage;
exports.saveMultipartFile = saveMultipartFile;
exports.moveUploadedAsset = moveUploadedAsset;
exports.copyUploadedAsset = copyUploadedAsset;
exports.copyUploadedAssets = copyUploadedAssets;
exports.isPromise = isPromise;
exports.getBundleDirectory = getBundleDirectory;
exports.getRequestBundleFilePath = getRequestBundleFilePath;
exports.getAssetPath = getAssetPath;
exports.validateBundlesExist = validateBundlesExist;
const cluster_1 = __importDefault(require("cluster"));
const path_1 = __importDefault(require("path"));
const fs_extra_1 = require("fs-extra");
const stream_1 = require("stream");
const util_1 = require("util");
const errorReporter = __importStar(require("./errorReporter.js"));
const configBuilder_js_1 = require("./configBuilder.js");
const log_js_1 = __importDefault(require("./log.js"));
const fileExistsAsync_js_1 = __importDefault(require("./fileExistsAsync.js"));
exports.TRUNCATION_FILLER = '\n... TRUNCATED ...\n';
exports.SHUTDOWN_WORKER_MESSAGE = 'NODE_RENDERER_SHUTDOWN_WORKER';
function workerIdLabel() {
    return cluster_1.default?.worker?.id || 'NO WORKER ID';
}
// From https://stackoverflow.com/a/831583/1009332
function smartTrim(value, maxLength = (0, configBuilder_js_1.getConfig)().maxDebugSnippetLength) {
    let string;
    if (value == null)
        return null;
    if (typeof value === 'string') {
        string = value;
    }
    else if (value instanceof String) {
        string = value.toString();
    }
    else {
        string = JSON.stringify(value);
    }
    if (maxLength < 1)
        return string;
    if (string.length <= maxLength)
        return string;
    if (maxLength === 1)
        return string.substring(0, 1) + exports.TRUNCATION_FILLER;
    const midpoint = Math.ceil(string.length / 2);
    const toRemove = string.length - maxLength;
    const lstrip = Math.ceil(toRemove / 2);
    const rstrip = toRemove - lstrip;
    return string.substring(0, midpoint - lstrip) + exports.TRUNCATION_FILLER + string.substring(midpoint + rstrip);
}
function errorResponseResult(msg) {
    errorReporter.message(msg);
    return {
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        status: 400,
        data: msg,
    };
}
/**
 * @param renderingRequest The JavaScript code which threw an error
 * @param error The error that was thrown (typed as `unknown` to minimize casts in `catch`)
 * @param context Optional context to include in the error message
 */
function formatExceptionMessage(renderingRequest, error, context) {
    return `${context ? `\nContext:\n${context}\n` : ''}
JS code for rendering request was:
${smartTrim(renderingRequest)}
    
EXCEPTION MESSAGE:
${error.message || error}

STACK:
${error.stack}`;
}
// https://github.com/fastify/fastify-multipart?tab=readme-ov-file#usage
const pump = (0, util_1.promisify)(stream_1.pipeline);
async function saveMultipartFile(multipartFile, destinationPath) {
    await (0, fs_extra_1.ensureDir)(path_1.default.dirname(destinationPath));
    return pump(multipartFile.file, (0, fs_extra_1.createWriteStream)(destinationPath));
}
function moveUploadedAsset(asset, destinationPath, options = {}) {
    return (0, fs_extra_1.move)(asset.savedFilePath, destinationPath, options);
}
function copyUploadedAsset(asset, destinationPath, options = {}) {
    return (0, fs_extra_1.copy)(asset.savedFilePath, destinationPath, options);
}
async function copyUploadedAssets(uploadedAssets, targetDirectory) {
    const copyMultipleAssets = uploadedAssets.map((asset) => {
        const destinationAssetFilePath = path_1.default.join(targetDirectory, asset.filename);
        return copyUploadedAsset(asset, destinationAssetFilePath, { overwrite: true });
    });
    await Promise.all(copyMultipleAssets);
    log_js_1.default.info(`Copied assets ${JSON.stringify(uploadedAssets.map((fileDescriptor) => fileDescriptor.filename))}`);
}
function isPromise(value) {
    return value && typeof value.then === 'function';
}
const isReadableStream = (stream) => typeof stream === 'object' &&
    stream !== null &&
    typeof stream.pipe === 'function' &&
    typeof stream.read === 'function';
exports.isReadableStream = isReadableStream;
const handleStreamError = (stream, onError) => {
    const newStreamAfterHandlingError = new stream_1.PassThrough();
    stream.on('error', onError);
    stream.pipe(newStreamAfterHandlingError);
    return newStreamAfterHandlingError;
};
exports.handleStreamError = handleStreamError;
const isErrorRenderResult = (result) => typeof result === 'object' && !(0, exports.isReadableStream)(result) && 'exceptionMessage' in result;
exports.isErrorRenderResult = isErrorRenderResult;
// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
const majorVersion = (version) => Number.parseInt(version.split('.', 2)[0], 10);
exports.majorVersion = majorVersion;
// Can be replaced by `import { setTimeout } from 'timers/promises'` when Node 16 is the minimum supported version
const delay = (milliseconds) => new Promise((resolve) => {
    setTimeout(resolve, milliseconds);
});
exports.delay = delay;
function getBundleDirectory(bundleTimestamp) {
    const { serverBundleCachePath } = (0, configBuilder_js_1.getConfig)();
    return path_1.default.join(serverBundleCachePath, `${bundleTimestamp}`);
}
function getRequestBundleFilePath(bundleTimestamp) {
    const bundleDirectory = getBundleDirectory(bundleTimestamp);
    return path_1.default.join(bundleDirectory, `${bundleTimestamp}.js`);
}
function getAssetPath(bundleTimestamp, filename) {
    const bundleDirectory = getBundleDirectory(bundleTimestamp);
    return path_1.default.join(bundleDirectory, filename);
}
async function validateBundlesExist(bundleTimestamp, dependencyBundleTimestamps) {
    const missingBundles = (await Promise.all([...(dependencyBundleTimestamps ?? []), bundleTimestamp].map(async (timestamp) => {
        const bundleFilePath = getRequestBundleFilePath(timestamp);
        const fileExists = await (0, fileExistsAsync_js_1.default)(bundleFilePath);
        return fileExists ? null : timestamp;
    }))).filter((timestamp) => timestamp !== null);
    if (missingBundles.length > 0) {
        const missingBundlesText = missingBundles.length > 1 ? 'bundles' : 'bundle';
        log_js_1.default.info(`No saved ${missingBundlesText}: ${missingBundles.join(', ')}`);
        return {
            headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
            status: 410,
            data: 'No bundle uploaded',
        };
    }
    return null;
}
//# sourceMappingURL=utils.js.map