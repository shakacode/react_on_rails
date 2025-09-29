import React from 'react';

describe('ReactOnRails debug logging', () => {
  let originalConsoleLog;
  let consoleOutput;

  beforeEach(async () => {
    // Reset modules to get fresh instance
    jest.resetModules();

    // Mock console.log to capture output
    consoleOutput = [];
    originalConsoleLog = console.log;
    console.log = jest.fn((...args) => {
      consoleOutput.push(args.join(' '));
    });

    // Mock the necessary dependencies
    jest.mock('../src/clientStartup.ts', () => ({
      clientStartup: jest.fn(),
      reactOnRailsPageLoaded: jest.fn(),
    }));

    jest.mock('../src/pro/ClientSideRenderer.ts', () => ({
      renderOrHydrateComponent: jest.fn(),
      hydrateStore: jest.fn(),
    }));

    jest.mock('../src/pro/ComponentRegistry.ts', () => ({
      register: jest.fn(),
      get: jest.fn(),
      getOrWaitForComponent: jest.fn(),
      components: jest.fn(() => new Map()),
    }));

    jest.mock('../src/pro/StoreRegistry.ts', () => ({
      register: jest.fn(),
      getStore: jest.fn(),
      getOrWaitForStore: jest.fn(),
      getOrWaitForStoreGenerator: jest.fn(),
    }));

    // Import ReactOnRails after mocking using dynamic import
    await import('../src/ReactOnRails.client.ts');
  });

  afterEach(() => {
    console.log = originalConsoleLog;
    jest.clearAllMocks();
  });

  describe('component registration logging', () => {
    it('logs nothing when debug options are disabled', () => {
      const TestComponent = () => React.createElement('div', null, 'Test');

      window.ReactOnRails.register({ TestComponent });

      expect(consoleOutput).toHaveLength(0);
    });

    it('logs component registration when logComponentRegistration is enabled', () => {
      const TestComponent = () => React.createElement('div', null, 'Test');
      const AnotherComponent = () => React.createElement('div', null, 'Another');

      window.ReactOnRails.setOptions({ logComponentRegistration: true });
      window.ReactOnRails.register({ TestComponent, AnotherComponent });

      expect(consoleOutput).toContain('[ReactOnRails] Component registration logging enabled');
      expect(consoleOutput.some((log) => log.includes('Registering 2 component(s)'))).toBe(true);
      expect(consoleOutput.some((log) => log.includes('TestComponent'))).toBe(true);
      expect(consoleOutput.some((log) => log.includes('AnotherComponent'))).toBe(true);
      expect(consoleOutput.some((log) => log.includes('completed in'))).toBe(true);
    });

    it('logs detailed information when debugMode is enabled', () => {
      const TestComponent = () => React.createElement('div', null, 'Test');

      window.ReactOnRails.setOptions({ debugMode: true });
      window.ReactOnRails.register({ TestComponent });

      expect(consoleOutput).toContain('[ReactOnRails] Debug mode enabled');
      expect(consoleOutput.some((log) => log.includes('✅ Registered: TestComponent'))).toBe(true);
      expect(consoleOutput.some((log) => log.includes('kb)'))).toBe(true);
    });

    it('logs registration timing information', () => {
      const Component1 = () => React.createElement('div', null, '1');
      const Component2 = () => React.createElement('div', null, '2');
      const Component3 = () => React.createElement('div', null, '3');

      window.ReactOnRails.setOptions({ logComponentRegistration: true });
      window.ReactOnRails.register({ Component1, Component2, Component3 });

      const timingLog = consoleOutput.find((log) => log.includes('completed in'));
      expect(timingLog).toBeDefined();
      expect(timingLog).toMatch(/completed in \d+\.\d+ms/);
    });
  });

  describe('setOptions', () => {
    it('accepts debugMode option', () => {
      expect(() => {
        window.ReactOnRails.setOptions({ debugMode: true });
      }).not.toThrow();

      expect(window.ReactOnRails.options.debugMode).toBe(true);
    });

    it('accepts logComponentRegistration option', () => {
      expect(() => {
        window.ReactOnRails.setOptions({ logComponentRegistration: true });
      }).not.toThrow();

      expect(window.ReactOnRails.options.logComponentRegistration).toBe(true);
    });

    it('can set multiple debug options', () => {
      window.ReactOnRails.setOptions({
        debugMode: true,
        logComponentRegistration: true,
      });

      expect(window.ReactOnRails.options.debugMode).toBe(true);
      expect(window.ReactOnRails.options.logComponentRegistration).toBe(true);
    });

    it('logs when debug options are enabled', () => {
      window.ReactOnRails.setOptions({ debugMode: true });
      expect(consoleOutput).toContain('[ReactOnRails] Debug mode enabled');

      consoleOutput = [];
      window.ReactOnRails.setOptions({ logComponentRegistration: true });
      expect(consoleOutput).toContain('[ReactOnRails] Component registration logging enabled');
    });
  });
});
