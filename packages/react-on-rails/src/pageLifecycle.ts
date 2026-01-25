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

  // Important: replacing this condition with `document.readyState !== 'loading'` is not valid
  // As the core ReactOnRails needs to ensure that all component bundles are loaded and executed before hydrating them
  // If the `document.readyState === 'interactive'`, it doesn't guarantee that deferred scripts are executed
  // the `readyState` can be `'interactive'` while the deferred scripts are still being executed
  // Which will lead to the error `"Could not find component registered with name <component name>"`
  // It will happen if this line is reached before the component chunk is executed on browser and reached the line
  // ReactOnRails.register({ Component });
  // ReactOnRailsPro is resellient against that type of race conditions, but it won't wait for that state anyway
  // As it immediately hydrates the components at the page as soon as its html and bundle is loaded on the browser
  // See pageLifecycle.test.js for unit tests validating this logic
  if (document.readyState === 'complete') {
    setupPageNavigationListeners();
  } else {
    document.addEventListener('DOMContentLoaded', setupPageNavigationListeners);
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
