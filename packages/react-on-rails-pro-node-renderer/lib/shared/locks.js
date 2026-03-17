"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.unlock = unlock;
exports.lock = lock;
const lockfile_1 = __importDefault(require("lockfile"));
const util_1 = require("util");
const debug_js_1 = __importDefault(require("./debug.js"));
const log_js_1 = __importDefault(require("./log.js"));
const utils_js_1 = require("./utils.js");
const lockfileLockAsync = (0, util_1.promisify)(lockfile_1.default.lock);
const lockfileUnlockAsync = (0, util_1.promisify)(lockfile_1.default.unlock);
const TEST_LOCKFILE_THREADING = false;
// See definitions here: https://github.com/npm/lockfile/blob/master/README.md#options
/*
 * A number of milliseconds to wait for locks to expire before giving up. Only used by
 * lockFile.lock. Poll for opts.wait ms. If the lock is not cleared by the time the wait expires,
 * then it returns with the original error.
 */
const LOCKFILE_WAIT = 3000;
/*
 * When using opts.wait, this is the period in ms in which it polls to check if the lock has
 * expired. Defaults to 100.
 */
const LOCKFILE_POLL_PERIOD = 300; // defaults to 100
/*
 * A number of milliseconds before locks are considered to have expired.
 */
const LOCKFILE_STALE = 20000;
/*
 * Used by lock and lockSync. Retry n number of times before giving up.
 */
const LOCKFILE_RETRIES = 45;
/*
 * Used by lock. Wait n milliseconds before retrying.
 */
const LOCKFILE_RETRY_WAIT = 300;
const lockfileOptions = {
    wait: LOCKFILE_WAIT,
    retryWait: LOCKFILE_RETRY_WAIT,
    retries: LOCKFILE_RETRIES,
    stale: LOCKFILE_STALE,
    pollPeriod: LOCKFILE_POLL_PERIOD,
};
async function unlock(lockfileName) {
    (0, debug_js_1.default)('Worker %s: About to unlock %s', (0, utils_js_1.workerIdLabel)(), lockfileName);
    log_js_1.default.info('Worker %s: About to unlock %s', (0, utils_js_1.workerIdLabel)(), lockfileName);
    await lockfileUnlockAsync(lockfileName);
}
async function lock(filename) {
    const lockfileName = `${filename}.lock`;
    const workerId = (0, utils_js_1.workerIdLabel)();
    try {
        (0, debug_js_1.default)('Worker %s: About to request lock %s', workerId, lockfileName);
        log_js_1.default.info('Worker %s: About to request lock %s', workerId, lockfileName);
        await lockfileLockAsync(lockfileName, lockfileOptions);
        if (TEST_LOCKFILE_THREADING) {
            (0, debug_js_1.default)('Worker %i: handleNewBundleProvided sleeping 5s', workerId);
            await (0, utils_js_1.delay)(5000);
            (0, debug_js_1.default)('Worker %i: handleNewBundleProvided done sleeping 5s', workerId);
        }
        (0, debug_js_1.default)('After acquired lock in pid', lockfileName);
    }
    catch (error) {
        log_js_1.default.info('Worker %s: Failed to acquire lock %s, error %s', workerId, lockfileName, error);
        return { lockfileName, wasLockAcquired: false, errorMessage: error };
    }
    return { lockfileName, wasLockAcquired: true, errorMessage: null };
}
//# sourceMappingURL=locks.js.map