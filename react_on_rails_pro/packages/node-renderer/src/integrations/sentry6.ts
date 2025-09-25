/* eslint-disable @typescript-eslint/no-deprecated */
import { captureException, captureMessage, startTransaction } from '@sentry/node';
import { CaptureContext, TransactionContext } from '@sentry/types';
import { addErrorNotifier, addMessageNotifier, message, setupTracing } from './api';

declare module '../shared/tracing' {
  interface TracingContext {
    sentry6?: CaptureContext;
  }

  interface UnitOfWorkOptions {
    sentry6?: TransactionContext;
  }
}

export function init({ tracing = false } = {}) {
  addMessageNotifier((msg, tracingContext) => {
    captureMessage(msg, tracingContext?.sentry6);
  });

  addErrorNotifier((msg, tracingContext) => {
    captureException(msg, tracingContext?.sentry6);
  });

  if (tracing) {
    try {
      // eslint-disable-next-line global-require,import/no-unresolved,@typescript-eslint/no-require-imports -- Intentionally absent in our devDependencies
      require('@sentry/tracing');
    } catch (_e) {
      message("Failed to load '@sentry/tracing'. Tracing is disabled.");
      return;
    }

    setupTracing({
      startSsrRequestOptions: () => ({
        sentry6: {
          op: 'handleRenderRequest',
          name: 'SSR Request',
        },
      }),
      executor: async (fn, unitOfWorkOptions) => {
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        const transaction = startTransaction(unitOfWorkOptions.sentry6!);
        try {
          return await fn({ sentry6: (scope) => scope.setSpan(transaction) });
        } finally {
          transaction.finish();
        }
      },
    });
  }
}
