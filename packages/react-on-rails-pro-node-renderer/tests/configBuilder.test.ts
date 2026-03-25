describe('configBuilder', () => {
  const originalRendererHost = process.env.RENDERER_HOST;
  const originalNodeEnv = process.env.NODE_ENV;
  const originalRendererPassword = process.env.RENDERER_PASSWORD;
  const originalRailsEnv = process.env.RAILS_ENV;

  afterEach(() => {
    if (originalRendererHost === undefined) {
      delete process.env.RENDERER_HOST;
    } else {
      process.env.RENDERER_HOST = originalRendererHost;
    }
    if (originalNodeEnv === undefined) {
      delete process.env.NODE_ENV;
    } else {
      process.env.NODE_ENV = originalNodeEnv;
    }
    if (originalRendererPassword === undefined) {
      delete process.env.RENDERER_PASSWORD;
    } else {
      process.env.RENDERER_PASSWORD = originalRendererPassword;
    }
    if (originalRailsEnv === undefined) {
      delete process.env.RAILS_ENV;
    } else {
      process.env.RAILS_ENV = originalRailsEnv;
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

  function mockProcessExit() {
    return jest.spyOn(process, 'exit').mockImplementation(((code?: number) => {
      throw new Error(`process.exit: ${code ?? 0}`);
    }) as never);
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

  describe('password validation in production-like environments', () => {
    it('throws when no password is set in production', () => {
      process.env.NODE_ENV = 'production';
      delete process.env.RENDERER_PASSWORD;
      const processExit = mockProcessExit();

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).toThrow('process.exit: 1');
      expect(processExit).toHaveBeenCalledWith(1);
    });

    it('throws when no password is set in staging', () => {
      process.env.NODE_ENV = 'staging';
      delete process.env.RENDERER_PASSWORD;
      const processExit = mockProcessExit();

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).toThrow('process.exit: 1');
      expect(processExit).toHaveBeenCalledWith(1);
    });

    it('does not throw when password is set via env in production', () => {
      process.env.NODE_ENV = 'production';
      process.env.RENDERER_PASSWORD = 'secure-password';

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).not.toThrow();
    });

    it('does not throw when password is set via config in production', () => {
      process.env.NODE_ENV = 'production';
      delete process.env.RENDERER_PASSWORD;

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig({ password: 'secure-password' })).not.toThrow();
    });

    it('does not throw in development without a password', () => {
      process.env.NODE_ENV = 'development';
      delete process.env.RENDERER_PASSWORD;

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).not.toThrow();
    });

    it('does not throw in test without a password', () => {
      process.env.NODE_ENV = 'test';
      delete process.env.RENDERER_PASSWORD;

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).not.toThrow();
    });

    it('throws when RAILS_ENV is production even if NODE_ENV is development', () => {
      process.env.NODE_ENV = 'development';
      process.env.RAILS_ENV = 'production';
      delete process.env.RENDERER_PASSWORD;
      const processExit = mockProcessExit();

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).toThrow('process.exit: 1');
      expect(processExit).toHaveBeenCalledWith(1);
    });

    it('throws when RAILS_ENV is production and NODE_ENV is unset', () => {
      delete process.env.NODE_ENV;
      process.env.RAILS_ENV = 'production';
      delete process.env.RENDERER_PASSWORD;
      const processExit = mockProcessExit();

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).toThrow('process.exit: 1');
      expect(processExit).toHaveBeenCalledWith(1);
    });

    it('throws when NODE_ENV is staging even if RAILS_ENV is development', () => {
      process.env.NODE_ENV = 'staging';
      process.env.RAILS_ENV = 'development';
      delete process.env.RENDERER_PASSWORD;
      const processExit = mockProcessExit();

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).toThrow('process.exit: 1');
      expect(processExit).toHaveBeenCalledWith(1);
    });

    it('throws when RAILS_ENV is production even if NODE_ENV is test', () => {
      process.env.NODE_ENV = 'test';
      process.env.RAILS_ENV = 'production';
      delete process.env.RENDERER_PASSWORD;
      const processExit = mockProcessExit();

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).toThrow('process.exit: 1');
      expect(processExit).toHaveBeenCalledWith(1);
    });

    it('does not throw when RAILS_ENV is development and NODE_ENV is development', () => {
      process.env.NODE_ENV = 'development';
      process.env.RAILS_ENV = 'development';
      delete process.env.RENDERER_PASSWORD;

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).not.toThrow();
    });

    it('throws when neither NODE_ENV nor RAILS_ENV is set (fail-closed)', () => {
      delete process.env.NODE_ENV;
      delete process.env.RAILS_ENV;
      delete process.env.RENDERER_PASSWORD;
      const processExit = mockProcessExit();

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig()).toThrow('process.exit: 1');
      expect(processExit).toHaveBeenCalledWith(1);
    });

    it('does not throw when password is set after module import', () => {
      process.env.NODE_ENV = 'production';
      delete process.env.RENDERER_PASSWORD;

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      process.env.RENDERER_PASSWORD = 'late-loaded-password';

      expect(() => buildConfig()).not.toThrow();
    });

    it('does not treat undefined user password as override when env password exists', () => {
      process.env.NODE_ENV = 'production';
      process.env.RENDERER_PASSWORD = 'late-loaded-password';

      const { buildConfig } = loadConfigBuilderWithMockedLogger();

      expect(() => buildConfig({ password: undefined })).not.toThrow();
    });
  });
});
