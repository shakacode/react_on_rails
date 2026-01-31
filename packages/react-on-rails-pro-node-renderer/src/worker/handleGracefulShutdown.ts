import cluster from 'cluster';
import { FastifyInstance } from './types.js';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils.js';
import log from '../shared/log.js';

const handleGracefulShutdown = (app: FastifyInstance) => {
  const { worker } = cluster;
  if (!worker) {
    log.error('handleGracefulShutdown is called on master, expected to call it on worker only');
    return;
  }

  let activeRequestsCount = 0;
  let isShuttingDown = false;

  // Helper to decrement counter and potentially kill worker
  const decrementAndMaybeShutdown = (context: string) => {
    activeRequestsCount -= 1;
    if (isShuttingDown && activeRequestsCount === 0) {
      log.debug('Worker #%d has no active requests after %s, killing the worker', worker.id, context);
      worker.destroy();
    }
  };

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
    decrementAndMaybeShutdown('onResponse');
    done();
  });

  // Handle client abort - onResponse is NOT called when client disconnects
  app.addHook('onRequestAbort', (_req, done) => {
    log.debug('Worker #%d: request aborted by client', worker.id);
    decrementAndMaybeShutdown('onRequestAbort');
    done();
  });

  // Handle request timeout - onResponse is NOT called when request times out
  app.addHook('onTimeout', (_req, _reply, done) => {
    log.debug('Worker #%d: request timed out', worker.id);
    decrementAndMaybeShutdown('onTimeout');
    done();
  });
};

export default handleGracefulShutdown;
