import { jest } from '@jest/globals';

import * as Sentry from '@sentry/node';
import sentryTestkit from 'sentry-testkit';
import * as errorReporter from '../../src/shared/errorReporter';
import { trace } from '../../src/shared/tracing';
import * as tracingIntegration from '../../src/integrations/sentry';

const { testkit, sentryTransport } = sentryTestkit();

Sentry.init({
  dsn: 'https://fakeUser@fakeDsn.ingest.sentry.io/0',
  tracesSampleRate: 1.0,
  transport: sentryTransport,
});

tracingIntegration.init({ tracing: true });

const spanName = 'TestSpan';
const testTransactionContext = { sentry: { op: 'test', name: spanName } };

beforeEach(() => {
  testkit.reset();
});

test('should run function and finish span', async () => {
  const fn = jest.fn<Parameters<typeof trace>[0]>();
  let savedSpan: Sentry.Span | undefined;
  const message = 'test';
  await trace(async () => {
    savedSpan = Sentry.getActiveSpan();
    errorReporter.message(message);
    await fn();
  }, testTransactionContext);
  expect(savedSpan).toBeDefined();
  // eslint-disable-next-line @typescript-eslint/no-deprecated -- the suggested replacement doesn't work
  expect(savedSpan?.name).toBe(spanName);
  expect(Sentry.getActiveSpan()).not.toBe(savedSpan);
  expect(fn.mock.calls).toHaveLength(1);

  await Sentry.flush();
  const transactions = testkit.transactions();
  expect(transactions).toHaveLength(1);
  const transaction = transactions[0]!;
  expect(transaction.name).toBe(spanName);
  const reports = testkit.reports();
  expect(reports).toHaveLength(1);
  const report = reports[0]!;
  // Note: Sentry v10 no longer sets report.tags.transaction automatically.
  // Remove this assertion when upgrading devDependency.
  expect(report.tags.transaction).toBe(spanName);
  expect(report.message).toBe(message);
});

test('should throw if inner function throws', async () => {
  let savedSpan: Sentry.Span | undefined;
  await expect(async () => {
    await trace(() => {
      savedSpan = Sentry.getActiveSpan();
      throw new Error();
    }, testTransactionContext);
  }).rejects.toThrow();
  expect(Sentry.getActiveSpan()).not.toBe(savedSpan);
});
