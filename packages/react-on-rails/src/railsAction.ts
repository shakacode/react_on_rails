import { authenticityToken } from './Authenticity.ts';

export type RailsActionMethod = 'POST' | 'PUT' | 'PATCH' | 'DELETE' | 'post' | 'put' | 'patch' | 'delete';

export type RailsActionPath<TVariables> = string | ((variables: TVariables) => string);

export interface RailsActionOptions<TVariables> {
  path: RailsActionPath<TVariables>;
  method?: RailsActionMethod;
  /**
   * Maps variables to the JSON request body. Omit to send variables verbatim;
   * supply `() => null` to send no body when variables only populate the path.
   * DELETE requests never send a body; identify the resource in the URL instead.
   */
  body?: (variables: TVariables) => unknown;
  /**
   * Additional request headers. `X-CSRF-Token`, `X-Requested-With`, and the JSON-body
   * `Content-Type` are controlled by this helper. `Accept` defaults to `application/json`
   * but can be overridden here. When no JSON body is sent, `Content-Type` is removed after
   * these headers are merged.
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

  readonly cause?: unknown;

  constructor(response: Response, responseBody: TResponseBody, options: { cause?: unknown } = {}) {
    super(`Rails action request failed with status ${response.status}`);
    this.name = 'RailsActionRequestError';
    this.response = response;
    this.responseBody = responseBody;
    if (options.cause !== undefined) {
      Object.defineProperty(this, 'cause', {
        configurable: true,
        value: options.cause,
        writable: true,
      });
    }
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

const JSON_CONTENT_TYPE_PATTERN = /^(application\/json|[^/]+\/[^;]+\+json)(?:\s*;|\s*$)/i;

const isJsonResponse = (response: Response): boolean =>
  JSON_CONTENT_TYPE_PATTERN.test(response.headers.get('Content-Type') ?? '');

const isAbortError = (error: unknown): boolean =>
  typeof error === 'object' && error !== null && 'name' in error && error.name === 'AbortError';

const parseOptionalJsonBody = async (response: Response): Promise<unknown> => {
  if (!isJsonResponse(response)) {
    return null;
  }

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

  if (!isJsonResponse(response)) {
    return null;
  }

  const responseText = await response.text();
  return responseText.trim() === '' ? null : (JSON.parse(responseText) as unknown);
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

const warnOnDiscardedDeleteBody = (requestBody: unknown): boolean => {
  if (requestBody === undefined || requestBody === null) {
    return false;
  }

  console.warn(
    '[createRailsAction] A DELETE request resolved a JSON body that will not be sent. ' +
      'Use `body: () => null` when variables only populate the path, or identify the resource in the URL instead.',
  );
  return true;
};

const warnOnImplicitBodyWithDynamicPath = (): void => {
  console.warn(
    '[createRailsAction] A dynamic path with no `body` mapper sends all variables as the JSON body. ' +
      'Supply `body` to choose which fields are serialized, or `body: () => null` when variables only populate the path.',
  );
};

const nonJsonBodyTypeName = (requestBody: unknown): string | null => {
  if (requestBody === undefined) {
    return 'undefined';
  }
  if (typeof requestBody === 'number' && !Number.isFinite(requestBody)) {
    return 'non-finite number';
  }
  if (typeof Date !== 'undefined' && requestBody instanceof Date && Number.isNaN(requestBody.getTime())) {
    return 'invalid Date';
  }
  if (
    typeof Number !== 'undefined' &&
    requestBody instanceof Number &&
    !Number.isFinite(requestBody.valueOf())
  ) {
    return 'non-finite Number';
  }
  if (typeof FormData !== 'undefined' && requestBody instanceof FormData) {
    return 'FormData';
  }
  if (typeof File !== 'undefined' && requestBody instanceof File) {
    return 'File';
  }
  if (typeof Blob !== 'undefined' && requestBody instanceof Blob) {
    return 'Blob';
  }
  if (typeof Headers !== 'undefined' && requestBody instanceof Headers) {
    return 'Headers';
  }
  if (typeof Request !== 'undefined' && requestBody instanceof Request) {
    return 'Request';
  }
  if (typeof Response !== 'undefined' && requestBody instanceof Response) {
    return 'Response';
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
  if (typeof Map !== 'undefined' && requestBody instanceof Map) {
    return 'Map';
  }
  if (typeof Set !== 'undefined' && requestBody instanceof Set) {
    return 'Set';
  }
  if (typeof WeakMap !== 'undefined' && requestBody instanceof WeakMap) {
    return 'WeakMap';
  }
  if (typeof WeakSet !== 'undefined' && requestBody instanceof WeakSet) {
    return 'WeakSet';
  }
  if (typeof Error !== 'undefined' && requestBody instanceof Error) {
    return requestBody.name || 'Error';
  }
  if (typeof RegExp !== 'undefined' && requestBody instanceof RegExp) {
    return 'RegExp';
  }
  if (typeof requestBody === 'bigint') {
    return 'BigInt';
  }
  if (typeof requestBody === 'function') {
    return 'Function';
  }
  if (typeof requestBody === 'symbol') {
    return 'Symbol';
  }
  if (typeof ReadableStream !== 'undefined' && requestBody instanceof ReadableStream) {
    return 'ReadableStream';
  }

  if (typeof requestBody !== 'object' || requestBody === null) {
    return null;
  }

  const maybeThenable = requestBody as { then?: unknown };
  if (typeof maybeThenable.then === 'function') {
    return 'Promise';
  }

  return null;
};

const preSerializationNonJsonBodyTypeName = (
  requestBody: unknown,
  activeObjects: Set<object> = new Set(),
): string | null => {
  const bodyTypeName = nonJsonBodyTypeName(requestBody);
  if (bodyTypeName !== null) {
    return bodyTypeName;
  }
  if (typeof requestBody !== 'object' || requestBody === null) {
    return null;
  }

  const objectBody = requestBody as { toJSON?: unknown };
  if (typeof objectBody.toJSON === 'function') {
    return null;
  }
  if (activeObjects.has(requestBody)) {
    return 'circular object';
  }
  activeObjects.add(requestBody);

  try {
    const values = Array.isArray(requestBody)
      ? requestBody
      : Object.values(requestBody as Record<string, unknown>);
    for (const value of values) {
      const nestedBodyTypeName = preSerializationNonJsonBodyTypeName(value, activeObjects);
      if (nestedBodyTypeName !== null) {
        return nestedBodyTypeName;
      }
    }

    return null;
  } finally {
    activeObjects.delete(requestBody);
  }
};

const jsonBodyTypeError = (bodyTypeName: string): TypeError =>
  new TypeError(
    `[createRailsAction] The request body resolved to ${bodyTypeName}, which cannot be JSON serialized correctly. ` +
      'Return a plain JSON value, null, or undefined instead.',
  );

const originalJsonBodyValue = (holder: unknown, key: string, rootBody: unknown): unknown => {
  if (key === '') {
    return rootBody;
  }
  if (typeof holder !== 'object' || holder === null) {
    return undefined;
  }
  return (holder as Record<string, unknown>)[key];
};

const stringifyJsonBody = (requestBody: unknown): string => {
  try {
    const bodyTypeName = preSerializationNonJsonBodyTypeName(requestBody);
    if (bodyTypeName !== null) {
      throw jsonBodyTypeError(bodyTypeName);
    }

    const serializedBody = JSON.stringify(
      requestBody,
      function replaceJsonBodyValue(this: unknown, key, value: unknown) {
        const originalValue = originalJsonBodyValue(this, key, requestBody);
        const originalBodyTypeName = nonJsonBodyTypeName(originalValue);
        if (originalBodyTypeName !== null) {
          throw jsonBodyTypeError(originalBodyTypeName);
        }

        const replacedBodyTypeName = nonJsonBodyTypeName(value);
        if (replacedBodyTypeName !== null) {
          throw jsonBodyTypeError(replacedBodyTypeName);
        }

        return value;
      },
    );
    if (serializedBody === undefined) {
      throw jsonBodyTypeError('undefined');
    }
    return serializedBody;
  } catch (error) {
    if (error instanceof TypeError && /BigInt/i.test(error.message)) {
      throw new TypeError(
        '[createRailsAction] The request body contains a BigInt value, which cannot be JSON serialized correctly. ' +
          'Convert BigInt values to strings or numbers before returning the body.',
      );
    }
    throw error;
  }
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

const hasOwnProperty = (value: object, key: PropertyKey): boolean =>
  Object.prototype.hasOwnProperty.call(value, key);

function callOptionsValue(callOptions: RailsActionCallOptions, key: 'signal'): AbortSignal | undefined;
function callOptionsValue(callOptions: RailsActionCallOptions, key: 'headers'): HeadersInit | undefined;
function callOptionsValue(
  callOptions: RailsActionCallOptions,
  key: keyof RailsActionCallOptions,
): RailsActionCallOptions[keyof RailsActionCallOptions] | undefined {
  if (typeof callOptions !== 'object' || callOptions === null) {
    return undefined;
  }

  return hasOwnProperty(callOptions, key) ? callOptions[key] : undefined;
}

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
 * Body values that would serialize lossy or outside JSON, including nested `undefined`, `BigInt`, and
 * non-finite numbers, are rejected before `fetch` runs.
 * When `variables` only populate `path`, supply `body: () => null` or a mapper to avoid forwarding them.
 * Return `null` or `undefined` from `body` when the request should not send JSON. DELETE requests never
 * send a JSON body; identify the resource in the URL instead.
 */
export function createRailsAction<TVariables = undefined, TResponse = unknown>(
  options: RailsActionOptions<TVariables>,
): RailsActionCaller<TVariables, TResponse> {
  const method = (options.method ?? 'POST').toUpperCase();
  // DELETE body discard is an action configuration problem, so warn at most once per DELETE action factory.
  let warnedOnDiscardedDeleteBody = method !== 'DELETE' || process.env.NODE_ENV === 'production';
  let warnedOnImplicitDynamicPathBody =
    method === 'DELETE' ||
    typeof options.path !== 'function' ||
    options.body !== undefined ||
    process.env.NODE_ENV === 'production';

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
        'createRailsAction can only call same-origin Rails action URLs. ' +
          'Ensure the path resolves to the same origin as the current page.',
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
    const shouldWarnOnDiscardedDeleteBody =
      !warnedOnDiscardedDeleteBody && requestBody !== undefined && requestBody !== null;
    const shouldWarnOnImplicitDynamicPathBody = !warnedOnImplicitDynamicPathBody && hasJsonBody;
    const serializedRequestBody = hasJsonBody ? stringifyJsonBody(requestBody) : undefined;
    if (shouldWarnOnDiscardedDeleteBody) {
      warnOnDiscardedDeleteBody(requestBody);
      warnedOnDiscardedDeleteBody = true;
    }
    if (shouldWarnOnImplicitDynamicPathBody) {
      warnOnImplicitBodyWithDynamicPath();
      warnedOnImplicitDynamicPathBody = true;
    }
    let response: Response;
    try {
      response = await fetch(requestUrl, {
        method,
        mode: 'same-origin',
        credentials: 'same-origin',
        redirect: 'error',
        signal: callOptionsValue(callOptions, 'signal'),
        headers: buildRailsActionHeaders(
          csrfToken,
          hasJsonBody,
          resolveHeaders(options.headers, typedVariables),
          callOptionsValue(callOptions, 'headers'),
        ),
        body: serializedRequestBody,
      });
    } catch (fetchError) {
      warnOnPossibleRedirectFetchError(fetchError);
      throw fetchError;
    }

    if (!response.ok) {
      // Keep this clone before any error-body reads so callers can still inspect the original response body.
      let responseBody: unknown = null;
      let bodyReadError: unknown;
      try {
        responseBody = await parseOptionalJsonBody(response.clone());
      } catch (error) {
        if (isAbortError(error)) {
          throw error;
        }
        bodyReadError = error;
        responseBody = null;
      }
      throw new RailsActionRequestError(response, responseBody, { cause: bodyReadError });
    }

    const responseBody = await parseSuccessJsonBody(response);
    return responseBody as TResponse;
  };

  return callRailsAction as RailsActionCaller<TVariables, TResponse>;
}
