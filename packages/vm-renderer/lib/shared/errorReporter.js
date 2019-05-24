const Honeybadger = require('honeybadger');

class ErrorReporter {
  constructor() {
    this.honeybadger = false;
  }

  addHoneybadgerApiKey(apiKey) {
    Honeybadger.configure({ apiKey });
    this.honeybadger = true;
  }

  addSentryDsn(_sentryDsn) {
    this.sentry = true;
    throw new Error('Sentry is not yet supported.');
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
  }
}

const errorReporter = new ErrorReporter();

module.exports = errorReporter;
