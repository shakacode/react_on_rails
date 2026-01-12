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

function runInNextPollPhase(callback: PageLifecycleCallback) {
  console.log('Running the callback at the next poll phase0');
  setTimeout(() => {
    console.log('The real callback is running now....');
    void callback();
  }, 10);
}

function runPageLoadedCallbacks(): void {
  console.log('Running page loaded callbacks', new Error().stack);
  currentPageState = 'load';
  pageLoadedCallbacks.forEach((callback) => {
    runInNextPollPhase(callback);
  });
}

function runPageUnloadedCallbacks(): void {
  currentPageState = 'unload';
  pageUnloadedCallbacks.forEach((callback) => {
    runInNextPollPhase(callback);
  });
}

function setupPageNavigationListeners(): void {
  // Install listeners when running on the client (browser).
  // We must check for navigation libraries AFTER the document is loaded because we load the
  // Webpack bundles first.
  const hasNavigationLibrary = (turbolinksInstalled() && turbolinksSupported()) || turboInstalled();
  if (!hasNavigationLibrary) {
    debugTurbolinks('NO NAVIGATION LIBRARY: running page loaded callbacks immediately');
    console.log('Run Page Loaded Callbacks');
    runPageLoadedCallbacks();
    return;
  }

  if (turboInstalled()) {
    debugTurbolinks('TURBO DETECTED: adding event listeners for turbo:before-render and turbo:render.');
    document.addEventListener('turbo:before-render', runPageUnloadedCallbacks);
    document.addEventListener('turbo:render', runPageLoadedCallbacks);
    runPageLoadedCallbacks();
  } else if (turbolinksVersion5()) {
    debugTurbolinks(
      'TURBOLINKS 5 DETECTED: adding event listeners for turbolinks:before-render and turbolinks:render.',
    );
    document.addEventListener('turbolinks:before-render', runPageUnloadedCallbacks);
    document.addEventListener('turbolinks:render', runPageLoadedCallbacks);
    runPageLoadedCallbacks();
  } else {
    debugTurbolinks('TURBOLINKS 2 DETECTED: adding event listeners for page:before-unload and page:change.');
    document.addEventListener('page:before-unload', runPageUnloadedCallbacks);
    document.addEventListener('page:change', runPageLoadedCallbacks);
  }
}

let isPageLifecycleInitialized = false;
function initializePageEventListeners(): void {
  if (typeof window === 'undefined') return;

  if (isPageLifecycleInitialized) {
    return;
  }
  isPageLifecycleInitialized = true;

  if (document.readyState !== 'loading') {
    console.log(`Page state: ${document.readyState}`);
    setupPageNavigationListeners();
  } else {
    document.addEventListener('DOMContentLoaded', setupPageNavigationListeners);
  }
}

export function onPageLoaded(callback: PageLifecycleCallback): void {
  if (currentPageState === 'load') {
    console.log('Pag is already at the load state');
    runInNextPollPhase(callback);
  }
  pageLoadedCallbacks.add(callback);
  initializePageEventListeners();
}

export function onPageUnloaded(callback: PageLifecycleCallback): void {
  if (currentPageState === 'unload') {
    runInNextPollPhase(callback);
  }
  pageUnloadedCallbacks.add(callback);
  initializePageEventListeners();
}
