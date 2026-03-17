"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.startSsrRequestOptions = void 0;
exports.setupTracing = setupTracing;
exports.trace = trace;
const errorReporter_js_1 = require("./errorReporter.js");
/* eslint-enable @typescript-eslint/no-empty-object-type */
let setupRun = false;
let executor = (fn) => fn();
let mutableStartSsrRequestOptions = () => ({});
const startSsrRequestOptions = (request) => mutableStartSsrRequestOptions(request);
exports.startSsrRequestOptions = startSsrRequestOptions;
// TODO: this supports only one tracing plugin.
//  Replace by a function which extends the executor and transaction context instead of replacing them.
/**
 * Sets up tracing for the given integration.
 * @param options.executor - A function that wraps an async callback in the tracing service's unit of work.
 * @param options.startSsrRequestOptions - Options used to start a new unit of work for an SSR request.
 *   Should be an object with your integration name as the only property.
 *   It will be passed to the executor.
 */
function setupTracing(options) {
    if (setupRun) {
        (0, errorReporter_js_1.message)('setupTracing called more than once. Currently only one tracing integration can be enabled.');
        return;
    }
    executor = options.executor;
    if (options.startSsrRequestOptions) {
        mutableStartSsrRequestOptions = options.startSsrRequestOptions;
    }
    setupRun = true;
}
/**
 * Reports a unit of work to the tracing service, if any.
 */
function trace(fn, unitOfWorkOptions) {
    return executor(fn, unitOfWorkOptions);
}
//# sourceMappingURL=tracing.js.map