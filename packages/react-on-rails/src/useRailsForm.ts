/**
 * useRailsForm — a small, Inertia `useForm`-style hook for submitting React
 * forms to plain Rails controller actions.
 *
 * The hook keeps Rails as the mutation layer: it wires up `fetch`, attaches the
 * CSRF token from the standard Rails `<meta name="csrf-token">` tag (via the
 * existing `authenticityToken` utility), sends/receives JSON, and maps the
 * blessed 422 validation-error shape — `{ errors: { field: ["message"] } }` —
 * onto per-field client state. The matching server side is the opt-in
 * `ReactOnRails::Controller::FormResponders#render_model_errors` concern in the
 * react_on_rails gem, but the hook works against any endpoint that returns the
 * documented shape.
 *
 * v1 scope (https://github.com/shakacode/react_on_rails/issues/3872):
 * submit verbs, `data`/`setData`, `errors`, `processing`, CSRF auto-attach, and
 * 422 error mapping. Deferred to a follow-up: `transform`,
 * `recentlySuccessful`, and file-upload `progress` (which requires an
 * XMLHttpRequest or duplex-stream transport; v1 is fetch-only).
 *
 * Success/redirect handling is intentionally minimal and forward-compatible
 * with the client-routing work in issue #3873: the hook never navigates on its
 * own. It surfaces safe JSON `redirect_to` hints through `onSuccess` / the
 * resolved submit result so the app — or a future router integration — decides
 * what to do.
 */

import * as React from 'react';
import { authenticityToken } from './Authenticity.ts';

/** Per-field validation errors: `{ field: ["message", ...] }`. */
export type RailsFormErrors = Record<string, string[]>;

export type RailsFormMethod = 'post' | 'put' | 'patch' | 'delete';

export interface RailsFormSuccessResult {
  ok: true;
  /** Parsed JSON response body, or `null` when the body was empty or not JSON. */
  responseData: unknown;
  /**
   * Redirect target when the server replied with a safe JSON
   * `redirect_to`/`redirectTo` hint. Browser redirect following is disabled for
   * CSRF-bearing submissions; a defensively filtered redirected Response URL is
   * still accepted if a custom fetch implementation returns one.
   * Hints are accepted only when they resolve to the current origin over HTTP(S);
   * non-HTTP schemes such as `javascript:` are ignored.
   * The hook never navigates — pass this to your router or `window.location`.
   * Designed to compose with the client-routing integration in issue #3873.
   */
  redirectTo: string | null;
  response: Response;
}

export interface RailsFormValidationErrorResult {
  ok: false;
  /** Per-field errors mapped from the 422 response body. */
  errors: RailsFormErrors;
  response: Response;
}

export type RailsFormSubmitResult = RailsFormSuccessResult | RailsFormValidationErrorResult;

/** Thrown (as a promise rejection) for non-2xx responses other than a mappable 422. */
export class RailsFormRequestError extends Error {
  /** The response, with its body stream unread — `.json()`/`.text()` work. */
  readonly response: Response;

  /**
   * Parsed JSON body when the hook already read it (a 422 whose body didn't
   * match the documented errors shape); `undefined` otherwise.
   */
  readonly responseBody: unknown;

  constructor(response: Response, responseBody: unknown = undefined) {
    super(`useRailsForm request failed with status ${response.status}`);
    this.name = 'RailsFormRequestError';
    this.response = response;
    this.responseBody = responseBody;
  }
}

export interface RailsFormSubmitOptions {
  /** Extra request headers. JSON and CSRF headers are always applied on top. */
  headers?: Record<string, string>;
  /**
   * Called after a 2xx response. If this callback throws, the exception
   * propagates as the submit promise rejection after form state has settled.
   */
  onSuccess?: (result: RailsFormSuccessResult) => void;
  /** Called after a 422 response whose body matched the documented errors shape. */
  onError?: (errors: RailsFormErrors) => void;
}

