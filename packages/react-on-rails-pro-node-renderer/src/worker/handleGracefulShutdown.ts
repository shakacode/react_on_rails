import cluster from 'cluster';
import { FastifyInstance } from './types.js';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils.js';
import log from '../shared/log.js';
import { runWorkerShutdownHooks } from './shutdownHooks.js';

const WORKER_SHUTDOWN_HOOKS_TIMEOUT_MS = 10_000;

function errorCode(error: unknown): string | undefined {
  const code = (error as { code?: unknown })?.code;
  return typeof code === 'string' ? code : undefined;
}

const handleGracefulShutdown = (app: FastifyInstance) => {
  const { worker } = cluster;
  if (!worker) {
    log.error('handleGracefulShutdown is called on master, expected to call it on worker only');
    return;
  }

  let activeRequestsCount = 0;
  let isShuttingDown = false;
  let isDestroying = false;

  const destroyWorkerAfterShutdownHooks = (context: string) => {
    if (isDestroying) {
      return;
    }

    isDestroying = true;
    log.debug('Worker #%d running shutdown hooks before shutdown after %s', worker.id, context);
    let workerDestroyed = false;
    const destroyWorker = () => {
      if (workerDestroyed) {
        return;
      }
      workerDestroyed = true;
      worker.destroy();
    };
    const shutdownTimeout = setTimeout(() => {
      log.warn('Worker #%d: shutdown hooks timed out, forcing worker.destroy()', worker.id);
      destroyWorker();
    }, WORKER_SHUTDOWN_HOOKS_TIMEOUT_MS);
    const shutdownHooksPromise = runWorkerShutdownHooks();

    void shutdownHooksPromise
      .catch((error: unknown) => {
        log.warn({ msg: 'Error running worker shutdown hooks before worker shutdown', error });
      })
      .finally(() => {
        clearTimeout(shutdownTimeout);
        destroyWorker();
      });
  };

  const disconnectWorker = () => {
    try {
      worker.disconnect();
    } catch (error: unknown) {
      if (errorCode(error) === 'ERR_IPC_DISCONNECTED') {
        log.debug('Worker #%d IPC channel was already disconnected during graceful shutdown', worker.id);
      } else {
        log.warn({ msg: 'Error disconnecting worker during graceful shutdown', error });
      }
    }
  };

  // Helper to decrement counter and potentially kill worker
  const decrementAndMaybeShutdown = (context: string) => {
    activeRequestsCount -= 1;
    if (isShuttingDown && activeRequestsCount === 0) {
      log.debug('Worker #%d has no active requests after %s, killing the worker', worker.id, context);
      destroyWorkerAfterShutdownHooks(context);
    }
  };

  process.on('message', (msg) => {
    if (msg === SHUTDOWN_WORKER_MESSAGE) {
      log.debug('Worker #%d received graceful shutdown message', worker.id);
      isShuttingDown = true;
      if (activeRequestsCount === 0) {
        log.debug('Worker #%d has no active requests, killing the worker', worker.id);
        destroyWorkerAfterShutdownHooks('shutdown message');
      } else {
        log.debug(
          'Worker #%d has "%d" active requests, disconnecting the worker',
          worker.id,
          activeRequestsCount,
        );
        disconnectWorker();
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
