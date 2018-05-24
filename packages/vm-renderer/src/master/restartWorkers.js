/**
 * Perform all workers restart with provided delay
 * @module master/restartWorkers
 */

import cluster from 'cluster';
import log from 'winston';

const MILLISECONDS_IN_MINUTE = 60000;

module.exports = function restartWorkers(delayBetweenIndividualWorkerRestarts) {
  log.debug('Started scheduled restart of workers');

  let delay = 0;
  Object.keys(cluster.workers).forEach((id) => {
    const worker = cluster.workers[id];
    const killWorker = () => {
      log.debug('Kill worker #%d', worker.id);
      worker.isScheduledRestart = true;
      worker.destroy();
    };
    setTimeout(killWorker, delay);
    delay += delayBetweenIndividualWorkerRestarts * MILLISECONDS_IN_MINUTE;
  });

  setTimeout(() => log.debug('Finished scheduled restart of workers'), delay);
};
