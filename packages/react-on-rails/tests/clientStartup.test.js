/**
 * @jest-environment jsdom
 */

describe('reactOnRailsPageLoaded startup coordination', () => {
  let originalReadyStateDescriptor;
  let currentReadyState;
  let addEventListenerSpy;

  const setReadyState = (state) => {
    currentReadyState = state;
  };

  const waitForNextTick = () => new Promise((resolve) => setTimeout(resolve, 0));

  const loadReactOnRails = () => require('../src/ReactOnRails.client.ts').default;

  const setupPage = () => {
    document.body.innerHTML = `\
      <script id="js-react-on-rails-context" type="application/json">{"pathname":"/test"}</script>
      <script type="application/json" data-js-react-on-rails-store="TestStore">{"seed":1}</script>
      <div id="app"></div>
      <script type="application/json" class="js-react-on-rails-component" data-component-name="CustomRenderer" data-dom-id="app">{"name":"Leslie"}</script>
    `;
  };

  const registerStoreAndRenderer = (ReactOnRails) => {
    const counts = {
      storeCalls: 0,
      rendererCalls: 0,
    };

    ReactOnRails.registerStore({
      TestStore: (props) => {
        counts.storeCalls += 1;
        return { props, createdAtCall: counts.storeCalls };
      },
    });

    const renderer = (_props, _railsContext, domId) => {
      counts.rendererCalls += 1;
      const domNode = document.getElementById(domId);
      if (domNode) {
        domNode.textContent = `render ${counts.rendererCalls}`;
      }
    };
    renderer.renderFunction = true;

    ReactOnRails.register({ CustomRenderer: renderer });
    return counts;
  };

  beforeEach(() => {
    jest.resetModules();
    delete globalThis.ReactOnRails;
    // eslint-disable-next-line no-underscore-dangle
    delete globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__;

    originalReadyStateDescriptor = Object.getOwnPropertyDescriptor(document, 'readyState');
    setReadyState('loading');
    Object.defineProperty(document, 'readyState', {
      configurable: true,
      get() {
        return currentReadyState;
      },
    });

    addEventListenerSpy = jest.spyOn(document, 'addEventListener');
    document.body.innerHTML = '';
  });

  afterEach(() => {
    if (originalReadyStateDescriptor) {
      Object.defineProperty(document, 'readyState', originalReadyStateDescriptor);
    }

    document.body.innerHTML = '';
    addEventListenerSpy.mockRestore();
    delete globalThis.ReactOnRails;
    // eslint-disable-next-line no-underscore-dangle
    delete globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__;
  });

  it('does not render twice when manual page load runs during interactive before deferred startup registration', async () => {
    setReadyState('interactive');
    setupPage();

    const ReactOnRails = loadReactOnRails();
    const counts = registerStoreAndRenderer(ReactOnRails);

    await ReactOnRails.reactOnRailsPageLoaded();
    expect(counts).toEqual({ storeCalls: 1, rendererCalls: 1 });

    await waitForNextTick();
    expect(counts).toEqual({ storeCalls: 1, rendererCalls: 1 });

    setReadyState('complete');
    document.dispatchEvent(new Event('readystatechange'));
    await waitForNextTick();

    expect(counts).toEqual({ storeCalls: 1, rendererCalls: 1 });
  });

  it('does not render twice when lifecycle already reached load before deferred startup registration', async () => {
    setReadyState('complete');
    setupPage();

    const ReactOnRails = loadReactOnRails();
    const counts = registerStoreAndRenderer(ReactOnRails);

    await ReactOnRails.reactOnRailsPageLoaded();
    expect(counts).toEqual({ storeCalls: 1, rendererCalls: 1 });

    await waitForNextTick();
    expect(counts).toEqual({ storeCalls: 1, rendererCalls: 1 });
  });

  it('defers turbo listener installation until the automatic ready event after a manual initial load', async () => {
    setReadyState('interactive');
    setupPage();

    const ReactOnRails = loadReactOnRails();
    registerStoreAndRenderer(ReactOnRails);

    await ReactOnRails.reactOnRailsPageLoaded();
    ReactOnRails.setOptions({ turbo: true });

    expect(addEventListenerSpy).not.toHaveBeenCalledWith('turbo:before-render', expect.any(Function));
    expect(addEventListenerSpy).not.toHaveBeenCalledWith('turbo:render', expect.any(Function));

    setReadyState('complete');
    document.dispatchEvent(new Event('readystatechange'));
    await waitForNextTick();

    expect(addEventListenerSpy).toHaveBeenCalledWith('turbo:before-render', expect.any(Function));
    expect(addEventListenerSpy).toHaveBeenCalledWith('turbo:render', expect.any(Function));
  });
});
