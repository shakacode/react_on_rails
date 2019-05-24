/**
 * Entry point for master process that forks workers.
 * @module master
 */
const cluster = require('cluster');
const log = require('./shared/log');
const { buildConfig, logSanitizedConfig } = require('./shared/configBuilder');
const restartWorkers = require('./master/restartWorkers');

const MILLISECONDS_IN_MINUTE = 60000;

module.exports = function masterRun(runningConfig) {
  // Store config in app state. From now it can be loaded by any module using getConfig():
  const config = buildConfig(runningConfig);
  const { workersCount, allWorkersRestartInterval, delayBetweenIndividualWorkerRestarts } = config;

  logSanitizedConfig();

  // Count available CPUs for worker processes:
  const workerCpuCount = workersCount;

  // Create a worker for each CPU except one that used for master process:
  for (let i = 0; i < workerCpuCount; i += 1) {
    cluster.fork();
  }

  // Listen for dying workers:
  cluster.on('exit', worker => {
    if (worker.isScheduledRestart) {
      log.info('Restarting worker #%d on schedule', worker.id);
    } else {
      log.warn('Worker #%d died UNEXPECTEDLY :(, restarting', worker.id);
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
    setInterval(
      () => restartWorkers(delayBetweenIndividualWorkerRestarts),
      allWorkersRestartInterval * MILLISECONDS_IN_MINUTE,
    );
  } else if (allWorkersRestartInterval || delayBetweenIndividualWorkerRestarts) {
    log.error(
      "Misconfiguration, please provide both 'allWorkersRestartInterval' and " +
        "'delayBetweenIndividualWorkerRestarts' to enable scheduled worker restarts",
    );
    process.exit();
  } else {
    log.info('No schedule for workers restarts');
  }
};
