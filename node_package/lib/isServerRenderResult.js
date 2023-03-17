"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isPromise = exports.isServerRenderHash = void 0;
function isServerRenderHash(testValue) {
    return !!(testValue.renderedHtml ||
        testValue.redirectLocation ||
        testValue.routeError ||
        testValue.error);
}
exports.isServerRenderHash = isServerRenderHash;
function isPromise(testValue) {
    return !!(testValue.then);
}
exports.isPromise = isPromise;
