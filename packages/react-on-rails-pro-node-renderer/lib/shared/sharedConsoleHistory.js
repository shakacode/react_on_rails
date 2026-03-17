"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const async_hooks_1 = require("async_hooks");
const configBuilder_js_1 = require("./configBuilder.js");
const log_js_1 = __importDefault(require("./log.js"));
const utils_js_1 = require("./utils.js");
function replayConsoleOnRenderer(consoleHistory) {
    if (log_js_1.default.level !== 'debug')
        return;
    consoleHistory.forEach((msg) => {
        const stringifiedList = msg.arguments.map((arg) => {
            let val;
            try {
                val = typeof arg === 'string' || arg instanceof String ? arg : JSON.stringify(arg);
            }
            catch (e) {
                val = `${e.message}: ${arg}`;
            }
            return val;
        });
        log_js_1.default.debug(stringifiedList.join(' '));
    });
}
// AsyncLocalStorage is available in Node.js 12.17.0 and later versions
const canUseAsyncLocalStorage = () => typeof async_hooks_1.AsyncLocalStorage !== 'undefined' && (0, configBuilder_js_1.getConfig)().replayServerAsyncOperationLogs;
class SharedConsoleHistory {
    constructor() {
        if (canUseAsyncLocalStorage()) {
            this.asyncLocalStorageIfEnabled = new async_hooks_1.AsyncLocalStorage();
        }
        this.isRunningSyncOperation = false;
        this.syncHistory = [];
    }
    getConsoleHistory() {
        if (this.asyncLocalStorageIfEnabled) {
            return this.asyncLocalStorageIfEnabled.getStore()?.consoleHistory ?? [];
        }
        // If console history is not safely stored in AsyncLocalStorage,
        // then return it only in sync operations (to avoid data leakage)
        return this.isRunningSyncOperation ? this.syncHistory : [];
    }
    addToConsoleHistory(message) {
        if (this.asyncLocalStorageIfEnabled) {
            this.asyncLocalStorageIfEnabled.getStore()?.consoleHistory.push(message);
        }
        else {
            this.syncHistory.push(message);
        }
    }
    replayConsoleLogsAfterRender(result, customConsoleHistory) {
        const replayLogs = (value) => {
            const consoleHistory = customConsoleHistory ?? this.syncHistory;
            replayConsoleOnRenderer(consoleHistory);
            return value;
        };
        // TODO: replay console logs for readable streams
        if ((0, utils_js_1.isReadableStream)(result)) {
            return result;
        }
        if ((0, utils_js_1.isPromise)(result)) {
            return result.then(replayLogs);
        }
        return replayLogs(result);
    }
    trackConsoleHistoryInRenderRequest(renderRequestFunction) {
        this.isRunningSyncOperation = true;
        let result;
        try {
            if (this.asyncLocalStorageIfEnabled) {
                const storage = { consoleHistory: [] };
                result = this.asyncLocalStorageIfEnabled.run(storage, renderRequestFunction);
                return this.replayConsoleLogsAfterRender(result, storage.consoleHistory);
            }
            this.syncHistory = [];
            result = renderRequestFunction();
            return this.replayConsoleLogsAfterRender(result);
        }
        finally {
            this.isRunningSyncOperation = false;
            this.syncHistory = [];
        }
    }
}
exports.default = SharedConsoleHistory;
//# sourceMappingURL=sharedConsoleHistory.js.map