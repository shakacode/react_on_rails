import { enableFetchMocks } from 'jest-fetch-mock';
import { createWebResponseFromText } from './testUtils.ts';

enableFetchMocks();

const encoder = new TextEncoder();
const decoder = new TextDecoder();

type CreateRscPayloadNode = typeof import('../src/createRscPayloadNode.client.ts').createRscPayloadNode;

const frame = (content: string, metadata: Record<string, unknown> = {}) => {
  const contentBytes = encoder.encode(content);
  return `${JSON.stringify({
    consoleReplayScript: '',
    hasErrors: false,
    isShellReady: true,
    ...metadata,
  })}\t${contentBytes.length.toString(16).padStart(8, '0')}\n${content}`;
};

const responseFromText = (text: string) => createWebResponseFromText(text);

const responseWithStatus = (text: string, status: number, statusText: string) =>
  createWebResponseFromText(text, { ok: status >= 200 && status < 300, status, statusText });

const readFlightStream = async (stream: ReadableStream<Uint8Array>) => {
  const reader = stream.getReader();
  const chunks: Uint8Array[] = [];
  let done = false;

  while (!done) {
    // eslint-disable-next-line no-await-in-loop
    const readResult = await reader.read();
    done = readResult.done;
    if (readResult.value) {
      chunks.push(readResult.value);
    }
  }

  const byteLength = chunks.reduce((total, chunk) => total + chunk.length, 0);
  const combined = new Uint8Array(byteLength);
  let offset = 0;
  chunks.forEach((chunk) => {
    combined.set(chunk, offset);
    offset += chunk.length;
  });

  return decoder.decode(combined);
};

const loadHelper = () => {
  jest.resetModules();

  const createFromReadableStream = jest.fn((stream: ReadableStream<Uint8Array>) => readFlightStream(stream));
  jest.doMock('react-on-rails-rsc/client.browser', () => ({
    createFromReadableStream,
  }));

  // eslint-disable-next-line global-require, @typescript-eslint/no-var-requires
  const { createRscPayloadNode } = require('../src/createRscPayloadNode.client.ts') as {
    createRscPayloadNode: CreateRscPayloadNode;
  };

  return { createFromReadableStream, createRscPayloadNode };
};

const fetchMock = fetch as jest.MockedFunction<typeof fetch>;

