import { jest } from '@jest/globals';

jest.mock('@sentry/node');

import Sentry = require('@sentry/node');
import tracing = require('../../src/shared/tracing');

test('should run function and finish transaction', async () => {
  const finishMock = jest.fn();
  const fn = jest.fn<Parameters<typeof tracing.withinTransaction>[0]>();
  (Sentry.startTransaction as jest.Mock).mockReturnValue({ finish: finishMock });
  tracing.setSentry(Sentry);
  await tracing.withinTransaction(fn, 'sample', 'Sample');
  expect(finishMock.mock.calls).toHaveLength(1);
  expect(fn.mock.calls).toHaveLength(1);
});

test('should throw if inner function throws', async () => {
  const finishMock = jest.fn();
  (Sentry.startTransaction as jest.Mock).mockReturnValue({ finish: finishMock });
  tracing.setSentry(Sentry);
  await expect(async () => {
    await tracing.withinTransaction(
      () => {
        throw new Error();
      },
      'sample',
      'Sample',
    );
  }).rejects.toThrow();
  expect(finishMock.mock.calls).toHaveLength(1);
});
