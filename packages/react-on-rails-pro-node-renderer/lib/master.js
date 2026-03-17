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
exports.default = masterRun;
/**
 * Entry point for master process that forks workers.
 * @module master
 */
const path_1 = __importDefault(require("path"));
const cluster_1 = __importDefault(require("cluster"));
const promises_1 = require("fs/promises");
const log_js_1 = __importDefault(require("./shared/log.js"));
const configBuilder_js_1 = require("./shared/configBuilder.js");
const restartWorkers_js_1 = __importDefault(require("./master/restartWorkers.js"));
const errorReporter = __importStar(require("./shared/errorReporter.js"));
const licenseValidator_js_1 = require("./shared/licenseValidator.js");
const MILLISECONDS_IN_MINUTE = 60000;
// How often to scan for orphaned upload directories.
const ORPHAN_CLEANUP_INTERVAL_MS = 5 * MILLISECONDS_IN_MINUTE;
// How old a directory must be before it is considered orphaned.
// Set well above the longest realistic upload duration so that large bundle
// uploads in progress are never deleted by the cleanup timer.
const ORPHAN_AGE_THRESHOLD_MS = 30 * MILLISECONDS_IN_MINUTE;
function masterRun(runningConfig) {
    // Check license status on startup and log appropriately
    // Use warn in production, info in non-production (matches Ruby behavior)
    // Check both NODE_ENV and RAILS_ENV for production detection to stay consistent
    // with Ruby's Rails.env.production? check
    const status = (0, licenseValidator_js_1.getLicenseStatus)();
    const isProduction = process.env.NODE_ENV === 'production' || process.env.RAILS_ENV === 'production';
    const logLicenseIssue = isProduction ? log_js_1.default.warn.bind(log_js_1.default) : log_js_1.default.info.bind(log_js_1.default);
    if (status === 'valid') {
        log_js_1.default.info('[React on Rails Pro] License validated successfully.');
    }
    else if (status === 'missing') {
        logLicenseIssue('[React on Rails Pro] No license found. Get a license at https://www.shakacode.com/react-on-rails-pro/');
    }
    else if (status === 'expired') {
        logLicenseIssue('[React on Rails Pro] License has expired. Renew your license at https://www.shakacode.com/react-on-rails-pro/');
    }
    else {
        logLicenseIssue('[React on Rails Pro] Invalid license. Get a license at https://www.shakacode.com/react-on-rails-pro/');
    }
    // Store config in app state. From now it can be loaded by any module using getConfig():
    const config = (0, configBuilder_js_1.buildConfig)(runningConfig);
    const { workersCount, allWorkersRestartInterval, delayBetweenIndividualWorkerRestarts, gracefulWorkerRestartTimeout, } = config;
    (0, configBuilder_js_1.logSanitizedConfig)();
    // Periodically clean up orphaned per-request upload directories that workers
    // failed to remove (e.g. after a crash). Each worker creates uploads/<UUID>/
    // directories that are normally cleaned up in the onResponse hook; this timer
    // catches any that were left behind.
    const uploadsDir = path_1.default.join(config.serverBundleCachePath, 'uploads');
    setInterval(() => {
        void (async () => {
            try {
                const entries = await (0, promises_1.readdir)(uploadsDir).catch(() => []);
                const now = Date.now();
                await Promise.all(entries.map(async (entry) => {
                    const dirPath = path_1.default.join(uploadsDir, entry);
                    const stats = await (0, promises_1.stat)(dirPath).catch(() => null);
                    if (stats?.isDirectory() && now - stats.mtimeMs > ORPHAN_AGE_THRESHOLD_MS) {
                        await (0, promises_1.rm)(dirPath, { recursive: true, force: true });
                        log_js_1.default.info({ msg: 'Cleaned up orphaned upload directory', dir: dirPath });
                    }
                }));
            }
            catch (err) {
                log_js_1.default.warn({ msg: 'Error during orphaned upload directory cleanup', err });
            }
        })();
    }, ORPHAN_CLEANUP_INTERVAL_MS);
    for (let i = 0; i < workersCount; i += 1) {
        cluster_1.default.fork();
    }
    // Listen for dying workers:
    cluster_1.default.on('exit', (worker) => {
        if (worker.isScheduledRestart) {
            log_js_1.default.info('Restarting worker #%d on schedule', worker.id);
        }
        else {
            // TODO: Track last rendering request per worker.id
            // TODO: Consider blocking a given rendering request if it kills a worker more than X times
            const msg = `Worker ${worker.id} died UNEXPECTEDLY :(, restarting`;
            errorReporter.message(msg);
        }
        // Replace the dead worker:
        cluster_1.default.fork();
    });
    // Schedule regular restarts of workers
    if (allWorkersRestartInterval && delayBetweenIndividualWorkerRestarts) {
        log_js_1.default.info('Scheduled workers restarts every %d minutes (%d minutes btw each)', allWorkersRestartInterval, delayBetweenIndividualWorkerRestarts);
        const allWorkersRestartIntervalMS = allWorkersRestartInterval * MILLISECONDS_IN_MINUTE;
        const scheduleWorkersRestart = () => {
            void (0, restartWorkers_js_1.default)(delayBetweenIndividualWorkerRestarts, gracefulWorkerRestartTimeout).finally(() => {
                setTimeout(scheduleWorkersRestart, allWorkersRestartIntervalMS);
            });
        };
        setTimeout(scheduleWorkersRestart, allWorkersRestartIntervalMS);
    }
    else if (allWorkersRestartInterval || delayBetweenIndividualWorkerRestarts) {
        log_js_1.default.error("Misconfiguration, please provide both 'allWorkersRestartInterval' and " +
            "'delayBetweenIndividualWorkerRestarts' to enable scheduled worker restarts");
        process.exit(1);
    }
    else {
        log_js_1.default.info('No schedule for workers restarts');
    }
}
//# sourceMappingURL=master.js.map