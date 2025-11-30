/**
 * Entry point for master process that forks workers.
 * @module master
 */
import cluster from 'cluster';
import log from './shared/log.js';
import { buildConfig, Config, logSanitizedConfig } from './shared/configBuilder.js';
import restartWorkers from './master/restartWorkers.js';
import * as errorReporter from './shared/errorReporter.js';
import { getValidatedLicenseData } from './shared/licenseValidator.js';
import { routeMessagesFromWorker } from './workerMessagesRouter.js';

const MILLISECONDS_IN_MINUTE = 60000;

export default function masterRun(runningConfig?: Partial<Config>) {
  // Validate license before starting - required in all environments
  log.info('[React on Rails Pro] Validating license...');
  getValidatedLicenseData();
  log.info('[React on Rails Pro] License validation successful');

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
    const worker = cluster.fork();
    routeMessagesFromWorker(worker);
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
    const newWorker = cluster.fork();
    routeMessagesFromWorker(newWorker);
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