export interface UseRailsForm<TData extends object> {
  /** Current form data. */
  data: TData;
  /** Set a single field, merge a partial object, or apply an updater function. */
  setData: {
    <K extends keyof TData>(key: K, value: TData[K]): void;
    (valuesOrUpdater: Partial<TData> | ((previousData: TData) => TData)): void;
  };
  /** Per-field validation errors from the last 422 response (or `setError`). */
  errors: RailsFormErrors;
  hasErrors: boolean;
  /** True while a submission is in flight. */
  processing: boolean;
  /** True once the most recent submission succeeded. Reset when a new one starts. */
  wasSuccessful: boolean;
  /** Submit with an explicit HTTP method. */
  submit: (
    method: RailsFormMethod,
    url: string,
    options?: RailsFormSubmitOptions,
  ) => Promise<RailsFormSubmitResult>;
  post: (url: string, options?: RailsFormSubmitOptions) => Promise<RailsFormSubmitResult>;
  put: (url: string, options?: RailsFormSubmitOptions) => Promise<RailsFormSubmitResult>;
  patch: (url: string, options?: RailsFormSubmitOptions) => Promise<RailsFormSubmitResult>;
  /** Named `delete` on the hook object; `delete` is reserved in some contexts. */
  delete: (url: string, options?: RailsFormSubmitOptions) => Promise<RailsFormSubmitResult>;
  /**
   * Reset all data (no args) or the given fields to their initial values.
   * Clears matching errors and `wasSuccessful`. "Initial values" are the
   * `initialData` captured on first render (Inertia `useForm` semantics) —
   * later prop changes are not tracked; remount the component to re-seed.
   */
  reset: (...fields: Extract<keyof TData, string>[]) => void;
  /** Clear all errors (no args) or the errors for the given fields. */
  clearErrors: (...fields: string[]) => void;
  /** Manually set the errors for one field (e.g. client-side pre-checks). */
  setError: (field: string, messages: string | string[]) => void;
}

const PINNED_RAILS_FORM_HEADER_NAMES = new Set([
  'accept',
  'content-type',
  'x-csrf-token',
  'x-requested-with',
]);

const REQUIRED_REACT_HOOK_NAMES = ['useCallback', 'useEffect', 'useRef', 'useState'] as const;

const assertReactHooksAvailable = (): void => {
  const missingHooks = REQUIRED_REACT_HOOK_NAMES.filter((hookName) => typeof React[hookName] !== 'function');
  if (missingHooks.length > 0) {
    throw new Error(
      `useRailsForm requires React 16.8 or newer because it uses React hooks. Missing React exports: ${missingHooks.join(
        ', ',
      )}.`,
    );
  }
};

assertReactHooksAvailable();

const railsFormJsonHeaders = (customHeaders: Record<string, string> = {}): Record<string, string> => {
  const filteredCustomHeaders = Object.fromEntries(
    Object.entries(customHeaders).filter(
      ([headerName]) => !PINNED_RAILS_FORM_HEADER_NAMES.has(headerName.toLowerCase()),
    ),
  );

  return {
    ...filteredCustomHeaders,
    Accept: 'application/json',
    'Content-Type': 'application/json',
  };
};

const railsFormHeaders = (
  csrfToken: string,
  customHeaders?: Record<string, string>,
): Record<string, string> => ({
  ...railsFormJsonHeaders(customHeaders),
  'X-CSRF-Token': csrfToken,
  'X-Requested-With': 'XMLHttpRequest',
});

const validationMessageToString = (value: unknown): string => {
  switch (typeof value) {
    case 'string':
      return value;
    case 'number':
    case 'boolean':
    case 'bigint':
    case 'symbol':
      return value.toString();
    default: {
      try {
        return JSON.stringify(value) ?? Object.prototype.toString.call(value);
      } catch {
        return Object.prototype.toString.call(value);
      }
    }
  }
};

const toMessageArray = (value: unknown): string[] => {
  if (Array.isArray(value)) {
    return value.filter((message) => message != null).map(validationMessageToString);
  }
  if (value == null) {
    return [];
  }
  // Preserve unexpected custom-endpoint values visibly instead of silently
  // dropping them, but ignore nullish values that cannot be displayed helpfully.
  return [validationMessageToString(value)];
};

