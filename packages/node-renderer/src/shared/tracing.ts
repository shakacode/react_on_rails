import type { Transaction } from '@sentry/types';
import requireOptional from './requireOptional';
import log from './log';

type SentryModule = typeof import('@sentry/node');
const sentryTracing = requireOptional('@sentry/tracing');

class Tracing {
  Sentry: null | SentryModule;

  constructor() {
    this.Sentry = null;
  }

  tracingServices() {
    if (this.Sentry) {
      return ['sentry'];
    }

    return null;
  }

  setSentry(Sentry: SentryModule) {
    if (sentryTracing === null) {
      log.error(
        '@sentry/tracing package is not installed. Either install it in order to use tracing with Sentry or set sentryTracing to false in your config.',
      );
    } else {
      this.Sentry = Sentry;
    }
  }

  async withinTransaction<T>(fn: (transaction?: Transaction) => Promise<T>, op: string, name: string) {
    if (this.Sentry === null) {
      return fn();
    }
    const transaction = this.Sentry.startTransaction({
      op,
      name,
    });
    try {
      return await fn(transaction);
    } finally {
      transaction.finish();
    }
  }
}

const tracing = new Tracing();

export = tracing;
