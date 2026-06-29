import { authenticityToken } from './Authenticity.ts';

export type RailsActionMethod = 'POST' | 'PUT' | 'PATCH' | 'DELETE' | 'post' | 'put' | 'patch' | 'delete';

export type RailsActionPath<TVariables> = string | ((variables: TVariables) => string);

export interface RailsActionOptions<TVariables> {
  path: RailsActionPath<TVariables>;
  method?: RailsActionMethod;
  /**
   * Maps variables to the JSON request body. Omit to send variables verbatim;
   * supply `() => null` to send no body when variables only populate the path.
   */
  body?: (variables: TVariables) => unknown;
  /**
   * Additional request headers. Security-critical Rails headers always win.
   * When no JSON body is sent, Content-Type is removed after these headers are merged.
   */
  headers?: HeadersInit | ((variables: TVariables) => HeadersInit);
}

export interface RailsActionCallOptions {
  headers?: HeadersInit;
  signal?: AbortSignal;
}

// Brackets prevent distribution over union TVariables, preserving a single caller signature.
export type RailsActionCaller<TVariables, TResponse> = [TVariables] extends [undefined]
  ? (variables?: undefined, options?: RailsActionCallOptions) => Promise<TResponse>
  : (variables: TVariables, options?: RailsActionCallOptions) => Promise<TResponse>;

export class RailsActionRequestError<TResponseBody = unknown> extends Error {
  readonly response: Response;

  readonly responseBody: TResponseBody;

  constructor(response: Response, responseBody: TResponseBody) {
    super(`Rails action request failed with status ${response.status}`);
    this.name = 'RailsActionRequestError';
    this.response = response;
    this.responseBody = responseBody;
  }
}

const resolveSameOriginRequestUrl = (url: string): string | null => {
  try {
    const resolvedUrl = new URL(url, window.location.href);
    if (
      (resolvedUrl.protocol === 'http:' || resolvedUrl.protocol === 'https:') &&
      resolvedUrl.origin === window.location.origin
    ) {
      return resolvedUrl.href;
    }
  } catch {
    return null;
  }

  return null;
};

const JSON_CONTENT_TYPE_PATTERN = /^(application\/json|[^/]+\/[^;]+\+json)(?:\s*;|$)/i;

const isJsonResponse = (response: Response): boolean =>
  JSON_CONTENT_TYPE_PATTERN.test(response.headers.get('Content-Type') ?? '');

const isAbortError = (error: unknown): boolean =>
  typeof error === 'object' && error !== null && 'name' in error && error.name === 'AbortError';

const parseOptionalJsonBody = async (response: Response): Promise<unknown> => {
  try {
    return (await response.json()) as unknown;
  } catch (error) {
    if (!(error instanceof SyntaxError)) {
      throw error;
    }
    return null;
  }
};

const parseSuccessJsonBody = async (response: Response): Promise<unknown> => {
  if (response.status === 204 || response.status === 205) {
    return null;
  }

  try {
    return (await response.json()) as unknown;
  } catch (error) {
    if (error instanceof SyntaxError && !isJsonResponse(response)) {
      return null;
    }
    throw error;
  }
};

const warnOnPossibleRedirectFetchError = (fetchError: unknown): void => {
  if (process.env.NODE_ENV === 'production' || !(fetchError instanceof TypeError)) {
    return;
  }
  if (!/failed to fetch|networkerror|load failed/i.test(fetchError.message)) {
    return;
  }
  console.warn(
    '[createRailsAction] The request may have failed because the server responded with a redirect or ' +
      'because the network is unavailable. createRailsAction requires JSON responses; Rails `redirect_to` ' +
      'is not supported for mutation endpoints.',
  );
};

const warnOnDiscardedDeleteBody = (method: string, requestBody: unknown): boolean => {
  if (
    process.env.NODE_ENV === 'production' ||
    method !== 'DELETE' ||
    requestBody === undefined ||
    requestBody === null
  ) {
    return false;
  }

  console.warn(
    '[createRailsAction] A DELETE request resolved a JSON body that will not be sent. ' +
      'Use `body: () => null` when variables only populate the path, or identify the resource in the URL instead.',
  );
  return true;
};

const nonJsonBodyTypeName = (requestBody: unknown): string | null => {
  if (typeof FormData !== 'undefined' && requestBody instanceof FormData) {
    return 'FormData';
  }
  if (typeof Blob !== 'undefined' && requestBody instanceof Blob) {
    return 'Blob';
  }
  if (typeof URLSearchParams !== 'undefined' && requestBody instanceof URLSearchParams) {
    return 'URLSearchParams';
  }
  if (typeof ArrayBuffer !== 'undefined' && requestBody instanceof ArrayBuffer) {
    return 'ArrayBuffer';
  }
  if (typeof ArrayBuffer !== 'undefined' && ArrayBuffer.isView(requestBody)) {
    return requestBody.constructor.name || 'ArrayBufferView';
  }
  if (typeof ReadableStream !== 'undefined' && requestBody instanceof ReadableStream) {
    return 'ReadableStream';
  }
  return null;
};

const assertJsonBodyValue = (requestBody: unknown, hasJsonBody: boolean): void => {
  if (!hasJsonBody) {
    return;
  }

  const bodyTypeName = nonJsonBodyTypeName(requestBody);
  if (bodyTypeName === null) {
    return;
  }

  throw new TypeError(
    `[createRailsAction] The request body resolved to ${bodyTypeName}, which cannot be JSON serialized correctly. ` +
      'Return a plain JSON value, null, or undefined instead.',
  );
};

