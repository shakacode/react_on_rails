"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const cluster_1 = __importDefault(require("cluster"));
const utils_js_1 = require("../shared/utils.js");
const log_js_1 = __importDefault(require("../shared/log.js"));
const handleGracefulShutdown = (app) => {
    const { worker } = cluster_1.default;
    if (!worker) {
        log_js_1.default.error('handleGracefulShutdown is called on master, expected to call it on worker only');
        return;
    }
    let activeRequestsCount = 0;
    let isShuttingDown = false;
    // Helper to decrement counter and potentially kill worker
    const decrementAndMaybeShutdown = (context) => {
        activeRequestsCount -= 1;
        if (isShuttingDown && activeRequestsCount === 0) {
            log_js_1.default.debug('Worker #%d has no active requests after %s, killing the worker', worker.id, context);
            worker.destroy();
        }
    };
    process.on('message', (msg) => {
        if (msg === utils_js_1.SHUTDOWN_WORKER_MESSAGE) {
            log_js_1.default.debug('Worker #%d received graceful shutdown message', worker.id);
            isShuttingDown = true;
            if (activeRequestsCount === 0) {
                log_js_1.default.debug('Worker #%d has no active requests, killing the worker', worker.id);
                worker.destroy();
            }
            else {
                log_js_1.default.debug('Worker #%d has "%d" active requests, disconnecting the worker', worker.id, activeRequestsCount);
                worker.disconnect();
            }
        }
    });
    app.addHook('onRequest', (_req, _reply, done) => {
        activeRequestsCount += 1;
        done();
    });
    app.addHook('onResponse', (_req, _reply, done) => {
        decrementAndMaybeShutdown('onResponse');
        done();
    });
    // Handle client abort - onResponse is NOT called when client disconnects
    app.addHook('onRequestAbort', (_req, done) => {
        log_js_1.default.debug('Worker #%d: request aborted by client', worker.id);
        decrementAndMaybeShutdown('onRequestAbort');
        done();
    });
    // Handle request timeout - onResponse is NOT called when request times out
    app.addHook('onTimeout', (_req, _reply, done) => {
        log_js_1.default.debug('Worker #%d: request timed out', worker.id);
        decrementAndMaybeShutdown('onTimeout');
        done();
    });
};
exports.default = handleGracefulShutdown;
//# sourceMappingURL=handleGracefulShutdown.js.map