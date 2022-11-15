const requireOptional = require('../shared/requireOptional');
const log = require('./log');

const Honeybadger = requireOptional('@honeybadger-io/js');
const Sentry = requireOptional('@sentry/node');
const SentryTracing = requireOptional('@sentry/tracing');

class ErrorReporter {
  constructor() {
    this.honeybadger = false;
    this.sentry = false;
  }

  reportingServices() {
    if (this.sentry && this.honeybadger) {
      return ['sentry', 'honeybadger'];
    }

    if (this.sentry) {
      return ['sentry'];
    }

    if (this.honeybadger) {
      return ['honeybadger'];
    }

    return null;
  }

  addHoneybadgerApiKey(apiKey) {
    if (Honeybadger === null) {
      log.error(
        'Honeybadger package is not installed. Either install it in order to use error reporting with Honeybadger or remove the honeybadgerApiKey from your config.',
      );
    } else {
      Honeybadger.configure({ apiKey });
      this.honeybadger = true;
    }
  }

  addSentryDsn(sentryDsn, options = {}) {
    if (Sentry === null) {
      log.error(
        '@sentry/node package is not installed. Either install it in order to use error reporting with Sentry or remove the sentryDsn from your config.',
      );
    } else {
      let sentryOptions = {
        dsn: sentryDsn,
      };

      if (options.tracing) {
        if (SentryTracing === null) {
          log.error(
            '@sentry/tracing package is not installed. Either install it in order to use error reporting with Sentry or set config sentryTracing to false.',
          );
        } else {
          sentryOptions = {
            ...sentryOptions,
            integrations: [
              // enable HTTP calls tracing
              new Sentry.Integrations.Http({ tracing: true }),
            ],

            // We recommend adjusting this value in production, or using tracesSampler
            // for finer control
            tracesSampleRate: options.tracesSampleRate,
          };
        }
      }
      Sentry.init(sentryOptions);
      this.sentry = true;
    }
  }

  setContext(context) {
    if (this.honeybadger) {
      Honeybadger.setContext(context);
    }
  }

  notify(msg, context = {}, scopeFn = undefined) {
    log.error(`ErrorReporter notification: ${msg}`);
    if (this.honeybadger) {
      Honeybadger.notify(msg, context);
    }
    if (this.sentry) {
      Sentry.captureMessage(msg, scopeFn);
    }
  }
}

const errorReporter = new ErrorReporter();

module.exports = errorReporter;