const mergeHeaders = (...headersList: Array<HeadersInit | undefined>): Headers => {
  const headers = new Headers();

  headersList.forEach((headersInit) => {
    if (headersInit === undefined) {
      return;
    }
    new Headers(headersInit).forEach((value, key) => {
      headers.set(key, value);
    });
  });

  return headers;
};

const buildRailsActionHeaders = (
  csrfToken: string,
  hasJsonBody: boolean,
  ...headersList: Array<HeadersInit | undefined>
): Headers => {
  const headers = mergeHeaders({ Accept: 'application/json' }, ...headersList);
  if (hasJsonBody) {
    headers.set('Content-Type', 'application/json');
  } else {
    headers.delete('Content-Type');
  }
  headers.set('X-CSRF-Token', csrfToken);
  headers.set('X-Requested-With', 'XMLHttpRequest');
  return headers;
};

const resolvePath = <TVariables>(path: RailsActionPath<TVariables>, variables: TVariables): string =>
  typeof path === 'function' ? path(variables) : path;

const resolveHeaders = <TVariables>(
  headers: RailsActionOptions<TVariables>['headers'],
  variables: TVariables,
): HeadersInit | undefined => (typeof headers === 'function' ? headers(variables) : headers);

const assertBrowserContext = (): void => {
  if (typeof window === 'undefined' || typeof document === 'undefined') {
    throw new Error('createRailsAction can only be used in browser contexts.');
  }
};

/**
 * Creates a CSRF-aware JSON caller for a Rails controller action.
 *
 * Supply the response generic from the generated Rails response declarations:
 *
 * ```ts
 * type CreateProjectResponse = RailsResponseType<'projects.create'>;
 * const createProject = createRailsAction<CreateProjectVariables, CreateProjectResponse>({
 *   path: '/api/projects',
 * });
 * ```
 *
 * The returned function is directly usable as a TanStack Query `mutationFn`.
 * It always requests JSON, rejects browser-followed redirects, and resolves 204 or non-JSON success
 * responses as `null`. Include `null` in `TResponse` when a successful empty response is expected.
 * A 200 response with `text/html`, such as an unexpected Rails error page, also resolves as `null`.
 * `options.headers` can override the default `Accept: application/json`; include `null` in `TResponse`
 * when that custom Accept header may produce a successful non-JSON response.
 * Omitting `body` sends `variables` as the JSON body verbatim; supply `body` to map or filter fields before
 * serialization.
 * When `variables` only populate `path`, supply `body: () => null` or a mapper to avoid forwarding them.
 * Return `null` or `undefined` from `body` when the request should not send JSON. DELETE requests never
 * send a JSON body; identify the resource in the URL instead.
 */
export function createRailsAction<TVariables = undefined, TResponse = unknown>(
  options: RailsActionOptions<TVariables>,
): RailsActionCaller<TVariables, TResponse> {
  const method = (options.method ?? 'POST').toUpperCase();
  // DELETE body discard is an action configuration problem, so warn at most once per DELETE action factory.
  let warnedOnDiscardedDeleteBody = method !== 'DELETE';

  const callRailsAction = async (
    variables?: TVariables,
    callOptions: RailsActionCallOptions = {},
  ): Promise<TResponse> => {
    // The public conditional type only permits omitted variables when TVariables is undefined.
    const typedVariables = variables as TVariables;
    assertBrowserContext();

    const resolvedPath = resolvePath(options.path, typedVariables);
    const requestUrl = resolveSameOriginRequestUrl(resolvedPath);
    if (requestUrl === null) {
      throw new Error(
        `createRailsAction can only call same-origin Rails action URLs (attempted: ${resolvedPath}).`,
      );
    }

    const csrfToken = authenticityToken()?.trim();
    if (!csrfToken) {
      throw new Error(
        'createRailsAction requires a <meta name="csrf-token"> tag before submitting. ' +
          'Add <%= csrf_meta_tags %> to your Rails layout.',
      );
    }

    const requestBody = options.body !== undefined ? options.body(typedVariables) : typedVariables;
    const hasJsonBody = method !== 'DELETE' && requestBody !== undefined && requestBody !== null;
    if (!warnedOnDiscardedDeleteBody) {
      warnedOnDiscardedDeleteBody = warnOnDiscardedDeleteBody(method, requestBody);
    }
    assertJsonBodyValue(requestBody, hasJsonBody);
    let response: Response;
    try {
      response = await fetch(requestUrl, {
        method,
        mode: 'same-origin',
        credentials: 'same-origin',
        redirect: 'error',
        signal: callOptions.signal,
        headers: buildRailsActionHeaders(
          csrfToken,
          hasJsonBody,
          resolveHeaders(options.headers, typedVariables),
          callOptions.headers,
        ),
        body: hasJsonBody ? JSON.stringify(requestBody) : undefined,
      });
    } catch (fetchError) {
      warnOnPossibleRedirectFetchError(fetchError);
      throw fetchError;
    }

    if (!response.ok) {
      // Keep this clone before any error-body reads so callers can still inspect the original response body.
      let responseBody: unknown = null;
      try {
        responseBody = await parseOptionalJsonBody(response.clone());
      } catch (bodyReadError) {
        if (isAbortError(bodyReadError)) {
          throw bodyReadError;
        }
        responseBody = null;
      }
      throw new RailsActionRequestError(response, responseBody);
    }

    const responseBody = await parseSuccessJsonBody(response);
    return responseBody as TResponse;
  };

  return callRailsAction as RailsActionCaller<TVariables, TResponse>;
}