describe('createRscPayloadNode', () => {
  afterEach(() => {
    fetchMock.mockReset();
    jest.dontMock('react-on-rails-rsc/client.browser');
    jest.dontMock('../src/getReactServerComponent.client.ts');
    jest.resetModules();
    document.body.innerHTML = '';
  });

  it('fetches the Pro RSC payload route with same-origin credentials and returns raw Flight data to React', async () => {
    const { createFromReadableStream, createRscPayloadNode } = loadHelper();
    const props = { requestedBy: 'loader' };
    fetchMock.mockResolvedValue(responseFromText(`${frame('first')}${frame('second')}`));

    await expect(
      createRscPayloadNode({
        componentName: 'RscShowcaseServerPanel',
        payloadPath: ' /rsc_payload/ ',
        props,
      }),
    ).resolves.toBe('firstsecond');

    expect(fetchMock).toHaveBeenCalledWith(
      `/rsc_payload/RscShowcaseServerPanel?${new URLSearchParams({ props: JSON.stringify(props) })}`,
      { credentials: 'same-origin' },
    );
    expect(createFromReadableStream).toHaveBeenCalledTimes(1);
  });

  it('encodes component names as one payload URL path segment', async () => {
    const { createRscPayloadNode } = loadHelper();
    const props = { requestedBy: 'loader' };
    fetchMock.mockResolvedValue(responseFromText(frame('route data')));

    await expect(
      createRscPayloadNode({
        componentName: 'Dashboard Panel+Beta',
        payloadPath: '/rsc_payload',
        props,
      }),
    ).resolves.toBe('route data');

    expect(fetchMock).toHaveBeenCalledWith(
      `/rsc_payload/${encodeURIComponent('Dashboard Panel+Beta')}?${new URLSearchParams({
        props: JSON.stringify(props),
      })}`,
      { credentials: 'same-origin' },
    );
  });

  it('forwards only documented fetch controls to the payload request', async () => {
    const { createRscPayloadNode } = loadHelper();
    const abortController = new AbortController();
    const headers = new Headers({ 'X-Requested-With': 'ReactOnRailsRSC' });
    const props = { tab: 'overview' };
    fetchMock.mockResolvedValue(responseFromText(frame('route data')));

    await createRscPayloadNode({
      componentName: 'DashboardPanel',
      credentials: 'include',
      headers,
      payloadPath: 'rsc_payload',
      props,
      signal: abortController.signal,
    });

    expect(fetchMock).toHaveBeenCalledWith(
      `/rsc_payload/DashboardPanel?${new URLSearchParams({ props: JSON.stringify(props) })}`,
      {
        credentials: 'include',
        headers,
        signal: abortController.signal,
      },
    );
  });

  it('preserves abort cancellations from route loaders', async () => {
    const { createRscPayloadNode } = loadHelper();
    const abortController = new AbortController();
    const abortError = new DOMException('Route loader cancelled the payload request.', 'AbortError');
    fetchMock.mockRejectedValue(abortError);

    await expect(
      createRscPayloadNode({
        componentName: 'DashboardPanel',
        payloadPath: '/rsc_payload',
        signal: abortController.signal,
      }),
    ).rejects.toBe(abortError);
    expect(fetchMock).toHaveBeenCalledWith(
      `/rsc_payload/DashboardPanel?${new URLSearchParams({ props: JSON.stringify({}) })}`,
      { credentials: 'same-origin', signal: abortController.signal },
    );
  });

  it('rejects serialized Error payloads for route error boundaries', async () => {
    const { createFromReadableStream, createRscPayloadNode } = loadHelper();
    const payloadError = new Error('server component failed');
    fetchMock.mockResolvedValue(responseFromText(frame('serialized error payload')));
    (createFromReadableStream as jest.Mock).mockResolvedValueOnce(payloadError);

    await expect(
      createRscPayloadNode({
        componentName: 'BrokenPanel',
        payloadPath: '/rsc_payload',
      }),
    ).rejects.toBe(payloadError);
  });

  it('rejects cross-realm Error payloads for route error boundaries', async () => {
    const { createFromReadableStream, createRscPayloadNode } = loadHelper();
    const iframe = document.createElement('iframe');
    document.body.appendChild(iframe);
    const ErrorFromOtherRealm = (iframe.contentWindow as { Error?: ErrorConstructor } | null)?.Error;
    if (!ErrorFromOtherRealm) throw new Error('Expected iframe.contentWindow.Error to be available.');
    const payloadError = new ErrorFromOtherRealm('server component failed in another realm');
    fetchMock.mockResolvedValue(responseFromText(frame('serialized error payload')));
    (createFromReadableStream as jest.Mock).mockResolvedValueOnce(payloadError);

    await expect(
      createRscPayloadNode({
        componentName: 'BrokenPanel',
        payloadPath: '/rsc_payload',
      }),
    ).rejects.toBe(payloadError);
  });

  it('returns plain object payloads that only resemble errors', async () => {
    const { createFromReadableStream, createRscPayloadNode } = loadHelper();
    const validationPayload = {
      name: 'Error',
      message: 'Display this validation result.',
      stack: 'Error: Display this validation result.\n    at serialized route data',
      code: 422,
    };
    fetchMock.mockResolvedValue(responseFromText(frame('plain object payload')));
    (createFromReadableStream as jest.Mock).mockResolvedValueOnce(validationPayload);

    await expect(
      createRscPayloadNode({
        componentName: 'ValidationPanel',
        payloadPath: '/rsc_payload',
      }),
    ).resolves.toBe(validationPayload);
  });

  it('rejects non-ok HTTP responses from payload routes', async () => {
    const { createFromReadableStream, createRscPayloadNode } = loadHelper();
    fetchMock.mockResolvedValue(responseWithStatus('<html>Not found</html>', 404, 'Not Found'));

    await expect(
      createRscPayloadNode({
        componentName: 'MissingPanel',
        payloadPath: '/rsc_payload',
      }),
    ).rejects.toThrow(
      'Failed to fetch RSC payload for component "MissingPanel" from "/rsc_payload/MissingPanel?props=%7B%7D": RSC payload request for component "MissingPanel" from "/rsc_payload/MissingPanel" failed with HTTP 404 Not Found.',
    );
    expect(createFromReadableStream).not.toHaveBeenCalled();
  });

  it('returns a rejected promise when payload request preparation fails', async () => {
    const { createRscPayloadNode } = loadHelper();
    const circularProps: Record<string, unknown> = {};
    circularProps.self = circularProps;

    await expect(
      createRscPayloadNode({
        componentName: 'BrokenPropsPanel',
        payloadPath: '/rsc_payload',
        props: circularProps,
      }),
    ).rejects.toThrow('Failed to prepare RSC request for component "BrokenPropsPanel"');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('preserves non-Error synchronous failures as rejection causes', async () => {
    jest.resetModules();
    jest.doMock('../src/getReactServerComponent.client.ts', () => ({
      fetchRSC: () => {
        // eslint-disable-next-line no-throw-literal
        throw 'route data failed';
      },
    }));

    // eslint-disable-next-line global-require, @typescript-eslint/no-var-requires
    const { createRscPayloadNode } = require('../src/createRscPayloadNode.client.ts') as {
      createRscPayloadNode: CreateRscPayloadNode;
    };

    await expect(
      createRscPayloadNode({
        componentName: 'DashboardPanel',
        payloadPath: '/rsc_payload',
      }),
    ).rejects.toMatchObject({
      cause: 'route data failed',
      message: 'route data failed',
    });
  });

  it.each([
    '../AdminPanel',
    'Admin\\Panel',
    'AdminPanel?draft=true',
    'AdminPanel#section',
    'AdminPanel%2FEdit',
  ])('rejects component names that would change the payload URL path: %s', async (componentName) => {
    const { createRscPayloadNode } = loadHelper();

    await expect(
      createRscPayloadNode({
        componentName,
        payloadPath: '/rsc_payload',
      }),
    ).rejects.toThrow('createRscPayloadNode componentName cannot include path or query-string characters.');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it.each([
    '/rsc_payload/../admin',
    '/rsc_payload/%2e%2e/admin',
    '/rsc_payload?preview=true',
    '/rsc_payload#fragment',
    'https://example.test/rsc_payload',
    'rsc\\payload',
  ])('rejects payload paths that would escape the configured Rails path: %s', async (payloadPath) => {
    const { createRscPayloadNode } = loadHelper();

    await expect(
      createRscPayloadNode({
        componentName: 'DashboardPanel',
        payloadPath,
      }),
    ).rejects.toThrow(
      'createRscPayloadNode payloadPath must be a Rails path without traversal, URL, query, hash, or encoded path characters.',
    );
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('allows colon characters in ordinary Rails payload path segments', async () => {
    const { createRscPayloadNode } = loadHelper();
    fetchMock.mockResolvedValue(responseFromText(frame('route data')));

    await expect(
      createRscPayloadNode({
        componentName: 'DashboardPanel',
        payloadPath: '/rsc_payload/v1:tenant',
      }),
    ).resolves.toBe('route data');

    expect(fetchMock).toHaveBeenCalledWith(
      `/rsc_payload/v1:tenant/DashboardPanel?${new URLSearchParams({ props: JSON.stringify({}) })}`,
      { credentials: 'same-origin' },
    );
  });

  it('normalizes protocol-relative payload paths as relative Rails paths', async () => {
    const { createRscPayloadNode } = loadHelper();
    fetchMock.mockResolvedValue(responseFromText(frame('route data')));

    await expect(
      createRscPayloadNode({
        componentName: 'DashboardPanel',
        payloadPath: '//tenant.example/rsc_payload',
      }),
    ).resolves.toBe('route data');

    expect(fetchMock).toHaveBeenCalledWith(
      `/tenant.example/rsc_payload/DashboardPanel?${new URLSearchParams({ props: JSON.stringify({}) })}`,
      { credentials: 'same-origin' },
    );
  });

  it('does not materialize console replay metadata as inline script', async () => {
    const { createRscPayloadNode } = loadHelper();
    const createElementSpy = jest.spyOn(document, 'createElement');
    fetchMock.mockResolvedValue(
      responseFromText(
        frame('flight payload', { consoleReplayScript: '<script>console.log("from rsc")</script>' }),
      ),
    );

    try {
      await createRscPayloadNode({
        componentName: 'StrictCspPanel',
        payloadPath: '/rsc_payload',
      });

      expect(createElementSpy).not.toHaveBeenCalledWith('script');
    } finally {
      createElementSpy.mockRestore();
    }
  });
});
