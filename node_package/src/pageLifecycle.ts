import {
  debugTurbolinks,
  turbolinksInstalled,
  turbolinksSupported,
  turboInstalled,
  turbolinksVersion5,
} from './turbolinksUtils';

type PageLifecycleCallback = () => void | Promise<void>;
type PageState = 'load' | 'unload' | 'initial';

const pageLoadedCallbacks = new Set<PageLifecycleCallback>();
const pageUnloadedCallbacks = new Set<PageLifecycleCallback>();

let currentPageState: PageState = 'initial';

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

function setupTurbolinksEventListeners(): void {
  // Install listeners when running on the client (browser).
  // We must do this check for turbolinks AFTER the document is loaded because we load the
  // Webpack bundles first.
  if ((!turbolinksInstalled() || !turbolinksSupported()) && !turboInstalled()) {
    debugTurbolinks('NOT USING TURBOLINKS: calling reactOnRailsPageLoaded');
    runPageLoadedCallbacks();
    return;
  }

  if (turboInstalled()) {
    debugTurbolinks('USING TURBO: document added event listeners turbo:before-render and turbo:render.');
    document.addEventListener('turbo:before-render', runPageUnloadedCallbacks);
    document.addEventListener('turbo:render', runPageLoadedCallbacks);
    runPageLoadedCallbacks();
  } else if (turbolinksVersion5()) {
    debugTurbolinks(
      'USING TURBOLINKS 5: document added event listeners turbolinks:before-render and turbolinks:render.',
    );
    document.addEventListener('turbolinks:before-render', runPageUnloadedCallbacks);
    document.addEventListener('turbolinks:render', runPageLoadedCallbacks);
    runPageLoadedCallbacks();
  } else {
    debugTurbolinks('USING TURBOLINKS 2: document added event listeners page:before-unload and page:change.');
    document.addEventListener('page:before-unload', runPageUnloadedCallbacks);
    document.addEventListener('page:change', runPageLoadedCallbacks);
  }
}

let isEventListenerInitialized = false;
function initializePageEventListeners(): void {
  if (typeof window === 'undefined') return;

  if (isEventListenerInitialized) {
    return;
  }
  isEventListenerInitialized = true;

  if (document.readyState === 'complete') {
    setupTurbolinksEventListeners();
  } else {
    document.addEventListener('DOMContentLoaded', setupTurbolinksEventListeners);
  }
}

export async function onPageLoaded(callback: PageLifecycleCallback): Promise<void> {
  if (currentPageState === 'load') {
    await callback();
  }
  pageLoadedCallbacks.add(callback);
  initializePageEventListeners();
}

export async function onPageUnloaded(callback: PageLifecycleCallback): Promise<void> {
  if (currentPageState === 'unload') {
    await callback();
  }
  pageUnloadedCallbacks.add(callback);
  initializePageEventListeners();
}
