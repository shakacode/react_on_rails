const requireOptional = require('./requireOptional');

const sentryTracing = requireOptional('@sentry/tracing');
class Tracing {
  constructor() {
    this.Sentry = null;
  }

  tracingServices() {
    if (this.Sentry) {
      return ['sentry'];
    }

    return null;
  }

  setSentry(Sentry) {
    if (sentryTracing === null) {
      throw new Error(
        '@sentry/tracing package is not installed. Either install it in order to use tracing with Sentry or remove the sentryTracing from your config.',
      );
    }
    this.Sentry = Sentry;
  }

  async withinTransaction(fn, op, name) {
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

module.exports = tracing;
