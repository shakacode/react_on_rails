describe('configBuilder', () => {
  const originalRendererHost = process.env.RENDERER_HOST;

  afterEach(() => {
    if (originalRendererHost === undefined) {
      delete process.env.RENDERER_HOST;
    } else {
      process.env.RENDERER_HOST = originalRendererHost;
    }
    jest.restoreAllMocks();
    jest.resetModules();
  });

  function loadConfigBuilderWithMockedLogger() {
    const info = jest.fn();
    jest.doMock('../src/shared/log', () => ({
      __esModule: true,
      default: {
        info,
        error: jest.fn(),
        warn: jest.fn(),
        fatal: jest.fn(),
      },
    }));
    const { buildConfig, logSanitizedConfig } = jest.requireActual('../src/shared/configBuilder');
    return { buildConfig, logSanitizedConfig, info };
  }

  function envValuesUsedForRenderedConfig(userConfig: { host?: string }) {
    const { buildConfig, logSanitizedConfig, info } = loadConfigBuilderWithMockedLogger();

    buildConfig(userConfig);
    logSanitizedConfig();

    const logPayload = info.mock.calls[0][0] as Record<string, unknown>;
    return logPayload['ENV values used for settings (use "RENDERER_" prefix)'] as Record<string, unknown>;
  }

  it('marks RENDERER_HOST as env-provided when host is omitted from user config', () => {
    process.env.RENDERER_HOST = '0.0.0.0';

    const envValues = envValuesUsedForRenderedConfig({});

    expect(envValues.RENDERER_HOST).toBe('0.0.0.0');
  });

  it('does not mark RENDERER_HOST as env-provided when host key exists in user config', () => {
    process.env.RENDERER_HOST = '0.0.0.0';

    const envValues = envValuesUsedForRenderedConfig({ host: '' });

    expect(envValues.RENDERER_HOST).toBe(false);
  });
});
