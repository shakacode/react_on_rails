import { createRailsAction, RailsActionRequestError } from '../src/railsAction.ts';

const TEST_CSRF_TOKEN = 'TEST_CSRF_TOKEN';
let csrfMeta: HTMLMetaElement;
let originalFetch: typeof globalThis.fetch;

interface MockResponseOptions {
  status?: number;
  body?: unknown;
}

const mockResponse = (options: MockResponseOptions = {}): Response => {
  const { status = 200, body = null } = options;
  let bodyUsed = false;

  return {
    ok: status >= 200 && status < 300,
    status,
    clone: () => {
      if (bodyUsed) {
        throw new TypeError('body already used');
      }
      return mockResponse(options);
    },
    json: () => {
      if (bodyUsed) {
        return Promise.reject(new TypeError('body already used'));
      }
      bodyUsed = true;
      if (body === null || typeof body === 'string') {
        return Promise.reject(new Error('no JSON body'));
      }
      return Promise.resolve(body);
    },
    text: () => {
      if (bodyUsed) {
        return Promise.reject(new TypeError('body already used'));
      }
      bodyUsed = true;
      return Promise.resolve(typeof body === 'string' ? body : JSON.stringify(body));
    },
  } as unknown as Response;
};

const fetchMock = jest.fn<Promise<Response>, [string, RequestInit]>();

const headerValue = (headers: RequestInit['headers'], name: string): string | null =>
  new Headers(headers).get(name);

beforeAll(() => {
  originalFetch = globalThis.fetch;
  csrfMeta = document.createElement('meta');
  csrfMeta.name = 'csrf-token';
  csrfMeta.content = TEST_CSRF_TOKEN;
  document.head.appendChild(csrfMeta);
  globalThis.fetch = fetchMock as unknown as typeof fetch;
});

afterAll(() => {
  csrfMeta.remove();
  globalThis.fetch = originalFetch;
});

beforeEach(() => {
  fetchMock.mockClear();
  fetchMock.mockResolvedValue(mockResponse({ status: 200, body: { project: { id: 1 } } }));
});

