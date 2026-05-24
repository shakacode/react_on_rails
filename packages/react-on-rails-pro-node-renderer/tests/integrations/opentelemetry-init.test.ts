import { jest } from '@jest/globals';

describe('opentelemetry integration: init() failure path', () => {
  beforeEach(() => {
    jest.resetModules();
  });

  test('init() catches missing-peer-dep import error and returns without throwing', async () => {
    // Mock the SDK import to throw, simulating a missing peer dep at runtime.
    jest.doMock('@opentelemetry/sdk-trace-node', () => {
      throw new Error('Cannot find module @opentelemetry/sdk-trace-node');
    });

    const errorReporter = await import('../../src/shared/errorReporter');
    const messageSpy = jest.spyOn(errorReporter, 'message');

    // Importing the integration itself must not throw even though the SDK throws.
    // The integration defers the require to inside init().
    const otel = await import('../../src/integrations/opentelemetry');
    expect(() => otel.init()).not.toThrow();
    expect(messageSpy).toHaveBeenCalledWith(expect.stringContaining('[OpenTelemetry] init failed'));
  });

  test('the integration module itself can be imported with no @opentelemetry/* packages loaded', async () => {
    // Importing the integration should never trigger require() of any OTel SDK package.
    // This test confirms the type-only imports stay erased at runtime and the integration
    // is safe to import in environments where the OTel peer deps are missing.
    jest.doMock('@opentelemetry/sdk-trace-node', () => {
      throw new Error('should not be required at import time');
    });
    jest.doMock('@opentelemetry/api', () => {
      throw new Error('should not be required at import time');
    });
    jest.doMock('@opentelemetry/sdk-trace-base', () => {
      throw new Error('should not be required at import time');
    });

    // This import should succeed without triggering any of the mocked throws.
    await expect(import('../../src/integrations/opentelemetry')).resolves.toBeDefined();
  });
});
