import { getCurrentHub } from '@sentry/node';
import tracing from '../../src/shared/tracing';
import errorReporter from '../../src/shared/errorReporter';
import { buildConfig } from '../../src/shared/configBuilder';

// https://github.com/getsentry/sentry-javascript/blob/master/packages/node/test/index.test.ts#L17
const testDsn = 'https://53039209a22b4ec1bcc296a3c9fdecd6@sentry.io/4291';

// https://github.com/getsentry/sentry-go/issues/9#issuecomment-619615289
const isSentryInitialized = () => getCurrentHub().getClient() !== undefined;

describe('configBuilder', () => {
  beforeEach(() => {
    getCurrentHub().pushScope();
  });

  afterEach(() => {
    getCurrentHub().popScope();
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
