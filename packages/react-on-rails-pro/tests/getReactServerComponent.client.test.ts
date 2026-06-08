import { enableFetchMocks } from 'jest-fetch-mock';
import type { RailsContext } from 'react-on-rails/types';
import { RSC_STREAM_DIAGNOSTIC_ERROR_NAME } from '../src/rscDiagnostics.ts';

enableFetchMocks();

const encoder = new TextEncoder();

const streamFromText = (text: string) =>
  new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(encoder.encode(text));
      controller.close();
    },
  });

const responseFromText = (
  text: string,
  responseOverrides: Pick<Response, 'ok' | 'status' | 'statusText'> = {
    ok: true,
    status: 200,
    statusText: 'OK',
  },
) =>
  ({
    body: streamFromText(text),
    ...responseOverrides,
  }) as Response;

const loadClientModule = async (createFromReadableStream = jest.fn()) => {
  jest.resetModules();
  jest.doMock('react-on-rails-rsc/client.browser', () => ({
    createFromReadableStream,
  }));

  const clientModule = await import('../src/getReactServerComponent.client.ts');
  return { createFromReadableStream, ...clientModule };
};

const fetchMock = fetch as jest.MockedFunction<typeof fetch>;

const setDocumentReadyState = (readyState: DocumentReadyState) => {
  Object.defineProperty(document, 'readyState', {
    value: readyState,
    configurable: true,
    writable: true,
  });
};

describe('fetchRSC HTTP responses', () => {
  afterEach(() => {
    fetchMock.mockReset();
    jest.dontMock('react-on-rails-rsc/client.browser');
    jest.resetModules();
  });

  it('rejects non-ok HTTP responses before parsing the RSC stream', async () => {
    const { createFromReadableStream, fetchRSC } = await loadClientModule();
    const componentProps = { id: 1 };
    const fetchUrl = `/rsc_payload/MissingPanel?${new URLSearchParams({
      props: JSON.stringify(componentProps),
    })}`;
    fetchMock.mockResolvedValue(
      responseFromText('<html>Not found</html>', {
        ok: false,
        status: 404,
        statusText: 'Not Found',
      }),
    );

    await expect(
      fetchRSC({
        componentName: 'MissingPanel',
        componentProps,
        rscPayloadGenerationUrlPath: '/rsc_payload',
      }),
    ).rejects.toThrow(
      `Failed to fetch RSC payload for component "MissingPanel" from "${fetchUrl}": RSC payload request for component "MissingPanel" from "/rsc_payload/MissingPanel" failed with HTTP 404 Not Found.`,
    );
    expect(createFromReadableStream).not.toHaveBeenCalled();
  });

  it('propagates non-ok HTTP responses through the getReactServerComponent fetch path', async () => {
    const { createFromReadableStream, default: getReactServerComponent } = await loadClientModule();
    fetchMock.mockResolvedValue(
      responseFromText('unauthorized', {
        ok: false,
        status: 401,
        statusText: 'Unauthorized',
      }),
    );

    const getComponent = getReactServerComponent('dom-node-id', {
      rscPayloadGenerationUrlPath: '/rsc_payload',
    } as RailsContext);

    await expect(
      getComponent({
        componentName: 'AccountPanel',
        componentProps: {},
        enforceRefetch: true,
      }),
    ).rejects.toThrow(
      'Failed to fetch RSC payload for component "AccountPanel" from "/rsc_payload/AccountPanel?props=%7B%7D": RSC payload request for component "AccountPanel" from "/rsc_payload/AccountPanel" failed with HTTP 401 Unauthorized.',
    );
    expect(createFromReadableStream).not.toHaveBeenCalled();
  });
});

describe('getReactServerComponent preloaded payload diagnostics', () => {
  beforeAll(() => {
    const webpackWindow = window as unknown as Window & {
      __webpack_chunk_load__: jest.Mock;
      __webpack_require__: jest.Mock;
    };

    webpackWindow.__webpack_require__ = jest.fn();
    webpackWindow.__webpack_chunk_load__ = jest.fn();
  });

  it('merges RSC diagnostics into preloaded hydration errors', async () => {
    expect.assertions(7);
    const { createFromPreloadedPayloads } = await import('../src/getReactServerComponent.client.ts');
    let diagnosticMetadata: Record<string, unknown> | undefined;
    const payloads: string[] = [];
    const originalReadyState = document.readyState;
    setDocumentReadyState('loading');

    const renderPromise = createFromPreloadedPayloads(payloads, 'TestComponent', () => diagnosticMetadata);
    diagnosticMetadata = {
      hasErrors: true,
      renderingError: {
        message: 'useState is not a function',
        stack:
          'TypeError: useState is not a function\n' +
          '    at HooksWithoutClientDirective (/app/components/HooksWithoutClientDirective.server.tsx:4:7)',
      },
    };
    payloads.push('not valid Flight data\n');
    setDocumentReadyState('complete');
    document.dispatchEvent(new Event('DOMContentLoaded'));

    try {
      await renderPromise;
    } catch (error) {
      const caughtError = error as Error;
      expect(caughtError).toBeInstanceOf(Error);
      expect(caughtError.name).toBe(RSC_STREAM_DIAGNOSTIC_ERROR_NAME);
      expect(caughtError.message).toContain('[ReactOnRails] RSC bundle rendering failed.');
      expect(caughtError.message).toContain('Component: TestComponent');
      expect(caughtError.message).toContain('Module: /app/components/HooksWithoutClientDirective.server.tsx');
      expect(caughtError.message).toContain('Original error: useState is not a function');
      expect(caughtError.message).toContain('React stream error: Failed to hydrate preloaded RSC payload');
    } finally {
      setDocumentReadyState(originalReadyState);
    }
  });

  it('wraps preloaded hydration errors without diagnostics when no metadata is available', async () => {
    expect.assertions(5);
    const { createFromPreloadedPayloads } = await import('../src/getReactServerComponent.client.ts');
    const payloads: string[] = [];
    const originalReadyState = document.readyState;
    setDocumentReadyState('loading');

    const renderPromise = createFromPreloadedPayloads(payloads, 'TestComponent');
    payloads.push('not valid Flight data\n');
    setDocumentReadyState('complete');
    document.dispatchEvent(new Event('DOMContentLoaded'));

    try {
      await renderPromise;
    } catch (error) {
      const caughtError = error as Error;
      expect(caughtError).toBeInstanceOf(Error);
      expect(caughtError.name).toBe('Error');
      expect(caughtError.name).not.toBe(RSC_STREAM_DIAGNOSTIC_ERROR_NAME);
      expect(caughtError.message).toContain(
        'Failed to hydrate preloaded RSC payload for component "TestComponent"',
      );
      expect(caughtError.message).not.toContain('[ReactOnRails] RSC bundle rendering failed.');
    } finally {
      setDocumentReadyState(originalReadyState);
    }
  });
});
