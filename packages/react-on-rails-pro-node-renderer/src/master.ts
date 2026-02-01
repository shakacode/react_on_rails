/**
 * Entry point for master process that forks workers.
 * @module master
 */
import cluster from 'cluster';
import log from './shared/log.js';
import { buildConfig, Config, logSanitizedConfig } from './shared/configBuilder.js';
import restartWorkers from './master/restartWorkers.js';
import * as errorReporter from './shared/errorReporter.js';
import { getLicenseStatus } from './shared/licenseValidator.js';

const MILLISECONDS_IN_MINUTE = 60000;

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
