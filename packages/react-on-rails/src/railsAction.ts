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

export interface RailsActionMutationFunctionContext {
  client?: unknown;
  meta?: unknown;
  mutationKey?: readonly unknown[];
}

export type RailsActionCallerOptions = RailsActionCallOptions | RailsActionMutationFunctionContext;

// Brackets prevent distribution over union TVariables, preserving a single caller signature.
export type RailsActionCaller<TVariables, TResponse> = [TVariables] extends [undefined]
  ? (variables?: undefined, options?: RailsActionCallerOptions) => Promise<TResponse>
  : (variables: TVariables, options?: RailsActionCallerOptions) => Promise<TResponse>;

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
    const resolvedUrl = new URL(url, document.baseURI);
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

const nonJsonBodyTypeName = (requestBody: unknown, seenObjects = new WeakSet()): string | null => {
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
  if (typeof Map !== 'undefined' && requestBody instanceof Map) {
    return 'Map';
  }
  if (typeof Set !== 'undefined' && requestBody instanceof Set) {
    return 'Set';
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

  if (seenObjects.has(requestBody)) {
    return null;
  }
  seenObjects.add(requestBody);

  const nestedValues = Array.isArray(requestBody)
    ? requestBody
    : Object.values(requestBody as Record<string, unknown>);
  for (const nestedValue of nestedValues) {
    const nestedTypeName = nonJsonBodyTypeName(nestedValue, seenObjects);
    if (nestedTypeName !== null) {
      return nestedTypeName;
    }
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

const stringifyJsonBody = (requestBody: unknown): string => {
  try {
    return JSON.stringify(requestBody);
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

const isMutationFunctionContext = (callOptions: object): boolean =>
  hasOwnProperty(callOptions, 'client') ||
  hasOwnProperty(callOptions, 'meta') ||
  hasOwnProperty(callOptions, 'mutationKey');

function callOptionsValue(callOptions: RailsActionCallerOptions, key: 'signal'): AbortSignal | undefined;
function callOptionsValue(callOptions: RailsActionCallerOptions, key: 'headers'): HeadersInit | undefined;
function callOptionsValue(
  callOptions: RailsActionCallerOptions,
  key: keyof RailsActionCallOptions,
): RailsActionCallOptions[keyof RailsActionCallOptions] | undefined {
  if (typeof callOptions !== 'object' || callOptions === null || isMutationFunctionContext(callOptions)) {
    return undefined;
  }

  return hasOwnProperty(callOptions, key) ? (callOptions as RailsActionCallOptions)[key] : undefined;
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
    callOptions: RailsActionCallerOptions = {},
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
    assertJsonBodyValue(requestBody, hasJsonBody);
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
        body: hasJsonBody ? stringifyJsonBody(requestBody) : undefined,
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
