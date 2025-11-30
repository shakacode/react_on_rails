import cluster from 'cluster';
import { FastifyInstance } from './types.js';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils.js';
import log from '../shared/log.js';
import { onMessageEnded, onMessageInitiated } from '../workerMessagesRouter.js';

type GracefulShutdownController = {
  readonly activeRequestsCount: number;
  readonly activeMessageChannelsCount: number;
  readonly isShuttingDown: boolean;
  markNewRequestReceived: () => void;
  markRequestHandled: () => void;
  markNewMessageChannelOpened: () => void;
  markMessageChannelClosed: () => void;
};

let gracefulShutdownController: GracefulShutdownController;

const setupGracefulShutdownHandler = () => {
  if (gracefulShutdownController) {
    return gracefulShutdownController;
  }

  const { worker } = cluster;
  if (!worker) {
    log.error('setupGracefulShutdownHandler is called on master, expected to call it on worker only');
    return undefined;
  }

  let activeRequestsCount = 0;
  let activeMessageChannelsCount = 0;
  let isShuttingDown = false;

  const handleCloseEvent = () => {
    if (!isShuttingDown) {
      return;
    }

    if (activeMessageChannelsCount > 0) {
      log.info(
        'Worker #%d has "%d" active message channels, keep the worker connected',
        worker.id,
        activeMessageChannelsCount,
      );
    } else if (activeRequestsCount > 0) {
      log.info(
        'Worker #%d has "%d" active requests, disconnecting the worker',
        worker.id,
        activeRequestsCount,
      );
      worker.disconnect();
    } else {
      log.info('Worker #%d has no active requests, killing the worker', worker.id);
      worker.destroy();
    }
  };

  gracefulShutdownController = {
    get activeRequestsCount() {
      return activeRequestsCount;
    },
    get activeMessageChannelsCount() {
      return activeMessageChannelsCount;
    },
    get isShuttingDown() {
      return isShuttingDown;
    },
    markNewRequestReceived: () => {
      activeRequestsCount += 1;
    },
    markRequestHandled: () => {
      activeRequestsCount -= 1;
      handleCloseEvent();
    },
    markNewMessageChannelOpened: () => {
      activeMessageChannelsCount += 1;
    },
    markMessageChannelClosed: () => {
      activeMessageChannelsCount -= 1;
      handleCloseEvent();
    },
  };

  process.on('message', (msg) => {
    if (msg === SHUTDOWN_WORKER_MESSAGE) {
      log.info('Worker #%d received graceful shutdown message', worker.id);
      isShuttingDown = true;
      handleCloseEvent();
    }
  });

  return gracefulShutdownController;
};

const handleGracefulShutdown = (app: FastifyInstance) => {
  const controller = setupGracefulShutdownHandler();
  if (!controller) {
    return;
  }

  app.addHook('onRequest', (_req, _reply, done) => {
    controller.markNewRequestReceived();
    done();
  });

  app.addHook('onResponse', (_req, _reply, done) => {
    controller.markRequestHandled();
    done();
  });
};

onMessageInitiated(() => {
  const controller = setupGracefulShutdownHandler();
  controller?.markNewMessageChannelOpened();
});

onMessageEnded(() => {
  const controller = setupGracefulShutdownHandler();
  controller?.markMessageChannelClosed();
});

export default handleGracefulShutdown;
