import { enableFetchMocks } from 'jest-fetch-mock';

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

const streamFromText = (text: string) =>
  new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(encoder.encode(text));
      controller.close();
    },
  });

const responseFromText = (text: string) =>
  ({
    body: streamFromText(text),
    ok: true,
    status: 200,
    statusText: 'OK',
  }) as Response;

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
        payloadPath: '/rsc_payload/',
        props,
      }),
    ).resolves.toBe('firstsecond');

    expect(fetchMock).toHaveBeenCalledWith(
      `/rsc_payload/RscShowcaseServerPanel?${new URLSearchParams({ props: JSON.stringify(props) })}`,
      { credentials: 'same-origin' },
    );
    expect(createFromReadableStream).toHaveBeenCalledTimes(1);
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

  it.each([
    '../AdminPanel',
    'Admin\\Panel',
    'AdminPanel?draft=true',
    'AdminPanel#section',
    'AdminPanel%2FEdit',
  ])('rejects component names that would change the payload URL path: %s', (componentName) => {
    const { createRscPayloadNode } = loadHelper();

    expect(() =>
      createRscPayloadNode({
        componentName,
        payloadPath: '/rsc_payload',
      }),
    ).toThrow('createRscPayloadNode componentName cannot include path or query-string characters.');
    expect(fetchMock).not.toHaveBeenCalled();
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
