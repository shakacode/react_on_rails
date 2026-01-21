import cluster from 'cluster';
import { finished } from 'stream';
import { FastifyInstance } from './types.js';
import { SHUTDOWN_WORKER_MESSAGE } from '../shared/utils.js';
import log from '../shared/log.js';

// Symbol to track if we've already decremented for this request.
// This prevents double-decrementing when multiple completion mechanisms fire
// (e.g., both onResponse AND reply.raw 'close' event).
const REQUEST_COUNTED_DOWN = Symbol('request-counted-down');

// Augment the FastifyRequest type to include our tracking symbol
declare module 'fastify' {
  interface FastifyRequest {
    [REQUEST_COUNTED_DOWN]?: boolean;
  }
}

const handleGracefulShutdown = (app: FastifyInstance) => {
  const { worker } = cluster;
  // Support both cluster mode (worker is defined) and single-process mode (worker is undefined)
  const workerId = worker?.id ?? 'single';

  let activeRequestsCount = 0;
  let isShuttingDown = false;

  /**
   * Decrements the active request count and handles shutdown if needed.
   * Uses a flag on the request to prevent double-decrementing.
   */
  const decrementRequestCount = (req: { [REQUEST_COUNTED_DOWN]?: boolean }, source: string) => {
    // Prevent double-decrementing if multiple completion mechanisms fire
    if (req[REQUEST_COUNTED_DOWN]) {
      log.debug('Worker #%s request already counted down (source: %s), skipping', workerId, source);
      return;
    }
    req[REQUEST_COUNTED_DOWN] = true;

    // Safety check: never decrement below 0
    if (activeRequestsCount <= 0) {
      log.warn(
        'Worker #%s attempted to decrement activeRequestsCount below 0 (source: %s), current: %d',
        workerId,
        source,
        activeRequestsCount,
      );
      return;
    }

    activeRequestsCount -= 1;
    log.debug(
      'Worker #%s request completed (source: %s), active requests: %d, isShuttingDown: %s',
      workerId,
      source,
      activeRequestsCount,
      isShuttingDown,
    );

    if (isShuttingDown && activeRequestsCount === 0) {
      log.debug('Worker #%s all requests completed, shutting down', workerId);
      if (worker) {
        worker.destroy();
      } else {
        // Single-process mode: close the app
        void app.close();
      }
    }
  };

  // Only register shutdown message handler in cluster mode
  if (worker) {
    process.on('message', (msg) => {
      if (msg === SHUTDOWN_WORKER_MESSAGE) {
        log.debug('Worker #%s received graceful shutdown message', workerId);
        isShuttingDown = true;
        if (activeRequestsCount === 0) {
          log.debug('Worker #%s has no active requests, killing the worker', workerId);
          worker.destroy();
        } else {
          log.debug(
            'Worker #%s has "%d" active requests, closing server and waiting for requests to complete',
            workerId,
            activeRequestsCount,
          );
          // Close the server to stop accepting new connections, but DON'T disconnect yet.
          // The worker will be destroyed when all active requests complete (see decrementRequestCount).
          // Note: app.close() returns a promise, but we don't need to await it here.
          // The server will stop accepting new connections immediately, and existing connections
          // will be allowed to complete.
          void app.close();
        }
      }
    });
  }

  // 1. onRequest - fires when request is received (before parsing)
  // This hook MUST be active to track active requests for graceful shutdown
  app.addHook('onRequest', (req, reply, done) => {
    log.debug('>>> HOOK: onRequest fired for %s %s', req.method, req.url);
    activeRequestsCount += 1;

    // Set up stream event listeners for completion tracking
    // These act as fallbacks in case onResponse doesn't fire (e.g., abrupt disconnections)
    const http2Stream = (req.raw as { stream?: NodeJS.EventEmitter }).stream;

    reply.raw.on('close', () => {
      log.debug('>>> EVENT: reply.raw close');
      decrementRequestCount(req, 'reply.raw-close');
    });

    reply.raw.on('finish', () => {
      log.debug('>>> EVENT: reply.raw finish');
      decrementRequestCount(req, 'reply.raw-finish');
    });

    reply.raw.on('error', (err) => {
      log.debug('>>> EVENT: reply.raw error: %s', err?.message);
      decrementRequestCount(req, 'reply.raw-error');
    });

    req.raw.on('close', () => {
      log.debug('>>> EVENT: req.raw close');
      decrementRequestCount(req, 'req.raw-close');
    });

    req.raw.on('error', (err) => {
      log.debug('>>> EVENT: req.raw error: %s', err?.message);
      decrementRequestCount(req, 'req.raw-error');
    });

    if (http2Stream) {
      log.debug('>>> HTTP/2 stream detected, adding listeners');
      http2Stream.on('close', () => {
        log.debug('>>> EVENT: http2Stream close');
        decrementRequestCount(req, 'http2Stream-close');
      });
      http2Stream.on('error', (err: Error) => {
        log.debug('>>> EVENT: http2Stream error: %s', err?.message);
        decrementRequestCount(req, 'http2Stream-error');
      });
    } else {
      log.debug('>>> No HTTP/2 stream found on req.raw');
    }

    finished(reply.raw, { readable: false, writable: true }, (err) => {
      log.debug('>>> EVENT: stream.finished callback, error: %s', err?.message ?? 'none');
      decrementRequestCount(req, `stream.finished-${err ? 'error' : 'success'}`);
    });

    done();
  });

  // 2. preParsing - fires before parsing the request body
  app.addHook('preParsing', (req, _reply, payload, done) => {
    log.debug('>>> HOOK: preParsing fired for %s %s', req.method, req.url);
    done(null, payload);
  });

  // 3. preValidation - fires before validation
  app.addHook('preValidation', (req, _reply, done) => {
    log.debug('>>> HOOK: preValidation fired for %s %s', req.method, req.url);
    done();
  });

  // 4. preHandler - fires before the route handler
  app.addHook('preHandler', (req, _reply, done) => {
    log.debug('>>> HOOK: preHandler fired for %s %s', req.method, req.url);
    done();
  });

  // 5. preSerialization - fires before serializing the response
  app.addHook('preSerialization', (req, _reply, payload, done) => {
    log.debug('>>> HOOK: preSerialization fired for %s %s', req.method, req.url);
    done(null, payload);
  });

  // 6. onSend - fires before sending the response
  app.addHook('onSend', (req, _reply, payload, done) => {
    log.debug('>>> HOOK: onSend fired for %s %s', req.method, req.url);
    done(null, payload);
  });

  // 7. onResponse - fires after the response has been sent
  app.addHook('onResponse', (req, _reply, done) => {
    log.debug('>>> HOOK: onResponse fired for %s %s', req.method, req.url);
    decrementRequestCount(req, 'onResponse');
    done();
  });

  // 8. onError - fires when an error occurs
  app.addHook('onError', (req, _reply, error, done) => {
    log.debug('>>> HOOK: onError fired for %s %s, error: %s', req.method, req.url, error?.message);
    decrementRequestCount(req, 'onError');
    done();
  });

  // 9. onTimeout - fires when a request times out
  app.addHook('onTimeout', (req, _reply, done) => {
    log.debug('>>> HOOK: onTimeout fired for %s %s', req.method, req.url);
    decrementRequestCount(req, 'onTimeout');
    done();
  });

  // 10. onRequestAbort - fires when client aborts the request
  app.addHook('onRequestAbort', (req, done) => {
    log.debug('>>> HOOK: onRequestAbort fired for %s %s', req.method, req.url);
    decrementRequestCount(req, 'onRequestAbort');
    done();
  });
};

export default handleGracefulShutdown;
