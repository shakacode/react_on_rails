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
  headers?: HeadersInit | ((variables: TVariables) => HeadersInit);
}

export interface RailsActionCallOptions {
  headers?: HeadersInit;
  signal?: AbortSignal;
}

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
  const currentLocation = typeof window === 'undefined' ? null : window.location;
  if (currentLocation === null || typeof document === 'undefined') {
    return null;
  }

  try {
    const resolvedUrl = new URL(url, document.baseURI);
    if (
      (resolvedUrl.protocol === 'http:' || resolvedUrl.protocol === 'https:') &&
      resolvedUrl.origin === currentLocation.origin
    ) {
      return resolvedUrl.href;
    }
  } catch {
    return null;
  }

  return null;
};

const parseJsonBody = async (response: Response): Promise<unknown> => {
  try {
    return (await response.json()) as unknown;
  } catch {
    return null;
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

const warnOnDiscardedDeleteBody = (method: string, bodyOption: unknown): void => {
  if (process.env.NODE_ENV === 'production' || method !== 'DELETE' || bodyOption === undefined) {
    return;
  }

  console.warn(
    '[createRailsAction] A `body` option was supplied for a DELETE request but will not be sent. ' +
      'Identify the resource in the URL instead.',
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

  const callRailsAction = async (
    variables?: TVariables,
    callOptions: RailsActionCallOptions = {},
  ): Promise<TResponse> => {
    const typedVariables = variables as TVariables;
    assertBrowserContext();

    const requestUrl = resolveSameOriginRequestUrl(resolvePath(options.path, typedVariables));
    if (requestUrl === null) {
      throw new Error('createRailsAction can only call same-origin Rails action URLs.');
    }

    const csrfToken = authenticityToken();
    if (!csrfToken) {
      throw new Error(
        'createRailsAction requires a <meta name="csrf-token"> tag before submitting. ' +
          'Add <%= csrf_meta_tags %> to your Rails layout.',
      );
    }

    const requestBody = options.body !== undefined ? options.body(typedVariables) : variables;
    const hasJsonBody = method !== 'DELETE' && requestBody !== undefined && requestBody !== null;
    warnOnDiscardedDeleteBody(method, options.body);
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
      const responseBody = await parseJsonBody(response.clone());
      throw new RailsActionRequestError(response, responseBody);
    }

    const responseBody = await parseJsonBody(response);
    return responseBody as TResponse;
  };

  return callRailsAction as RailsActionCaller<TVariables, TResponse>;
}