describe('createRailsAction', () => {
  it('posts JSON variables with Rails CSRF headers and parses the typed response', async () => {
    type CreateProjectVariables = { project: { name: string } };
    type CreateProjectResponse = { project: { id: number } };

    const createProject = createRailsAction<CreateProjectVariables, CreateProjectResponse>({
      path: '/api/projects',
    });

    const response = await createProject({ project: { name: 'Apollo' } });

    expect(response.project.id).toBe(1);
    expect(fetchMock).toHaveBeenCalledTimes(1);

    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe(new URL('/api/projects', document.baseURI).href);
    expect(init.method).toBe('POST');
    expect(init.credentials).toBe('same-origin');
    expect(init.redirect).toBe('error');
    expect(init.body).toBe(JSON.stringify({ project: { name: 'Apollo' } }));
    expect(headerValue(init.headers, 'Accept')).toBe('application/json');
    expect(headerValue(init.headers, 'Content-Type')).toBe('application/json');
    expect(headerValue(init.headers, 'X-CSRF-Token')).toBe(TEST_CSRF_TOKEN);
    expect(headerValue(init.headers, 'X-Requested-With')).toBe('XMLHttpRequest');
  });

  it('supports dynamic paths, custom bodies, custom headers, and abort signals', async () => {
    const abortController = new AbortController();
    const updateProject = createRailsAction<{ id: number; name: string }, { ok: true }>({
      method: 'patch',
      path: ({ id }) => `/api/projects/${id}`,
      body: ({ name }) => ({ project: { name } }),
      headers: ({ id }) => ({ 'X-Project-Id': String(id), Accept: 'text/plain' }),
    });

    await updateProject(
      { id: 3, name: 'Hermes' },
      {
        signal: abortController.signal,
        // The meta-tag CSRF token always wins; caller headers cannot override it.
        headers: { 'X-Request-Source': 'test', 'X-CSRF-Token': 'CUSTOM' },
      },
    );

    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe(new URL('/api/projects/3', document.baseURI).href);
    expect(init.method).toBe('PATCH');
    expect(init.signal).toBe(abortController.signal);
    expect(init.body).toBe(JSON.stringify({ project: { name: 'Hermes' } }));
    expect(headerValue(init.headers, 'Accept')).toBe('application/json');
    expect(headerValue(init.headers, 'X-CSRF-Token')).toBe(TEST_CSRF_TOKEN);
    expect(headerValue(init.headers, 'X-Project-Id')).toBe('3');
    expect(headerValue(init.headers, 'X-Request-Source')).toBe('test');
  });

  it('omits the JSON body and content type when called without variables', async () => {
    fetchMock.mockResolvedValueOnce(mockResponse({ status: 204 }));
    const archiveAll = createRailsAction<undefined, null>({
      path: '/api/projects/archive_all',
    });

    await expect(archiveAll()).resolves.toBeNull();

    const [, init] = fetchMock.mock.calls[0];
    expect(init.body).toBeUndefined();
    expect(headerValue(init.headers, 'Content-Type')).toBeNull();
  });

  it('omits the JSON body when a body callback returns null', async () => {
    fetchMock.mockResolvedValueOnce(mockResponse({ status: 204 }));
    const pingProject = createRailsAction<{ id: number }, null>({
      path: ({ id }) => `/api/projects/${id}/ping`,
      body: () => null,
      headers: { 'Content-Type': 'text/plain' },
    });

    await expect(pingProject({ id: 1 })).resolves.toBeNull();

    const [, init] = fetchMock.mock.calls[0];
    expect(init.body).toBeUndefined();
    expect(headerValue(init.headers, 'Content-Type')).toBeNull();
  });

  it('omits the JSON body for DELETE requests even when variables are provided', async () => {
    fetchMock.mockResolvedValueOnce(mockResponse({ status: 204 }));
    const deleteProject = createRailsAction<{ id: number }, null>({
      method: 'DELETE',
      path: ({ id }) => `/api/projects/${id}`,
    });

    await expect(deleteProject({ id: 7 })).resolves.toBeNull();

    const [, init] = fetchMock.mock.calls[0];
    expect(init.method).toBe('DELETE');
    expect(init.body).toBeUndefined();
    expect(headerValue(init.headers, 'Content-Type')).toBeNull();
  });

  it('rejects before fetch when the Rails CSRF meta tag is missing', async () => {
    const csrfMeta = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]');
    csrfMeta?.remove();

    try {
      const createProject = createRailsAction<{ name: string }, { ok: true }>({
        path: '/api/projects',
      });

      await expect(createProject({ name: 'Apollo' })).rejects.toThrow(/csrf-token/);
      expect(fetchMock).not.toHaveBeenCalled();
    } finally {
      if (csrfMeta) {
        document.head.appendChild(csrfMeta);
      }
    }
  });

  it('rejects before fetch when the Rails CSRF meta tag has empty content', async () => {
    const originalContent = csrfMeta.content;
    csrfMeta.content = '';

    try {
      const createProject = createRailsAction<{ name: string }, { ok: true }>({
        path: '/api/projects',
      });

      await expect(createProject({ name: 'Apollo' })).rejects.toThrow(/csrf-token/);
      expect(fetchMock).not.toHaveBeenCalled();
    } finally {
      csrfMeta.content = originalContent;
    }
  });

  it('rejects cross-origin URLs before attaching CSRF headers', async () => {
    const createProject = createRailsAction<{ name: string }, { ok: true }>({
      path: 'https://example.com/projects',
    });

    await expect(createProject({ name: 'Apollo' })).rejects.toThrow(/same-origin Rails action URLs/);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('throws RailsActionRequestError with the parsed response body on non-2xx responses', async () => {
    fetchMock.mockResolvedValueOnce(mockResponse({ status: 422, body: { errors: { name: ['is blank'] } } }));
    const createProject = createRailsAction<{ name: string }, { ok: true }>({
      path: '/api/projects',
    });

    let caughtError: unknown;
    try {
      await createProject({ name: '' });
    } catch (error) {
      caughtError = error;
    }

    expect(caughtError).toBeInstanceOf(RailsActionRequestError);
    if (caughtError instanceof RailsActionRequestError) {
      expect(caughtError.response.status).toBe(422);
      expect(caughtError.responseBody).toEqual({ errors: { name: ['is blank'] } });
    }
  });

  it('leaves the failed response body readable after parsing an error body clone', async () => {
    fetchMock.mockResolvedValueOnce(mockResponse({ status: 500, body: '<html>boom</html>' }));
    const createProject = createRailsAction<{ name: string }, { ok: true }>({
      path: '/api/projects',
    });

    let caughtError: unknown;
    try {
      await createProject({ name: 'Apollo' });
    } catch (error) {
      caughtError = error;
    }

    expect(caughtError).toBeInstanceOf(RailsActionRequestError);
    if (caughtError instanceof RailsActionRequestError) {
      expect(caughtError.responseBody).toBeNull();
      await expect(caughtError.response.text()).resolves.toBe('<html>boom</html>');
    }
  });

  it('warns in development when a fetch rejection looks like a Rails redirect', async () => {
    const consoleWarn = jest.spyOn(console, 'warn').mockImplementation(() => {});
    const redirectError = new TypeError('Failed to fetch');
    fetchMock.mockRejectedValueOnce(redirectError);

    try {
      const createProject = createRailsAction<{ name: string }, { ok: true }>({
        path: '/api/projects',
      });

      await expect(createProject({ name: 'Apollo' })).rejects.toBe(redirectError);
      expect(consoleWarn).toHaveBeenCalledWith(expect.stringContaining('createRailsAction'));
    } finally {
      consoleWarn.mockRestore();
    }
  });
});
