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
    expect(addEventListenerSpy).not.toHaveBeenCalledWith('readystatechange', expect.any(Function));
  });

  it('should wait for readystatechange when document.readyState is "interactive"', () => {
    setReadyState('loading');
    const callback = jest.fn();
    const { onPageLoaded } = importPageLifecycle();

    onPageLoaded(callback);

    // Should not call callback immediately since readyState is 'loading'
    expect(callback).not.toHaveBeenCalled();
    // Verify that a DOMContentLoaded listener was added when readyState is 'loading'
    expect(addEventListenerSpy).toHaveBeenCalledWith('load', expect.any(Function));
  });

  it('should wait for readystatechange when document.readyState is "loading"', () => {
    setReadyState('loading');
    const callback = jest.fn();
    const { onPageLoaded } = importPageLifecycle();

    onPageLoaded(callback);

    // Should not call callback immediately since readyState is 'loading'
    expect(callback).not.toHaveBeenCalled();
    // Verify that a DOMContentLoaded listener was added when readyState is 'loading'
    expect(addEventListenerSpy).toHaveBeenCalledWith('load', expect.any(Function));
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
});
