import * as Sentry from '@sentry/node';
import { StartSpanOptions } from '@sentry/types';
import {
  addErrorNotifier,
  addMessageNotifier,
  message,
  setupTracing,
  configureFastify,
  FastifyConfigFunction,
} from './api';

declare module '../shared/tracing' {
  interface UnitOfWorkOptions {
    sentry?: StartSpanOptions;
  }
}

export function init({ fastify = false, tracing = false } = {}) {
  addMessageNotifier((msg) => {
    Sentry.captureMessage(msg);
  });

  addErrorNotifier((msg) => {
    Sentry.captureException(msg);
  });

  if (tracing) {
    setupTracing({
      startSsrRequestOptions: () => ({
        sentry: {
          op: 'handleRenderRequest',
          name: 'SSR Request',
        },
      }),
      executor: (fn, unitOfWorkOptions) =>
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        Sentry.startSpan(unitOfWorkOptions.sentry!, () => fn()),
    });
  }

  if (fastify) {
    // The check and the cast can be removed if/when we require Sentry SDK v8
    if ('setupFastifyErrorHandler' in Sentry) {
      configureFastify(Sentry.setupFastifyErrorHandler as FastifyConfigFunction);
    } else {
      message('Please upgrade to Sentry SDK v8 to use Fastify integration');
    }
  }
}
