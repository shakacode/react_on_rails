const setupWrappedHydration = async () => {
  jest.resetModules();

  const hydrateRoot = jest.fn();
  const createRoot = jest.fn(() => ({ render: jest.fn() }));
  const getReactServerComponent = jest.fn(() => jest.fn());

  jest.doMock('react-dom/client', () => ({ createRoot, hydrateRoot }));
  jest.doMock('react-on-rails-rsc/client.browser', () => ({}));
  jest.doMock('../src/getReactServerComponent.client.ts', () => ({
    __esModule: true,
    default: getReactServerComponent,
  }));

  // eslint-disable-next-line global-require, @typescript-eslint/no-var-requires
  const wrapServerComponentRenderer = require('../src/wrapServerComponentRenderer/client.tsx').default;

  const domNode = document.createElement('div');
  domNode.id = 'wrapped-rsc-root';
  domNode.innerHTML = '<main>server html</main>';
  document.body.appendChild(domNode);

  const WrappedComponent = wrapServerComponentRenderer(() => null, 'WrappedComponent');
  await WrappedComponent({}, { rscPayloadGenerationUrlPath: '/rsc_payload' }, domNode.id);

  expect(hydrateRoot).toHaveBeenCalledTimes(1);
  const [, , hydrateOptions] = hydrateRoot.mock.calls[0];

  return { hydrateOptions };
};

const createBailoutDigestError = () => {
  // eslint-disable-next-line global-require, @typescript-eslint/no-var-requires
  const { RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST } = require('../src/RSCRouteSSRFalseBailoutError.ts');
  const error = new Error('RSCRoute ssr=false bailout');
  error.digest = RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST;
  return error;
};

describe('wrapServerComponentRenderer/client recoverable errors', () => {
  let originalReportErrorDescriptor;

  const setReportError = (value) => {
    Object.defineProperty(globalThis, 'reportError', {
      configurable: true,
      value,
      writable: true,
    });
  };

  beforeEach(() => {
    originalReportErrorDescriptor = Object.getOwnPropertyDescriptor(globalThis, 'reportError');
    document.body.innerHTML = '';
  });

  afterEach(() => {
    if (originalReportErrorDescriptor) {
      Object.defineProperty(globalThis, 'reportError', originalReportErrorDescriptor);
    } else {
      Reflect.deleteProperty(globalThis, 'reportError');
    }

    jest.dontMock('react-dom/client');
    jest.dontMock('react-on-rails-rsc/client.browser');
    jest.dontMock('../src/getReactServerComponent.client.ts');
    jest.resetModules();
    document.body.innerHTML = '';
  });

  it.each([
    ['direct error digest', () => createBailoutDigestError()],
    [
      'cause digest',
      () => {
        const error = new Error('Recoverable hydration retry');
        error.cause = createBailoutDigestError();
        return error;
      },
    ],
  ])(
    'suppresses classified RSCRoute ssr=false bailout recoverable errors from the %s',
    async (_label, createRecoverableError) => {
      const reportError = jest.fn();
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => undefined);
      setReportError(reportError);

      try {
        const { hydrateOptions } = await setupWrappedHydration();
        hydrateOptions.onRecoverableError(createRecoverableError());

        expect(reportError).not.toHaveBeenCalled();
        expect(consoleErrorSpy).not.toHaveBeenCalled();
      } finally {
        consoleErrorSpy.mockRestore();
      }
    },
  );

  it('reports non-bailout recoverable errors through reportError when available', async () => {
    const reportError = jest.fn();
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => undefined);
    setReportError(reportError);
    const error = new Error('Real recoverable hydration error');

    try {
      const { hydrateOptions } = await setupWrappedHydration();
      hydrateOptions.onRecoverableError(error);

      expect(reportError).toHaveBeenCalledWith(error);
      expect(consoleErrorSpy).not.toHaveBeenCalled();
    } finally {
      consoleErrorSpy.mockRestore();
    }
  });

  it('falls back to console.error for non-bailout recoverable errors when reportError is unavailable', async () => {
    setReportError(undefined);
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => undefined);
    const error = new Error('Real recoverable hydration error');

    try {
      const { hydrateOptions } = await setupWrappedHydration();
      hydrateOptions.onRecoverableError(error);

      expect(consoleErrorSpy).toHaveBeenCalledWith(error);
    } finally {
      consoleErrorSpy.mockRestore();
    }
  });
});
