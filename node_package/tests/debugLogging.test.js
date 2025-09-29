import React from 'react';

describe('ReactOnRails debug logging', () => {
  let ReactOnRails;
  let originalConsoleLog;
  let consoleOutput;

  beforeEach(() => {
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

    // Import ReactOnRails after mocking
    ReactOnRails = require('../src/ReactOnRails.client.ts');
  });

  afterEach(() => {
    console.log = originalConsoleLog;
    jest.clearAllMocks();
  });

  describe('component registration logging', () => {
    it('logs nothing when debug options are disabled', () => {
      const TestComponent = () => React.createElement('div', null, 'Test');
      
      globalThis.ReactOnRails.register({ TestComponent });
      
      expect(consoleOutput).toHaveLength(0);
    });

    it('logs component registration when logComponentRegistration is enabled', () => {
      const TestComponent = () => React.createElement('div', null, 'Test');
      const AnotherComponent = () => React.createElement('div', null, 'Another');
      
      globalThis.ReactOnRails.setOptions({ logComponentRegistration: true });
      globalThis.ReactOnRails.register({ TestComponent, AnotherComponent });
      
      expect(consoleOutput).toContain('[ReactOnRails] Component registration logging enabled');
      expect(consoleOutput.some(log => log.includes('Registering 2 component(s)'))).toBe(true);
      expect(consoleOutput.some(log => log.includes('TestComponent'))).toBe(true);
      expect(consoleOutput.some(log => log.includes('AnotherComponent'))).toBe(true);
      expect(consoleOutput.some(log => log.includes('completed in'))).toBe(true);
    });

    it('logs detailed information when debugMode is enabled', () => {
      const TestComponent = () => React.createElement('div', null, 'Test');
      
      globalThis.ReactOnRails.setOptions({ debugMode: true });
      globalThis.ReactOnRails.register({ TestComponent });
      
      expect(consoleOutput).toContain('[ReactOnRails] Debug mode enabled');
      expect(consoleOutput.some(log => log.includes('✅ Registered: TestComponent'))).toBe(true);
      expect(consoleOutput.some(log => log.includes('kb)'))).toBe(true);
    });

    it('logs registration timing information', () => {
      const Component1 = () => React.createElement('div', null, '1');
      const Component2 = () => React.createElement('div', null, '2');
      const Component3 = () => React.createElement('div', null, '3');
      
      globalThis.ReactOnRails.setOptions({ logComponentRegistration: true });
      globalThis.ReactOnRails.register({ Component1, Component2, Component3 });
      
      const timingLog = consoleOutput.find(log => log.includes('completed in'));
      expect(timingLog).toBeDefined();
      expect(timingLog).toMatch(/completed in \d+\.\d+ms/);
    });
  });

  describe('setOptions', () => {
    it('accepts debugMode option', () => {
      expect(() => {
        globalThis.ReactOnRails.setOptions({ debugMode: true });
      }).not.toThrow();
      
      expect(globalThis.ReactOnRails.options.debugMode).toBe(true);
    });

    it('accepts logComponentRegistration option', () => {
      expect(() => {
        globalThis.ReactOnRails.setOptions({ logComponentRegistration: true });
      }).not.toThrow();
      
      expect(globalThis.ReactOnRails.options.logComponentRegistration).toBe(true);
    });

    it('can set multiple debug options', () => {
      globalThis.ReactOnRails.setOptions({ 
        debugMode: true,
        logComponentRegistration: true 
      });
      
      expect(globalThis.ReactOnRails.options.debugMode).toBe(true);
      expect(globalThis.ReactOnRails.options.logComponentRegistration).toBe(true);
    });

    it('logs when debug options are enabled', () => {
      globalThis.ReactOnRails.setOptions({ debugMode: true });
      expect(consoleOutput).toContain('[ReactOnRails] Debug mode enabled');
      
      consoleOutput = [];
      globalThis.ReactOnRails.setOptions({ logComponentRegistration: true });
      expect(consoleOutput).toContain('[ReactOnRails] Component registration logging enabled');
    });
  });
});