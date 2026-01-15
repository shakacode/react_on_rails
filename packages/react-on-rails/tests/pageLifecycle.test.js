/**
 * @jest-environment jsdom
 */

// Mock the turbolinksUtils module before importing pageLifecycle
jest.mock('../src/turbolinksUtils.ts', () => ({
  debugTurbolinks: jest.fn(),
  turbolinksInstalled: jest.fn(() => false),
  turbolinksSupported: jest.fn(() => false),
  turboInstalled: jest.fn(() => false),
  turbolinksVersion5: jest.fn(() => false),
}));

// Import will be done dynamically in tests to allow module reset

describe('pageLifecycle', () => {
  let originalReadyState;
  let addEventListenerSpy;
  let removeEventListenerSpy;

  // Helper function to set document.readyState
  const setReadyState = (state) => {
    Object.defineProperty(document, 'readyState', {
      value: state,
      writable: true,
    });
  };

  // We use require here instead of a global import at the top because we need to dynamically reload the module in each test.
  // This allows us to reset the module state between tests using jest.resetModules(), ensuring test isolation and preventing state leakage.
  // eslint-disable-next-line global-require
  const importPageLifecycle = () => require('../src/pageLifecycle.ts');

  // Helper function to create navigation library mock
  const createNavigationMock = (overrides = {}) => ({
    debugTurbolinks: jest.fn(),
    turbolinksInstalled: jest.fn(() => false),
    turbolinksSupported: jest.fn(() => false),
    turboInstalled: jest.fn(() => false),
    turbolinksVersion5: jest.fn(() => false),
    ...overrides,
  });

  beforeEach(() => {
    // Store the original readyState
    originalReadyState = document.readyState;

    // Mock document.addEventListener and removeEventListener
    addEventListenerSpy = jest.spyOn(document, 'addEventListener').mockImplementation(() => {});
    removeEventListenerSpy = jest.spyOn(document, 'removeEventListener').mockImplementation(() => {});

    // Reset DOM state - use Object.defineProperty to set readyState
    setReadyState('loading');

    // Reset all global state by reloading the module AFTER setting up mocks
    jest.resetModules();
  });

  afterEach(() => {
    // Restore original readyState
    Object.defineProperty(document, 'readyState', {
      value: originalReadyState,
      writable: true,
    });

    // Restore spies
    addEventListenerSpy.mockRestore();
    removeEventListenerSpy.mockRestore();
  });

  it('should initialize page event listeners immediately when document.readyState is "complete"', () => {
    setReadyState('complete');
    const callback = jest.fn();
    const { onPageLoaded } = importPageLifecycle();

    onPageLoaded(callback);

    // Since no navigation library is mocked, callbacks should run immediately
    expect(callback).toHaveBeenCalledTimes(1);
    // Should not add DOMContentLoaded listener since readyState is not 'loading'
    expect(addEventListenerSpy).not.toHaveBeenCalledWith('DOMContentLoaded', expect.any(Function));
  });

  it('should wait for DOMContentLoaded when when document.readyState is "interactive"', () => {
    setReadyState('interactive');
    const callback = jest.fn();
    const { onPageLoaded } = importPageLifecycle();

    onPageLoaded(callback);

    // Should not call callback immediately since readyState is 'loading'
    expect(callback).not.toHaveBeenCalled();
    // Verify that a DOMContentLoaded listener was added when readyState is 'loading'
    expect(addEventListenerSpy).toHaveBeenCalledWith('DOMContentLoaded', expect.any(Function));
  });

  it('should wait for DOMContentLoaded when document.readyState is "loading"', () => {
    setReadyState('loading');
    const callback = jest.fn();
    const { onPageLoaded } = importPageLifecycle();

    onPageLoaded(callback);

    // Should not call callback immediately since readyState is 'loading'
    expect(callback).not.toHaveBeenCalled();
    // Verify that a DOMContentLoaded listener was added when readyState is 'loading'
    expect(addEventListenerSpy).toHaveBeenCalledWith('DOMContentLoaded', expect.any(Function));
  });

  describe('with Turbo navigation library', () => {
    beforeEach(() => {
      jest.doMock('../src/turbolinksUtils.ts', () =>
        createNavigationMock({
          turboInstalled: jest.fn(() => true),
        }),
      );
    });

    afterEach(() => {
      jest.dontMock('../src/turbolinksUtils.ts');
    });

    it('should set up Turbo event listeners when Turbo is installed', () => {
      setReadyState('complete');
      const { onPageLoaded } = importPageLifecycle();
      const callback = jest.fn();

      onPageLoaded(callback);

      // Should add Turbo event listeners
      expect(addEventListenerSpy).toHaveBeenCalledWith('turbo:before-render', expect.any(Function));
      expect(addEventListenerSpy).toHaveBeenCalledWith('turbo:render', expect.any(Function));
      // Callback should be called immediately
      expect(callback).toHaveBeenCalledTimes(1);
    });
  });

  describe('with Turbolinks 5 navigation library', () => {
    beforeEach(() => {
      jest.doMock('../src/turbolinksUtils.ts', () =>
        createNavigationMock({
          turbolinksInstalled: jest.fn(() => true),
          turbolinksSupported: jest.fn(() => true),
          turbolinksVersion5: jest.fn(() => true),
        }),
      );
    });

    afterEach(() => {
      jest.dontMock('../src/turbolinksUtils.ts');
    });

    it('should set up Turbolinks 5 event listeners when Turbolinks 5 is installed', () => {
      setReadyState('complete');
      const { onPageLoaded } = importPageLifecycle();
      const callback = jest.fn();

      onPageLoaded(callback);

      // Should add Turbolinks 5 event listeners
      expect(addEventListenerSpy).toHaveBeenCalledWith('turbolinks:before-render', expect.any(Function));
      expect(addEventListenerSpy).toHaveBeenCalledWith('turbolinks:render', expect.any(Function));
      // Callback should be called immediately
      expect(callback).toHaveBeenCalledTimes(1);
    });
  });

  describe('with Turbolinks 2 navigation library', () => {
    beforeEach(() => {
      jest.doMock('../src/turbolinksUtils.ts', () =>
        createNavigationMock({
          turbolinksInstalled: jest.fn(() => true),
          turbolinksSupported: jest.fn(() => true),
        }),
      );
    });

    afterEach(() => {
      jest.dontMock('../src/turbolinksUtils.ts');
    });

    it('should set up Turbolinks 2 event listeners when Turbolinks 2 is installed', () => {
      setReadyState('complete');
      const { onPageLoaded } = importPageLifecycle();
      const callback = jest.fn();

      onPageLoaded(callback);

      // Should add Turbolinks 2 event listeners
      expect(addEventListenerSpy).toHaveBeenCalledWith('page:before-unload', expect.any(Function));
      expect(addEventListenerSpy).toHaveBeenCalledWith('page:change', expect.any(Function));
      // Turbolinks 2 does NOT call callbacks immediately - only sets up listeners
      expect(callback).not.toHaveBeenCalled();
    });
  });

  describe('multiple callbacks', () => {
    it('should handle multiple page loaded callbacks', () => {
      setReadyState('complete');
      const { onPageLoaded } = importPageLifecycle();
      const callback1 = jest.fn();
      const callback2 = jest.fn();
      const callback3 = jest.fn();

      onPageLoaded(callback1);
      onPageLoaded(callback2);
      onPageLoaded(callback3);

      // Since no navigation library is mocked (all return false), callbacks should be called immediately
      expect(callback1).toHaveBeenCalledTimes(1);
      expect(callback2).toHaveBeenCalledTimes(1);
      expect(callback3).toHaveBeenCalledTimes(1);
    });
  });

  describe('server-side rendering', () => {
    it('should not initialize when window is undefined', () => {
      // Mock window as undefined
      const originalWindow = global.window;
      delete global.window;

      const { onPageLoaded } = importPageLifecycle();
      const callback = jest.fn();

      onPageLoaded(callback);

      // Should not call callback or add event listeners
      expect(callback).not.toHaveBeenCalled();
      expect(addEventListenerSpy).not.toHaveBeenCalled();

      // Restore window
      global.window = originalWindow;
    });
  });

  describe('preventing duplicate initialization', () => {
    it('should not initialize listeners multiple times', () => {
      setReadyState('loading');
      const { onPageLoaded } = importPageLifecycle();
      const callback1 = jest.fn();
      const callback2 = jest.fn();

      // First call should initialize and call addEventListener
      onPageLoaded(callback1);
      expect(addEventListenerSpy).toHaveBeenCalledTimes(1);

      // Second call should not add more listeners (isPageLifecycleInitialized is true)
      onPageLoaded(callback2);
      expect(addEventListenerSpy).toHaveBeenCalledTimes(1);

      // Both callbacks should be called
      expect(callback1).not.toHaveBeenCalled();
      expect(callback2).not.toHaveBeenCalled();
    });
  });

  describe('deferred script race condition (PR #2295 regression test)', () => {
    // This test documents the race condition that occurs when using `readyState !== 'loading'`
    // instead of `readyState === 'complete'`.
    //
    // Timeline of events when a page loads with deferred scripts:
    // 1. Browser starts parsing HTML
    // 2. Browser encounters <script defer src="component-bundle.js">
    // 3. Browser continues parsing HTML (defer scripts download in parallel)
    // 4. Browser finishes parsing HTML → readyState becomes 'interactive'
    // 5. Browser executes deferred scripts in order (component-bundle.js runs ReactOnRails.register())
    // 6. Browser fires 'DOMContentLoaded' event
    // 7. Browser loads remaining resources (images, etc.) → readyState becomes 'complete'
    //
    // The problem with `readyState !== 'loading'`:
    // - If React on Rails initializes at step 4 (readyState = 'interactive')
    // - It tries to hydrate components BEFORE step 5 completes
    // - ComponentRegistry.get() throws "Could not find component registered with name"
    //
    // The fix: Use `readyState === 'complete'` to ensure we wait for DOMContentLoaded
    // (which fires AFTER deferred scripts execute)

    it('should NOT call callbacks immediately when readyState is "interactive" because deferred scripts may not have executed', () => {
      // Simulate the state right after HTML parsing completes but before deferred scripts run
      setReadyState('interactive');

      const { onPageLoaded } = importPageLifecycle();

      // This callback represents the hydration logic that needs registered components
      const hydrateComponentCallback = jest.fn();
      onPageLoaded(hydrateComponentCallback);

      // CRITICAL: With the correct implementation (readyState === 'complete'),
      // the callback should NOT be called immediately when readyState is 'interactive'.
      // This gives deferred scripts time to execute and register components.
      expect(hydrateComponentCallback).not.toHaveBeenCalled();

      // Instead, a DOMContentLoaded listener should be added
      // DOMContentLoaded fires AFTER deferred scripts execute (between steps 5 and 6)
      expect(addEventListenerSpy).toHaveBeenCalledWith('DOMContentLoaded', expect.any(Function));
    });

    it('should demonstrate the component registration timing issue with deferred scripts', () => {
      // This test simulates the exact scenario that causes "Could not find component" errors
      setReadyState('interactive');

      // Simulate a component that would be registered by a deferred script
      // At readyState='interactive', the deferred script hasn't run yet
      let componentRegistered = false;
      const simulatedComponentRegistry = {
        get: (name) => {
          if (!componentRegistered) {
            throw new Error(
              `Could not find component registered with name ${name}. ` +
                'Registered component names include [  ]. Maybe you forgot to register the component?',
            );
          }
          return { name, component: () => null };
        },
      };

      const { onPageLoaded } = importPageLifecycle();

      // This callback simulates what happens during hydration
      const attemptHydration = jest.fn(() => {
        // Try to get the component - this would fail if called before deferred scripts run
        return simulatedComponentRegistry.get('MyDeferredComponent');
      });

      onPageLoaded(attemptHydration);

      // With correct implementation: callback not called yet, so no error
      expect(attemptHydration).not.toHaveBeenCalled();

      // Simulate deferred script executing (this happens before DOMContentLoaded)
      componentRegistered = true;

      // Simulate DOMContentLoaded firing (triggers the stored callback)
      const domContentLoadedHandler = addEventListenerSpy.mock.calls.find(
        (call) => call[0] === 'DOMContentLoaded',
      )?.[1];

      expect(domContentLoadedHandler).toBeDefined();

      // Now when DOMContentLoaded fires, the component is registered
      // and hydration succeeds
      domContentLoadedHandler();
      expect(attemptHydration).toHaveBeenCalled();
      // No error thrown because componentRegistered is now true
    });

    it('should handle the case where readyState transitions from interactive to complete', () => {
      // Start in 'interactive' state (HTML parsed, deferred scripts may be running)
      setReadyState('interactive');

      const { onPageLoaded } = importPageLifecycle();
      const callback = jest.fn();

      onPageLoaded(callback);

      // Callback should not be called immediately at 'interactive'
      expect(callback).not.toHaveBeenCalled();
      expect(addEventListenerSpy).toHaveBeenCalledWith('DOMContentLoaded', expect.any(Function));

      // Get the DOMContentLoaded handler
      const domContentLoadedHandler = addEventListenerSpy.mock.calls.find(
        (call) => call[0] === 'DOMContentLoaded',
      )?.[1];

      // Simulate state transition: deferred scripts complete, then DOMContentLoaded fires
      setReadyState('complete');
      domContentLoadedHandler();

      // Now callback should have been called
      expect(callback).toHaveBeenCalledTimes(1);
    });
  });
});
