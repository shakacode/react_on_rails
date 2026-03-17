"use strict";
/**
 * Perform all workers restart with provided delay
 * @module master/restartWorkers
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = restartWorkers;
const cluster_1 = __importDefault(require("cluster"));
const log_js_1 = __importDefault(require("../shared/log.js"));
const utils_js_1 = require("../shared/utils.js");
const MILLISECONDS_IN_MINUTE = 60000;
async function restartWorkers(delayBetweenIndividualWorkerRestarts, gracefulWorkerRestartTimeout) {
    log_js_1.default.info('Started scheduled restart of workers');
    if (!cluster_1.default.workers) {
        throw new Error('No workers to restart');
    }
    for (const worker of Object.values(cluster_1.default.workers).filter((w) => !!w)) {
        log_js_1.default.debug('Kill worker #%d', worker.id);
        worker.isScheduledRestart = true;
        worker.send(utils_js_1.SHUTDOWN_WORKER_MESSAGE);
        // It's inteded to restart worker in sequence, it shouldn't happens in parallel
        // eslint-disable-next-line no-await-in-loop
        await new Promise((resolve) => {
            let timeout;
            const onExit = () => {
                clearTimeout(timeout);
                resolve();
            };
            worker.on('exit', onExit);
            // Zero means no timeout
            if (gracefulWorkerRestartTimeout) {
                timeout = setTimeout(() => {
                    log_js_1.default.debug('Worker #%d timed out, forcing kill it', worker.id);
                    worker.destroy();
                    worker.off('exit', onExit);
                    resolve();
                }, gracefulWorkerRestartTimeout);
            }
        });
        // eslint-disable-next-line no-await-in-loop
        await new Promise((resolve) => {
            setTimeout(resolve, delayBetweenIndividualWorkerRestarts * MILLISECONDS_IN_MINUTE);
        });
    }
    log_js_1.default.info('Finished scheduled restart of workers');
}
//# sourceMappingURL=restartWorkers.js.map