/**
 * Normalizes a 422 response body into per-field errors. Returns `null` when the
 * body doesn't match the documented `{ errors: { field: messages } }` shape.
 * An empty `errors` object is still a handled validation response.
 */
const mapValidationErrors = (body: unknown): RailsFormErrors | null => {
  if (typeof body !== 'object' || body === null) {
    return null;
  }
  const { errors } = body as { errors?: unknown };
  if (typeof errors !== 'object' || errors === null || Array.isArray(errors)) {
    return null;
  }
  const errorEntries = Object.entries(errors);
  const mapped: RailsFormErrors = {};
  for (const [field, messages] of errorEntries) {
    const fieldMessages = toMessageArray(messages);
    if (fieldMessages.length > 0) {
      mapped[field] = fieldMessages;
    }
  }
  return mapped;
};

const parseJsonBody = async (response: Response): Promise<unknown> => {
  try {
    return (await response.json()) as unknown;
  } catch {
    return null;
  }
};

const safeJsonRedirectHint = (redirectTo: string): string | null => {
  const normalizedRedirect = redirectTo.trim();
  if (normalizedRedirect.length === 0) {
    return null;
  }

  const currentLocation = typeof window === 'undefined' ? null : window.location;
  if (currentLocation === null) {
    return null;
  }

  try {
    // Match browser relative-URL behavior: query-only hints update the current
    // page query, while root-relative hints like `/posts/1` stay root-relative.
    const parsedRedirect = new URL(normalizedRedirect, currentLocation.href);
    if (
      (parsedRedirect.protocol === 'http:' || parsedRedirect.protocol === 'https:') &&
      parsedRedirect.origin === currentLocation.origin
    ) {
      if (/^https?:\/\//i.test(normalizedRedirect)) {
        return parsedRedirect.href;
      }
      return `${parsedRedirect.pathname}${parsedRedirect.search}${parsedRedirect.hash}`;
    }
  } catch {
    return null;
  }

  return null;
};

