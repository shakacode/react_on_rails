import cluster from 'cluster';
import { FastifyInstance } from './types';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils';
import log from '../shared/log';

const handleGracefulShutdown = (app: FastifyInstance) => {
  const { worker } = cluster;
  if (!worker) {
    log.error('handleGracefulShutdown is called on master, expected to call it on worker only');
    return;
  }

  let activeRequestsCount = 0;
  let isShuttingDown = false;

  process.on('message', (msg) => {
    if (msg === SHUTDOWN_WORKER_MESSAGE) {
      log.debug('Worker #%d received graceful shutdown message', worker.id);
      isShuttingDown = true;
      if (activeRequestsCount === 0) {
        log.debug('Worker #%d has no active requests, killing the worker', worker.id);
        worker.destroy();
      } else {
        log.debug(
          'Worker #%d has "%d" active requests, disconnecting the worker',
          worker.id,
          activeRequestsCount,
        );
        worker.disconnect();
      }
    }
  });

  app.addHook('onRequest', (_req, _reply, done) => {
    activeRequestsCount += 1;
    done();
  });

  app.addHook('onResponse', (_req, _reply, done) => {
    activeRequestsCount -= 1;
    if (isShuttingDown && activeRequestsCount === 0) {
      log.debug('Worker #%d served all active requests and going to be killed', worker.id);
      worker.destroy();
    }
    done();
  });
};

export default handleGracefulShutdown;
