const Honeybadger = require('honeybadger');
const Sentry = require('@sentry/node');

class ErrorReporter {
  constructor() {
    this.honeybadger = false;
    this.sentry = false;
  }

  addHoneybadgerApiKey(apiKey) {
    Honeybadger.configure({ apiKey });
    this.honeybadger = true;
  }

  addSentryDsn(sentryDsn) {
    Sentry.init({
      dsn: sentryDsn,
    });
    this.sentry = true;
  }

  setContext(context) {
    if (this.honeybadger) {
      Honeybadger.setConext(context);
    }
  }

  notify(msg, context = {}) {
    console.log('ErrorReporter postMessage', msg);
    if (this.honeybadger) {
      Honeybadger.notify(msg, context);
    }
    if (this.sentry) {
      Sentry.captureMessage(msg);
    }
  }
}

const errorReporter = new ErrorReporter();

module.exports = errorReporter;
