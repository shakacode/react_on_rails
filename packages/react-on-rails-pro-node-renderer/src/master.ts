/**
 * Entry point for master process that forks workers.
 * @module master
 */
import path from 'path';
import cluster from 'cluster';
import { readdir, stat, rm } from 'fs/promises';
import log from './shared/log.js';
import { buildConfig, Config, logSanitizedConfig } from './shared/configBuilder.js';
import restartWorkers from './master/restartWorkers.js';
import * as errorReporter from './shared/errorReporter.js';
import { getLicenseStatus } from './shared/licenseValidator.js';

const MILLISECONDS_IN_MINUTE = 60000;
// How often to scan for orphaned upload directories.
const ORPHAN_CLEANUP_INTERVAL_MS = 5 * MILLISECONDS_IN_MINUTE;
// How old a directory must be before it is considered orphaned.
// Set well above the longest realistic upload duration so that large bundle
// uploads in progress are never deleted by the cleanup timer.
const ORPHAN_AGE_THRESHOLD_MS = 30 * MILLISECONDS_IN_MINUTE;

export default function masterRun(runningConfig?: Partial<Config>) {
  // Check license status on startup and log appropriately
  // Use warn in production, info in non-production (matches Ruby behavior)
  // Check both NODE_ENV and RAILS_ENV for production detection to stay consistent
  // with Ruby's Rails.env.production? check
  const status = getLicenseStatus();
  const isProduction = process.env.NODE_ENV === 'production' || process.env.RAILS_ENV === 'production';
  const logLicenseIssue = isProduction ? log.warn.bind(log) : log.info.bind(log);

  if (status === 'valid') {
    log.info('[React on Rails Pro] License validated successfully.');
  } else if (status === 'missing') {
    logLicenseIssue(
      '[React on Rails Pro] No license found. Get a license at https://www.shakacode.com/react-on-rails-pro/',
    );
  } else if (status === 'expired') {
    logLicenseIssue(
      '[React on Rails Pro] License has expired. Renew your license at https://www.shakacode.com/react-on-rails-pro/',
    );
  } else {
    logLicenseIssue(
      '[React on Rails Pro] Invalid license. Get a license at https://www.shakacode.com/react-on-rails-pro/',
    );
  }

  // Store config in app state. From now it can be loaded by any module using getConfig():
  const config = buildConfig(runningConfig);
  const {
    workersCount,
    allWorkersRestartInterval,
    delayBetweenIndividualWorkerRestarts,
    gracefulWorkerRestartTimeout,
  } = config;

  logSanitizedConfig();

  // Periodically clean up orphaned per-request upload directories that workers
  // failed to remove (e.g. after a crash). Each worker creates uploads/<UUID>/
  // directories that are normally cleaned up in the onResponse hook; this timer
  // catches any that were left behind.
  const uploadsDir = path.join(config.serverBundleCachePath, 'uploads');
  setInterval(() => {
    void (async () => {
      try {
        const entries = await readdir(uploadsDir).catch(() => [] as string[]);
        const now = Date.now();
        await Promise.all(
          entries.map(async (entry) => {
            const dirPath = path.join(uploadsDir, entry);
            const stats = await stat(dirPath).catch(() => null);
            if (stats?.isDirectory() && now - stats.mtimeMs > ORPHAN_AGE_THRESHOLD_MS) {
              await rm(dirPath, { recursive: true, force: true });
              log.info({ msg: 'Cleaned up orphaned upload directory', dir: dirPath });
            }
          }),
        );
      } catch (err: unknown) {
        log.warn({ msg: 'Error during orphaned upload directory cleanup', err });
      }
    })();
  }, ORPHAN_CLEANUP_INTERVAL_MS);

  for (let i = 0; i < workersCount; i += 1) {
    cluster.fork();
  }

  // Listen for dying workers:
  cluster.on('exit', (worker) => {
    if (worker.isScheduledRestart) {
      log.info('Restarting worker #%d on schedule', worker.id);
    } else {
      // TODO: Track last rendering request per worker.id
      // TODO: Consider blocking a given rendering request if it kills a worker more than X times
      const msg = `Worker ${worker.id} died UNEXPECTEDLY :(, restarting`;
      errorReporter.message(msg);
    }
    // Replace the dead worker:
    cluster.fork();
  });

  // Schedule regular restarts of workers
  if (allWorkersRestartInterval && delayBetweenIndividualWorkerRestarts) {
    log.info(
      'Scheduled workers restarts every %d minutes (%d minutes btw each)',
      allWorkersRestartInterval,
      delayBetweenIndividualWorkerRestarts,
    );

    const allWorkersRestartIntervalMS = allWorkersRestartInterval * MILLISECONDS_IN_MINUTE;
    const scheduleWorkersRestart = () => {
      void restartWorkers(delayBetweenIndividualWorkerRestarts, gracefulWorkerRestartTimeout).finally(() => {
        setTimeout(scheduleWorkersRestart, allWorkersRestartIntervalMS);
      });
    };

    setTimeout(scheduleWorkersRestart, allWorkersRestartIntervalMS);
  } else if (allWorkersRestartInterval || delayBetweenIndividualWorkerRestarts) {
    log.error(
      "Misconfiguration, please provide both 'allWorkersRestartInterval' and " +
        "'delayBetweenIndividualWorkerRestarts' to enable scheduled worker restarts",
    );
    process.exit(1);
  } else {
    log.info('No schedule for workers restarts');
  }
}
