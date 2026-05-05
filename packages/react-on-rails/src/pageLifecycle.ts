import {
  debugTurbolinks,
  turbolinksInstalled,
  turbolinksSupported,
  turboInstalled,
  turbolinksVersion5,
} from './turbolinksUtils.ts';

type PageLifecycleCallback = () => void | Promise<void>;
type PageState = 'load' | 'unload' | 'initial';

const pageLoadedCallbacks = new Set<PageLifecycleCallback>();
const pageUnloadedCallbacks = new Set<PageLifecycleCallback>();

let currentPageState: PageState = 'initial';
let turboEventListenersInstalled = false;
let turbolinks5EventListenersInstalled = false;
let turbolinks2EventListenersInstalled = false;

function runPageLoadedCallbacks(): void {
  currentPageState = 'load';
  pageLoadedCallbacks.forEach((callback) => {
    void callback();
  });
}

function runPageUnloadedCallbacks(): void {
  currentPageState = 'unload';
  // Browser navigation events do not await async listeners. Keep unload
  // callbacks fire-and-forget; each callback must own any async cleanup it
  // starts.
  pageUnloadedCallbacks.forEach((callback) => {
    void callback();
  });
}

function setupPageNavigationListeners(): void {
  // Install listeners when running on the client (browser).
  // We must check for navigation libraries AFTER the document is loaded because we load the
  // Webpack bundles first.
  const hasNavigationLibrary = (turbolinksInstalled() && turbolinksSupported()) || turboInstalled();
  if (!hasNavigationLibrary) {
    debugTurbolinks('NO NAVIGATION LIBRARY: running page loaded callbacks immediately');
    runPageLoadedCallbacks();
    return;
  }

  if (turboInstalled()) {
    if (turboEventListenersInstalled) return;

    debugTurbolinks('TURBO DETECTED: adding event listeners for turbo:before-cache and turbo:render.');
    document.addEventListener('turbo:before-cache', runPageUnloadedCallbacks);
    document.addEventListener('turbo:render', runPageLoadedCallbacks);
    turboEventListenersInstalled = true;
    runPageLoadedCallbacks();
  } else if (turbolinksVersion5()) {
    if (turbolinks5EventListenersInstalled) return;

    debugTurbolinks(
      'TURBOLINKS 5 DETECTED: adding event listeners for turbolinks:before-render and turbolinks:render.',
    );
    document.addEventListener('turbolinks:before-render', runPageUnloadedCallbacks);
    document.addEventListener('turbolinks:render', runPageLoadedCallbacks);
    turbolinks5EventListenersInstalled = true;
    runPageLoadedCallbacks();
  } else {
    if (turbolinks2EventListenersInstalled) return;

    debugTurbolinks('TURBOLINKS 2 DETECTED: adding event listeners for page:before-unload and page:change.');
    document.addEventListener('page:before-unload', runPageUnloadedCallbacks);
    document.addEventListener('page:change', runPageLoadedCallbacks);
    turbolinks2EventListenersInstalled = true;
  }
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
    setupPageNavigationListeners();
  } else {
    const initialPageLoadHandler = (event: Event): void => {
      if (event.type === 'readystatechange' && document.readyState !== 'complete') return;
      document.removeEventListener('DOMContentLoaded', initialPageLoadHandler);
      document.removeEventListener('readystatechange', initialPageLoadHandler);
      setupPageNavigationListeners();
    };

    document.addEventListener('DOMContentLoaded', initialPageLoadHandler);

    if (document.readyState === 'interactive') {
      document.addEventListener('readystatechange', initialPageLoadHandler);
    }
  }
}

export function refreshPageEventListeners(): void {
  if (typeof window === 'undefined') return;

  if (!isPageLifecycleInitialized || document.readyState !== 'complete') {
    initializePageEventListeners();
    return;
  }

  setupPageNavigationListeners();
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
    // Match runPageUnloadedCallbacks: late unload subscribers are invoked
    // without awaiting their result.
    void callback();
  }
  pageUnloadedCallbacks.add(callback);
  initializePageEventListeners();
}
