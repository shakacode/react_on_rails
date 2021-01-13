const Sentry = require('@sentry/node');
const tracing = require('../../src/shared/tracing');
const errorReporter = require('../../src/shared/errorReporter');
const { buildConfig } = require('../../src/shared/configBuilder');

// https://github.com/getsentry/sentry-javascript/blob/master/packages/node/test/index.test.ts#L17
const testDsn = 'https://53039209a22b4ec1bcc296a3c9fdecd6@sentry.io/4291';

// https://github.com/getsentry/sentry-go/issues/9#issuecomment-619615289
const isSentryInitialized = () => Sentry.getCurrentHub().getClient() !== undefined;

describe('configBuilder', () => {
  beforeEach(() => {
    Sentry.getCurrentHub().pushScope();
  });

  afterEach(() => {
    Sentry.getCurrentHub().popScope();
  });

  test('should enable error catching with sentry', () => {
    expect(isSentryInitialized()).toBe(false);
    buildConfig({
      sentryDsn: testDsn,
    });
    expect(isSentryInitialized()).toBe(true);
    expect(errorReporter.reportingServices()).toContain('sentry');
  });

  test('should enable tracing with sentry', () => {
    expect(isSentryInitialized()).toBe(false);
    buildConfig({
      sentryDsn: testDsn,
      sentryTracing: true,
    });
    expect(isSentryInitialized()).toBe(true);
    expect(errorReporter.reportingServices()).toContain('sentry');
    expect(tracing.tracingServices()).toContain('sentry');
  });
});
