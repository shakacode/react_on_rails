/**
 * Entry point for master process that forks workers.
 * @module master
 */
import cluster from 'cluster';
import log from './shared/log';
import { buildConfig, Config, logSanitizedConfig } from './shared/configBuilder';
import restartWorkers from './master/restartWorkers';
import * as errorReporter from './shared/errorReporter';
import { isLicenseValid, getLicenseValidationError } from './shared/licenseValidator';

const MILLISECONDS_IN_MINUTE = 60000;

export = function masterRun(runningConfig?: Partial<Config>) {
  // Validate license before starting
  if (!isLicenseValid()) {
    const error = getLicenseValidationError() || 'Invalid license';
    const isDevelopment = process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test';

    if (isDevelopment) {
      log.warn(`[React on Rails Pro] ${error}`);
      // Continue in development with warning
    } else {
      log.error(`[React on Rails Pro] ${error}`);
      process.exit(1);
    }
  } else {
    log.info('[React on Rails Pro] License validation successful');
  }

  // Store config in app state. From now it can be loaded by any module using getConfig():
  const config = buildConfig(runningConfig);
  const { workersCount, allWorkersRestartInterval, delayBetweenIndividualWorkerRestarts } = config;

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
    setInterval(() => {
      restartWorkers(delayBetweenIndividualWorkerRestarts);
    }, allWorkersRestartInterval * MILLISECONDS_IN_MINUTE);
  } else if (allWorkersRestartInterval || delayBetweenIndividualWorkerRestarts) {
    log.error(
      "Misconfiguration, please provide both 'allWorkersRestartInterval' and " +
        "'delayBetweenIndividualWorkerRestarts' to enable scheduled worker restarts",
    );
    process.exit(1);
  } else {
    log.info('No schedule for workers restarts');
  }
};
