/**
 * Perform all workers restart with provided delay
 * @module master/restartWorkers
 */

import cluster from 'cluster';
import log from '../shared/log';

const MILLISECONDS_IN_MINUTE = 60000;

declare module 'cluster' {
  interface Worker {
    isScheduledRestart?: boolean;
  }
}

export = function restartWorkers(delayBetweenIndividualWorkerRestarts: number) {
  log.info('Started scheduled restart of workers');

  let delay = 0;
  if (!cluster.workers) {
    throw new Error('No workers to restart');
  }
  Object.values(cluster.workers).forEach((worker) => {
    const killWorker = () => {
      if (!worker) return;
      log.debug('Kill worker #%d', worker.id);
      // eslint-disable-next-line no-param-reassign -- necessary change
      worker.isScheduledRestart = true;
      worker.destroy();
    };
    setTimeout(killWorker, delay);
    delay += delayBetweenIndividualWorkerRestarts * MILLISECONDS_IN_MINUTE;
  });

  setTimeout(() => log.info('Finished scheduled restart of workers'), delay);
};
