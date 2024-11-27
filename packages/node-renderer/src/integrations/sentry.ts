import { captureException, captureMessage, startSpan } from '@sentry/node';
import { StartSpanOptions } from '@sentry/types';
import { addErrorNotifier, addMessageNotifier } from '../shared/errorReporter';
import { setupTracing } from '../shared/tracing';

declare module '../shared/tracing' {
  interface UnitOfWorkOptions {
    sentry?: StartSpanOptions;
  }
}

export function init({ tracing = false } = {}) {
  addMessageNotifier((msg) => {
    captureMessage(msg);
  });

  addErrorNotifier((msg) => {
    captureException(msg);
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
        startSpan(unitOfWorkOptions.sentry!, () => fn()),
    });
  }
}
