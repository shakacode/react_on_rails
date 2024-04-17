import type { Types } from '@honeybadger-io/js/dist/server/honeybadger';
import type { CaptureContext } from '@sentry/types';
import { NodeOptions } from '@sentry/node/dist/backend';
import requireOptional from './requireOptional';
import log from './log';

const Honeybadger = requireOptional('@honeybadger-io/js') as typeof import('@honeybadger-io/js') | null;
const Sentry = requireOptional('@sentry/node') as typeof import('@sentry/node') | null;
const SentryTracing = requireOptional('@sentry/tracing');

class ErrorReporter {
  honeybadger: boolean;
  sentry: boolean;

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

  addHoneybadgerApiKey(apiKey: string) {
    if (Honeybadger === null) {
      log.error(
        'Honeybadger package is not installed. Either install it in order to use error reporting with Honeybadger or remove the honeybadgerApiKey from your config.',
      );
    } else {
      Honeybadger.configure({ apiKey });
      this.honeybadger = true;
    }
  }

  addSentryDsn(sentryDsn: string, options: { tracing?: boolean; tracesSampleRate?: number } = {}) {
    if (Sentry === null) {
      log.error(
        '@sentry/node package is not installed. Either install it in order to use error reporting with Sentry or remove the sentryDsn from your config.',
      );
    } else {
      let sentryOptions: NodeOptions = {
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

  setContext(context: Record<string, unknown>) {
    if (this.honeybadger) {
      Honeybadger?.setContext(context);
    }
  }

  notify(
    msg: string | Error,
    context: Partial<Types.Notice> = {},
    scopeFn: CaptureContext | undefined = undefined,
  ) {
    log.error(`ErrorReporter notification: ${msg}`);
    if (this.honeybadger) {
      Honeybadger?.notify(msg, context);
    }
    if (this.sentry) {
      if (typeof msg === 'string') {
        Sentry?.captureMessage(msg, scopeFn);
      } else {
        Sentry?.captureException(msg, scopeFn);
      }
    }
  }
}

const errorReporter = new ErrorReporter();

export = errorReporter;
