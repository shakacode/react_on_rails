/* eslint-disable react/jsx-filename-extension */

import * as React from 'react';
import ComponentRegistry from '../src/ComponentRegistry.ts';
import ReactOnRails from '../src/ReactOnRails.client.ts';

describe('Debug Logging', () => {
  let consoleLogSpy;

  beforeEach(() => {
    // Clear registries before each test
    ComponentRegistry.clear();

    // Reset options to defaults
    ReactOnRails.resetOptions();

    // Spy on console.log
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
  });

  afterEach(() => {
    // Restore console.log
    consoleLogSpy.mockRestore();
  });

  describe('logComponentRegistration option', () => {
    it('does not log when logComponentRegistration is false (default)', () => {
      const TestComponent = () => <div>Test</div>;

      ReactOnRails.register({ TestComponent });

      expect(consoleLogSpy).not.toHaveBeenCalled();
    });

    it('logs component registration when logComponentRegistration is true', () => {
      ReactOnRails.setOptions({ logComponentRegistration: true });

      const TestComponent = () => <div>Test</div>;
      ReactOnRails.register({ TestComponent });

      expect(consoleLogSpy).toHaveBeenCalledWith('[ReactOnRails] Component registration logging enabled');
      expect(consoleLogSpy).toHaveBeenCalledWith('[ReactOnRails] Registering 1 component(s): TestComponent');
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] Component registration completed in \d+\.\d+ms/),
      );
    });

    it('logs multiple components registration', () => {
      ReactOnRails.setOptions({ logComponentRegistration: true });

      const Component1 = () => <div>One</div>;
      const Component2 = () => <div>Two</div>;
      const Component3 = () => <div>Three</div>;

      ReactOnRails.register({ Component1, Component2, Component3 });

      expect(consoleLogSpy).toHaveBeenCalledWith(
        '[ReactOnRails] Registering 3 component(s): Component1, Component2, Component3',
      );
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] Component registration completed in \d+\.\d+ms/),
      );
    });

    it('measures registration timing using performance.now() when available', () => {
      ReactOnRails.setOptions({ logComponentRegistration: true });

      const TestComponent = () => <div>Test</div>;
      ReactOnRails.register({ TestComponent });

      // Verify timing was logged in milliseconds with 2 decimal places
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] Component registration completed in \d+\.\d{2}ms/),
      );
    });
  });

  describe('debugMode option', () => {
    it('does not log when debugMode is false (default)', () => {
      const TestComponent = () => <div>Test</div>;

      ReactOnRails.register({ TestComponent });

      expect(consoleLogSpy).not.toHaveBeenCalled();
    });

    it('logs when debugMode is enabled', () => {
      ReactOnRails.setOptions({ debugMode: true });

      expect(consoleLogSpy).toHaveBeenCalledWith('[ReactOnRails] Debug mode enabled');
    });

    it('logs component registration details when debugMode is true', () => {
      ReactOnRails.setOptions({ debugMode: true });

      const TestComponent = () => <div>Test</div>;
      ReactOnRails.register({ TestComponent });

      expect(consoleLogSpy).toHaveBeenCalledWith('[ReactOnRails] Registering 1 component(s): TestComponent');
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] Component registration completed in \d+\.\d+ms/),
      );
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] ✅ Registered: TestComponent \(\d+ chars\)/),
      );
    });

    it('logs individual component sizes in debug mode', () => {
      ReactOnRails.setOptions({ debugMode: true });

      const SmallComponent = () => <div>S</div>;
      const LargerComponent = () => (
        <div>
          <p>This is a larger component with more content</p>
          <p>And another paragraph to make it bigger</p>
        </div>
      );

      ReactOnRails.register({ SmallComponent, LargerComponent });

      // Check that individual component registrations are logged with size info
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] ✅ Registered: SmallComponent \(\d+ chars\)/),
      );
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] ✅ Registered: LargerComponent \(\d+ chars\)/),
      );
    });

    it('logs all registration info when both debugMode and logComponentRegistration are enabled', () => {
      ReactOnRails.setOptions({
        debugMode: true,
        logComponentRegistration: true,
      });

      const TestComponent = () => <div>Test</div>;
      ReactOnRails.register({ TestComponent });

      // Should log both general info and detailed component info
      expect(consoleLogSpy).toHaveBeenCalledWith('[ReactOnRails] Debug mode enabled');
      expect(consoleLogSpy).toHaveBeenCalledWith('[ReactOnRails] Component registration logging enabled');
      expect(consoleLogSpy).toHaveBeenCalledWith('[ReactOnRails] Registering 1 component(s): TestComponent');
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] Component registration completed in \d+\.\d+ms/),
      );
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] ✅ Registered: TestComponent \(\d+ chars\)/),
      );
    });
  });

  describe('performance fallback', () => {
    it('falls back to Date.now() when performance is not available', () => {
      // Save original performance object
      const originalPerformance = global.performance;

      // Remove performance temporarily
      delete global.performance;

      ReactOnRails.setOptions({ logComponentRegistration: true });

      const TestComponent = () => <div>Test</div>;
      ReactOnRails.register({ TestComponent });

      // Should still log timing information
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[ReactOnRails\] Component registration completed in \d+\.\d+ms/),
      );

      // Restore performance
      global.performance = originalPerformance;
    });
  });

  describe('option validation', () => {
    it('accepts valid debugMode option', () => {
      expect(() => ReactOnRails.setOptions({ debugMode: true })).not.toThrow();
      expect(() => ReactOnRails.setOptions({ debugMode: false })).not.toThrow();
    });

    it('accepts valid logComponentRegistration option', () => {
      expect(() => ReactOnRails.setOptions({ logComponentRegistration: true })).not.toThrow();
      expect(() => ReactOnRails.setOptions({ logComponentRegistration: false })).not.toThrow();
    });

    it('can retrieve options via option() method', () => {
      ReactOnRails.setOptions({ debugMode: true, logComponentRegistration: true });

      expect(ReactOnRails.option('debugMode')).toBe(true);
      expect(ReactOnRails.option('logComponentRegistration')).toBe(true);
    });

    it('resetOptions() resets debug options to defaults', () => {
      ReactOnRails.setOptions({ debugMode: true, logComponentRegistration: true });
      ReactOnRails.resetOptions();

      expect(ReactOnRails.option('debugMode')).toBe(false);
      expect(ReactOnRails.option('logComponentRegistration')).toBe(false);
    });
  });

  describe('non-intrusive logging', () => {
    it('does not affect component registration functionality', () => {
      ReactOnRails.setOptions({ debugMode: true, logComponentRegistration: true });

      const TestComponent = () => <div>Test</div>;
      ReactOnRails.register({ TestComponent });

      // Component should still be properly registered
      const registered = ReactOnRails.getComponent('TestComponent');
      expect(registered.name).toBe('TestComponent');
      expect(registered.component).toBe(TestComponent);
    });

    it('does not affect multiple component registration', () => {
      ReactOnRails.setOptions({ debugMode: true });

      const Comp1 = () => <div>1</div>;
      const Comp2 = () => <div>2</div>;
      const Comp3 = () => <div>3</div>;

      ReactOnRails.register({ Comp1, Comp2, Comp3 });

      // All components should be registered correctly
      expect(ReactOnRails.registeredComponents().size).toBe(3);
      expect(ReactOnRails.getComponent('Comp1').component).toBe(Comp1);
      expect(ReactOnRails.getComponent('Comp2').component).toBe(Comp2);
      expect(ReactOnRails.getComponent('Comp3').component).toBe(Comp3);
    });
  });

  describe('zero production impact', () => {
    it('has minimal overhead when debug options are disabled', () => {
      const TestComponent = () => <div>Test</div>;

      // Register without debug options
      const startTime = performance.now();
      ReactOnRails.register({ TestComponent });
      const endTime = performance.now();

      // No console logging should occur
      expect(consoleLogSpy).not.toHaveBeenCalled();

      // Registration should complete quickly (sanity check, not a strict performance test)
      expect(endTime - startTime).toBeLessThan(100);
    });
  });
});