const resolveSameOriginRequestUrl = (url: string): string | null => {
  const currentLocation = typeof window === 'undefined' ? null : window.location;
  if (currentLocation === null || typeof document === 'undefined') {
    // No browser origin/document is available in SSR/Node, so same-origin and
    // CSRF guards cannot be enforced. Refuse the submit instead of guessing.
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

const extractRedirectTo = (response: Response, responseData: unknown): string | null => {
  // Native fetch never reaches this when `redirect: 'error'` is set; it throws
  // before returning a redirected Response. Keep the filter for custom fetch
  // implementations and tests that return pre-followed responses.
  if (response.redirected && response.url) {
    return safeJsonRedirectHint(response.url);
  }
  if (typeof responseData === 'object' && responseData !== null) {
    const { redirect_to: redirectSnake, redirectTo: redirectCamel } = responseData as {
      redirect_to?: unknown;
      redirectTo?: unknown;
    };
    if (typeof redirectSnake === 'string') {
      return safeJsonRedirectHint(redirectSnake);
    }
    if (typeof redirectCamel === 'string') {
      return safeJsonRedirectHint(redirectCamel);
    }
  }
  return null;
};

const warnOnPossibleRedirectFetchError = (fetchError: unknown): void => {
  // Keep this development-only: browsers surface `redirect: "error"` failures
  // as opaque TypeErrors, and warning on every production network failure would
  // be noisy without giving end users an actionable recovery path.
  if (process.env.NODE_ENV === 'production' || !(fetchError instanceof TypeError)) {
    return;
  }
  if (!/failed to fetch|networkerror|load failed/i.test(fetchError.message)) {
    return;
  }
  console.warn(
    '[useRailsForm] The request may have been rejected because the server responded with a redirect. ' +
      'useRailsForm requires `render json:` for success responses; Rails `redirect_to` is not supported in v1.',
  );
};

/**
 * React hook for submitting form data to a Rails controller action.
 *
 * ```tsx
 * const form = useRailsForm({ name: '', email: '' });
 * // <input value={form.data.name} onChange={(e) => form.setData('name', e.target.value)} />
 * // {form.errors.name?.[0]}
 * // <form onSubmit={(e) => { e.preventDefault(); void form.post('/contacts'); }}>
 * ```
 *
 * Submissions send `Content-Type: application/json` / `Accept: application/json`
 * with the CSRF token from the Rails csrf-token meta tag. A 422 response with a
 * `{ errors: { field: ["message"] } }` body (the shape rendered by the
 * `render_model_errors` controller concern) populates `errors`; other non-2xx
 * responses reject with `RailsFormRequestError`.
 */
export function useRailsForm<TData extends object>(initialData: TData): UseRailsForm<TData> {
  // Captured once on first render (Inertia useForm semantics): reset() restores
  // these mount-time values even if the initialData prop changes later.
  const initialDataRef = React.useRef(initialData);
  const [data, setDataState] = React.useState<TData>(initialData);
  const [errors, setErrors] = React.useState<RailsFormErrors>({});
  const [processing, setProcessing] = React.useState(false);
  const [wasSuccessful, setWasSuccessful] = React.useState(false);

  // Latest data for submit(). Updated eagerly by commitData (not on render) so
  // `setData(...); submit(...)` in the same tick posts the just-set values —
  // React batches the state update, so `data` itself is stale until re-render.
  const dataRef = React.useRef(data);

  const commitData = React.useCallback((updater: (previousData: TData) => TData) => {
    dataRef.current = updater(dataRef.current);
    setDataState(dataRef.current);
  }, []);

  // Guards against state updates from stale (superseded) or unmounted submissions.
  const submissionIdRef = React.useRef(0);
  const pendingSubmissionsRef = React.useRef(0);
  const mountedRef = React.useRef(true);
  React.useEffect(() => {
    // Re-assigning true is NOT redundant: under React StrictMode (and Fast
    // Refresh) the cleanup runs and the effect re-runs on the same component
    // instance, so without this the ref would stay false after the replay.
    mountedRef.current = true;
    // If a submission settled during the StrictMode cleanup/replay window,
    // finishSubmission could have skipped the visible state update while
    // mountedRef was false. Resync the flag when the same instance remounts.
    if (pendingSubmissionsRef.current === 0) {
      setProcessing(false);
    }
    return () => {
      mountedRef.current = false;
    };
  }, []);

  const setData = React.useCallback(
    (keyOrValues: keyof TData | Partial<TData> | ((previousData: TData) => TData), value?: unknown) => {
      if (typeof keyOrValues === 'function') {
        commitData(keyOrValues);
      } else if (typeof keyOrValues === 'object') {
        commitData((previousData) => ({ ...previousData, ...keyOrValues }));
      } else {
        commitData((previousData) => ({ ...previousData, [keyOrValues]: value }));
      }
    },
    [commitData],
  ) as UseRailsForm<TData>['setData'];

  const clearErrors = React.useCallback((...fields: string[]) => {
    if (fields.length === 0) {
      setErrors({});
      return;
    }
    setErrors((previousErrors) =>
      Object.fromEntries(Object.entries(previousErrors).filter(([field]) => !fields.includes(field))),
    );
  }, []);

  const setError = React.useCallback((field: string, messages: string | string[]) => {
    setErrors((previousErrors) => ({ ...previousErrors, [field]: toMessageArray(messages) }));
  }, []);

  const reset = React.useCallback(
    (...fields: Extract<keyof TData, string>[]) => {
      // A reset starts a fresh editing cycle: a pristine form should not still
      // report the previous submission as successful.
      setWasSuccessful(false);
      if (fields.length === 0) {
        commitData(() => initialDataRef.current);
        clearErrors();
        return;
      }
      commitData((previousData) => {
        const nextData = { ...previousData };
        fields.forEach((field) => {
          nextData[field] = initialDataRef.current[field];
        });
        return nextData;
      });
      clearErrors(...fields);
    },
    [clearErrors, commitData],
  );

  const submit = React.useCallback(
    async (method: RailsFormMethod, url: string, options: RailsFormSubmitOptions = {}) => {
      submissionIdRef.current += 1;
      const submissionId = submissionIdRef.current;
      const isCurrent = () => mountedRef.current && submissionId === submissionIdRef.current;
      const finishSubmission = () => {
        pendingSubmissionsRef.current = Math.max(0, pendingSubmissionsRef.current - 1);
        if (mountedRef.current && pendingSubmissionsRef.current === 0) {
          setProcessing(false);
        }
      };

      if (mountedRef.current && typeof window !== 'undefined') {
        setWasSuccessful(false);
        setErrors({});
        // Safety valve: a prior submission can settle during a StrictMode
        // cleanup window, leaving processing true even with no in-flight work.
        if (pendingSubmissionsRef.current === 0) {
          setProcessing(false);
        }
      }

      const requestUrl = resolveSameOriginRequestUrl(url);
      if (requestUrl === null) {
        throw new Error('useRailsForm can only submit to same-origin URLs.');
      }

      const csrfToken = authenticityToken();
      if (csrfToken === null) {
        throw new Error(
          'useRailsForm requires a <meta name="csrf-token"> tag before submitting. ' +
            'Add <%= csrf_meta_tags %> to your Rails layout.',
        );
      }

      pendingSubmissionsRef.current += 1;
      setProcessing(true);

      let response: Response;
      try {
        response = await fetch(requestUrl, {
          method: method.toUpperCase(),
          credentials: 'same-origin',
          // Never follow redirects while carrying explicit CSRF headers; an
          // open redirect could otherwise leak the token to another origin.
          redirect: 'error',
          headers: railsFormHeaders(csrfToken, options.headers),
          // DELETE bodies are legal per RFC 9110 but are stripped or rejected by
          // many proxies/CDNs in practice — identify the resource in the URL.
          body: method === 'delete' ? undefined : JSON.stringify(dataRef.current),
        });
      } catch (fetchError) {
        finishSubmission();
        warnOnPossibleRedirectFetchError(fetchError);
        throw fetchError;
      }

      if (response.status === 422) {
        // Parse a clone so `response` stays readable if we end up throwing
        // RailsFormRequestError below (e.g. the body doesn't match the shape).
        const body = await parseJsonBody(response.clone());
        const validationErrors = mapValidationErrors(body);
        if (validationErrors !== null) {
          if (isCurrent()) {
            setErrors(validationErrors);
            finishSubmission();
            options.onError?.(validationErrors);
          } else {
            finishSubmission();
          }
          return { ok: false as const, errors: validationErrors, response };
        }
        finishSubmission();
        throw new RailsFormRequestError(response, body);
      }

      if (!response.ok) {
        finishSubmission();
        throw new RailsFormRequestError(response);
      }

      const responseData = await parseJsonBody(response.clone());
      const result: RailsFormSuccessResult = {
        ok: true,
        responseData,
        redirectTo: extractRedirectTo(response, responseData),
        response,
      };
      if (isCurrent()) {
        setErrors({});
        setWasSuccessful(true);
        finishSubmission();
        // Guarded like the state updates: a superseded submission must not
        // fire callbacks (e.g. navigate on redirectTo) after a newer one.
        options.onSuccess?.(result);
      } else {
        finishSubmission();
      }
      return result;
    },
    // Intentionally empty: everything read inside satisfies
    // react-hooks/exhaustive-deps — refs (dataRef, submissionIdRef, mountedRef),
    // useState setters, and module-level imports. If you add a render-scoped
    // value here, it must go in this array.
    [],
  );

  const post = React.useCallback(
    (url: string, options?: RailsFormSubmitOptions) => submit('post', url, options),
    [submit],
  );
  const put = React.useCallback(
    (url: string, options?: RailsFormSubmitOptions) => submit('put', url, options),
    [submit],
  );
  const patch = React.useCallback(
    (url: string, options?: RailsFormSubmitOptions) => submit('patch', url, options),
    [submit],
  );
  const destroy = React.useCallback(
    (url: string, options?: RailsFormSubmitOptions) => submit('delete', url, options),
    [submit],
  );

  return {
    data,
    setData,
    errors,
    hasErrors: Object.keys(errors).length > 0,
    processing,
    wasSuccessful,
    submit,
    post,
    put,
    patch,
    delete: destroy,
    reset,
    clearErrors,
    setError,
  };
}
