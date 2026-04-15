import {
  debugTurbolinks,
  turbolinksInstalled,
  turbolinksSupported,
  turboInstalled,
  turbolinksVersion5,
} from './turbolinksUtils.ts';

type PageLifecycleCallback = () => void | Promise<void>;
type PageState = 'load' | 'unload' | 'initial';
type NavigationStrategy = 'none' | 'turbo' | 'turbolinks5' | 'turbolinks2';

const pageLoadedCallbacks = new Set<PageLifecycleCallback>();
const pageUnloadedCallbacks = new Set<PageLifecycleCallback>();

let currentPageState: PageState = 'initial';
let areNavigationListenersInstalled = false;
let initialPageLoadReadyHandler: (() => void) | null = null;
let initialPageLoadCompleteHandler: (() => void) | null = null;

function runPageLoadedCallbacks(): void {
  currentPageState = 'load';
  pageLoadedCallbacks.forEach((callback) => {
    void callback();
  });
}

function runPageUnloadedCallbacks(): void {
  currentPageState = 'unload';
  pageUnloadedCallbacks.forEach((callback) => {
    void callback();
  });
}

function getNavigationStrategy(): NavigationStrategy {
  if (turboInstalled()) {
    return 'turbo';
  }

  if (turbolinksInstalled() && turbolinksSupported()) {
    return turbolinksVersion5() ? 'turbolinks5' : 'turbolinks2';
  }

  return 'none';
}

function ensureNavigationListenersInstalled(): NavigationStrategy {
  const navigationStrategy = getNavigationStrategy();
  if (areNavigationListenersInstalled) {
    return navigationStrategy;
  }

  areNavigationListenersInstalled = true;

  // Install listeners when running on the client (browser).
  // We must check for navigation libraries AFTER the document is loaded because we load the
  // Webpack bundles first.
  if (navigationStrategy === 'none') {
    debugTurbolinks('NO NAVIGATION LIBRARY: running page loaded callbacks immediately');
  } else if (navigationStrategy === 'turbo') {
    debugTurbolinks('TURBO DETECTED: adding event listeners for turbo:before-render and turbo:render.');
    document.addEventListener('turbo:before-render', runPageUnloadedCallbacks);
    document.addEventListener('turbo:render', runPageLoadedCallbacks);
  } else if (navigationStrategy === 'turbolinks5') {
    debugTurbolinks(
      'TURBOLINKS 5 DETECTED: adding event listeners for turbolinks:before-render and turbolinks:render.',
    );
    document.addEventListener('turbolinks:before-render', runPageUnloadedCallbacks);
    document.addEventListener('turbolinks:render', runPageLoadedCallbacks);
  } else {
    debugTurbolinks('TURBOLINKS 2 DETECTED: adding event listeners for page:before-unload and page:change.');
    document.addEventListener('page:before-unload', runPageUnloadedCallbacks);
    document.addEventListener('page:change', runPageLoadedCallbacks);
  }

  return navigationStrategy;
}

function cleanupInitialPageLoadListeners(): void {
  if (initialPageLoadReadyHandler) {
    document.removeEventListener('DOMContentLoaded', initialPageLoadReadyHandler);
    initialPageLoadReadyHandler = null;
  }

  if (initialPageLoadCompleteHandler) {
    document.removeEventListener('readystatechange', initialPageLoadCompleteHandler);
    initialPageLoadCompleteHandler = null;
  }
}

function handleAutomaticInitialPageLoad(): void {
  if (currentPageState !== 'initial') {
    cleanupInitialPageLoadListeners();
    ensureNavigationListenersInstalled();
    return;
  }

  cleanupInitialPageLoadListeners();
  const navigationStrategy = ensureNavigationListenersInstalled();
  if (navigationStrategy !== 'turbolinks2') {
    runPageLoadedCallbacks();
  }
}

export function consumeInitialPageLoadIfNeeded(): boolean {
  if (currentPageState !== 'initial') {
    return false;
  }

  if (document.readyState === 'complete') {
    cleanupInitialPageLoadListeners();
    ensureNavigationListenersInstalled();
  }

  runPageLoadedCallbacks();
  return true;
}

let isPageLifecycleInitialized = false;
function initializePageEventListeners(): void {
  if (typeof window === 'undefined') return;

  if (isPageLifecycleInitialized) {
    return;
  }
  isPageLifecycleInitialized = true;

  // Important: replacing this condition with `document.readyState !== 'loading'` is not valid for
  // the core page-load sweep. During `interactive`, deferred/module scripts may still be executing,
  // and a component chunk may not yet have reached `ReactOnRails.register({ Component })`.
  // Starting hydration too early can trigger "Could not find component registered" errors.
  //
  // However, async or dynamically-injected scripts can start after DOMContentLoaded has already fired
  // while the document is still `interactive`. In that case, waiting only for DOMContentLoaded can miss
  // initialization entirely, so we recover on the later `complete` transition.
  //
  // ReactOnRailsPro's early hydration path is more resilient to the registration race because it can
  // hydrate components as their HTML and bundles arrive, but this page lifecycle still powers the
  // fallback page-load sweep. See pageLifecycle.test.js for regression coverage of both cases.
  if (document.readyState === 'complete') {
    handleAutomaticInitialPageLoad();
  } else {
    initialPageLoadReadyHandler = (): void => {
      handleAutomaticInitialPageLoad();
    };

    initialPageLoadCompleteHandler = (): void => {
      if (document.readyState === 'complete') {
        handleAutomaticInitialPageLoad();
      }
    };

    document.addEventListener('DOMContentLoaded', initialPageLoadReadyHandler);

    if (document.readyState === 'interactive') {
      document.addEventListener('readystatechange', initialPageLoadCompleteHandler);
    }
  }
}

export function onPageLoaded(callback: PageLifecycleCallback): void {
  if (currentPageState === 'load') {
    void callback();
  }
  pageLoadedCallbacks.add(callback);
  initializePageEventListeners();
}

export function onPageUnloaded(callback: PageLifecycleCallback): void {
  if (currentPageState === 'unload') {
    void callback();
  }
  pageUnloadedCallbacks.add(callback);
  initializePageEventListeners();
}
