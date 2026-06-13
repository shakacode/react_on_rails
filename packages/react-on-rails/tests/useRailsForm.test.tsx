/**
 * Tests for the useRailsForm hook: submit verbs, CSRF header attach,
 * 422 validation-error mapping, and the processing lifecycle.
 */

import * as React from 'react';
import { act, fireEvent, render, renderHook, screen, waitFor } from '@testing-library/react';
import { useRailsForm, RailsFormRequestError } from '../src/useRailsForm.ts';

const TEST_CSRF_TOKEN = 'TEST_CSRF_TOKEN';

interface MockResponseOptions {
  status?: number;
  body?: unknown;
  redirected?: boolean;
  url?: string;
}

// Minimal structural stand-in for the fetch Response (jsdom has no fetch).
const mockResponse = (options: MockResponseOptions = {}): Response => {
  const { status = 200, body = null, redirected = false, url = '' } = options;
  return {
    ok: status >= 200 && status < 300,
    status,
    redirected,
    url,
    json: () => (body === null ? Promise.reject(new Error('no body')) : Promise.resolve(body)),
    clone: () => mockResponse(options),
  } as unknown as Response;
};

const fetchMock = jest.fn<Promise<Response>, [string, RequestInit]>();

beforeAll(() => {
  const meta = document.createElement('meta');
  meta.name = 'csrf-token';
  meta.content = TEST_CSRF_TOKEN;
  document.head.appendChild(meta);
  globalThis.fetch = fetchMock as unknown as typeof fetch;
});

beforeEach(() => {
  fetchMock.mockResolvedValue(mockResponse({ status: 200, body: {} }));
});

describe('useRailsForm', () => {
  describe('request building', () => {
    it('posts JSON data with CSRF and Accept headers attached', async () => {
      const { result } = renderHook(() => useRailsForm({ name: 'Justin', email: '' }));

      await act(async () => {
        await result.current.post('/contact_messages');
      });

      expect(fetchMock).toHaveBeenCalledTimes(1);
      const [url, init] = fetchMock.mock.calls[0];
      expect(url).toBe('/contact_messages');
      expect(init.method).toBe('POST');
      expect(init.credentials).toBe('same-origin');
      expect(init.body).toBe(JSON.stringify({ name: 'Justin', email: '' }));
      expect(init.headers).toEqual({
        Accept: 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': TEST_CSRF_TOKEN,
        'X-Requested-With': 'XMLHttpRequest',
      });
    });

    it('merges custom headers but never drops the CSRF header', async () => {
      const { result } = renderHook(() => useRailsForm({ a: 1 }));

      await act(async () => {
        await result.current.post('/things', { headers: { 'X-Custom': 'yes' } });
      });

      const [, init] = fetchMock.mock.calls[0];
      expect(init.headers).toMatchObject({ 'X-Custom': 'yes', 'X-CSRF-Token': TEST_CSRF_TOKEN });
    });

    it.each([
      ['put', 'PUT'],
      ['patch', 'PATCH'],
      ['delete', 'DELETE'],
    ] as const)('%s() submits with the %s method', async (verb, expectedMethod) => {
      const { result } = renderHook(() => useRailsForm({ a: 1 }));

      await act(async () => {
        await result.current[verb]('/things/1');
      });

      expect(fetchMock.mock.calls[0][1].method).toBe(expectedMethod);
    });

    it('omits the request body for delete()', async () => {
      // DELETE bodies are widely stripped by proxies/CDNs; the resource id
      // belongs in the URL.
      const { result } = renderHook(() => useRailsForm({ a: 1 }));

      await act(async () => {
        await result.current.delete('/things/1');
      });

      expect(fetchMock.mock.calls[0][1].body).toBeUndefined();
    });

    it('accepts a named interface as the form-data type', async () => {
      // Type-level regression: the generic must not require a string index
      // signature (a plain interface has none).
      interface ContactFormData {
        name: string;
        email: string;
      }
      const initial: ContactFormData = { name: '', email: '' };
      const { result } = renderHook(() => useRailsForm<ContactFormData>(initial));

      act(() => {
        result.current.setData('name', 'Ada');
      });

      expect(result.current.data).toEqual({ name: 'Ada', email: '' });
    });

    it('submit() accepts an explicit method', async () => {
      const { result } = renderHook(() => useRailsForm({ a: 1 }));

      await act(async () => {
        await result.current.submit('patch', '/things/1');
      });

      expect(fetchMock.mock.calls[0][1].method).toBe('PATCH');
    });

    it('submits the latest data after setData updates', async () => {
      const { result } = renderHook(() => useRailsForm({ name: '', email: '' }));

      act(() => {
        result.current.setData('name', 'Ada');
      });
      act(() => {
        result.current.setData({ email: 'ada@example.com' });
      });

      await act(async () => {
        await result.current.post('/contact_messages');
      });

      expect(fetchMock.mock.calls[0][1].body).toBe(JSON.stringify({ name: 'Ada', email: 'ada@example.com' }));
    });

    it('submits values set by setData in the same tick as the submit', async () => {
      // React batches the state update, so without eager ref bookkeeping the
      // fetch body would serialize the pre-setData values.
      const { result } = renderHook(() => useRailsForm({ name: '', captchaToken: '' }));

      await act(async () => {
        result.current.setData('captchaToken', 'tok-123');
        await result.current.post('/contact_messages');
      });

      expect(fetchMock.mock.calls[0][1].body).toBe(JSON.stringify({ name: '', captchaToken: 'tok-123' }));
    });
  });

  describe('processing lifecycle', () => {
    it('is true while the request is in flight and false afterwards', async () => {
      let resolveFetch!: (response: Response) => void;
      fetchMock.mockReturnValue(
        new Promise<Response>((resolve) => {
          resolveFetch = resolve;
        }),
      );
      const { result } = renderHook(() => useRailsForm({ a: 1 }));
      expect(result.current.processing).toBe(false);

      let submitPromise: Promise<unknown>;
      act(() => {
        submitPromise = result.current.post('/things');
      });
      await waitFor(() => expect(result.current.processing).toBe(true));

      act(() => {
        resolveFetch(mockResponse({ status: 200, body: {} }));
      });
      await act(async () => {
        await submitPromise;
      });
      expect(result.current.processing).toBe(false);
    });

    it('clears processing when the network request rejects', async () => {
      fetchMock.mockRejectedValue(new TypeError('network down'));
      const { result } = renderHook(() => useRailsForm({ a: 1 }));

      await act(async () => {
        await expect(result.current.post('/things')).rejects.toThrow('network down');
      });

      expect(result.current.processing).toBe(false);
    });
  });

  describe('422 validation-error mapping', () => {
    it('maps the { errors: { field: [messages] } } body onto per-field errors', async () => {
      fetchMock.mockResolvedValue(
        mockResponse({
          status: 422,
          body: { errors: { name: ["can't be blank"], email: ['is invalid', "can't be blank"] } },
        }),
      );
      const onError = jest.fn();
      const { result } = renderHook(() => useRailsForm({ name: '', email: '' }));

      let submitResult: Awaited<ReturnType<typeof result.current.post>>;
      await act(async () => {
        submitResult = await result.current.post('/contact_messages', { onError });
      });

      expect(result.current.errors).toEqual({
        name: ["can't be blank"],
        email: ['is invalid', "can't be blank"],
      });
      expect(result.current.hasErrors).toBe(true);
      expect(result.current.processing).toBe(false);
      expect(result.current.wasSuccessful).toBe(false);
      expect(onError).toHaveBeenCalledWith({
        name: ["can't be blank"],
        email: ['is invalid', "can't be blank"],
      });
      expect(submitResult!.ok).toBe(false);
    });

    it('normalizes single-string error messages to arrays', async () => {
      fetchMock.mockResolvedValue(
        mockResponse({ status: 422, body: { errors: { name: "can't be blank" } } }),
      );
      const { result } = renderHook(() => useRailsForm({ name: '' }));

      await act(async () => {
        await result.current.post('/contact_messages');
      });

      expect(result.current.errors).toEqual({ name: ["can't be blank"] });
    });

    it('rejects when a 422 body does not match the errors shape', async () => {
      fetchMock.mockResolvedValue(mockResponse({ status: 422, body: { message: 'nope' } }));
      const { result } = renderHook(() => useRailsForm({ name: '' }));

      await act(async () => {
        await expect(result.current.post('/contact_messages')).rejects.toThrow(RailsFormRequestError);
      });

      expect(result.current.errors).toEqual({});
      expect(result.current.processing).toBe(false);
    });

    it('keeps the response readable and exposes responseBody on an unmappable 422', async () => {
      fetchMock.mockResolvedValue(mockResponse({ status: 422, body: { message: 'nope' } }));
      const { result } = renderHook(() => useRailsForm({ name: '' }));

      let caught: RailsFormRequestError | undefined;
      await act(async () => {
        try {
          await result.current.post('/contact_messages');
        } catch (error) {
          caught = error as RailsFormRequestError;
        }
      });

      expect(caught).toBeInstanceOf(RailsFormRequestError);
      // The hook parsed a clone, so the original body stream is still readable...
      await expect(caught!.response.json()).resolves.toEqual({ message: 'nope' });
      // ...and the already-parsed body is exposed for convenience.
      expect(caught!.responseBody).toEqual({ message: 'nope' });
    });

    it('clears stale errors after a subsequent successful submit', async () => {
      fetchMock.mockResolvedValueOnce(
        mockResponse({ status: 422, body: { errors: { name: ["can't be blank"] } } }),
      );
      const { result } = renderHook(() => useRailsForm({ name: '' }));

      await act(async () => {
        await result.current.post('/contact_messages');
      });
      expect(result.current.hasErrors).toBe(true);

      fetchMock.mockResolvedValueOnce(mockResponse({ status: 201, body: { message: 'ok' } }));
      await act(async () => {
        await result.current.post('/contact_messages');
      });

      expect(result.current.errors).toEqual({});
      expect(result.current.hasErrors).toBe(false);
      expect(result.current.wasSuccessful).toBe(true);
    });
  });

  describe('success handling', () => {
    it('exposes wasSuccessful, the parsed body, and a JSON redirect hint', async () => {
      fetchMock.mockResolvedValue(
        mockResponse({ status: 201, body: { message: 'created', redirect_to: '/posts/1' } }),
      );
      const onSuccess = jest.fn();
      const { result } = renderHook(() => useRailsForm({ title: 'Hi' }));

      let submitResult: Awaited<ReturnType<typeof result.current.post>>;
      await act(async () => {
        submitResult = await result.current.post('/posts', { onSuccess });
      });

      expect(result.current.wasSuccessful).toBe(true);
      expect(submitResult!).toMatchObject({
        ok: true,
        responseData: { message: 'created', redirect_to: '/posts/1' },
        redirectTo: '/posts/1',
      });
      expect(onSuccess).toHaveBeenCalledWith(expect.objectContaining({ ok: true, redirectTo: '/posts/1' }));
    });

    it('reports the followed redirect URL when fetch followed a redirect', async () => {
      fetchMock.mockResolvedValue(
        mockResponse({ status: 200, body: null, redirected: true, url: 'http://localhost/posts/1' }),
      );
      const { result } = renderHook(() => useRailsForm({ title: 'Hi' }));

      let submitResult: Awaited<ReturnType<typeof result.current.post>>;
      await act(async () => {
        submitResult = await result.current.post('/posts');
      });

      expect(submitResult!).toMatchObject({
        ok: true,
        responseData: null,
        redirectTo: 'http://localhost/posts/1',
      });
    });

    it('rejects with RailsFormRequestError for non-422 failures', async () => {
      fetchMock.mockResolvedValue(mockResponse({ status: 500, body: { error: 'boom' } }));
      const { result } = renderHook(() => useRailsForm({ a: 1 }));

      await act(async () => {
        await expect(result.current.post('/things')).rejects.toMatchObject({
          name: 'RailsFormRequestError',
          response: expect.objectContaining({ status: 500 }),
        });
      });

      expect(result.current.processing).toBe(false);
      expect(result.current.wasSuccessful).toBe(false);
    });

    it('does not fire onSuccess for a submission superseded by a newer one', async () => {
      // A slow first request must not run its callbacks (e.g. navigate on
      // redirectTo) after a newer submission has already completed.
      let resolveFirst: (response: Response) => void = () => {};
      fetchMock
        .mockImplementationOnce(
          () =>
            new Promise<Response>((resolve) => {
              resolveFirst = resolve;
            }),
        )
        .mockResolvedValueOnce(mockResponse({ status: 200, body: { redirect_to: '/second' } }));

      const { result } = renderHook(() => useRailsForm({ a: 1 }));
      const firstOnSuccess = jest.fn();
      const secondOnSuccess = jest.fn();

      let firstSubmit: Promise<unknown> = Promise.resolve();
      await act(async () => {
        firstSubmit = result.current.post('/things', { onSuccess: firstOnSuccess });
        await result.current.post('/things', { onSuccess: secondOnSuccess });
      });

      await act(async () => {
        resolveFirst(mockResponse({ status: 200, body: { redirect_to: '/first' } }));
        await firstSubmit;
      });

      expect(secondOnSuccess).toHaveBeenCalledTimes(1);
      expect(firstOnSuccess).not.toHaveBeenCalled();
    });
  });

  describe('data and error management', () => {
    it('setData supports updater functions', async () => {
      const { result } = renderHook(() => useRailsForm({ count: 1 }));

      act(() => {
        result.current.setData((previous: { count: number }) => ({ count: previous.count + 1 }));
      });

      expect(result.current.data).toEqual({ count: 2 });
    });

    it('reset() restores initial data and clears errors', async () => {
      fetchMock.mockResolvedValue(mockResponse({ status: 422, body: { errors: { name: ['bad'] } } }));
      const { result } = renderHook(() => useRailsForm({ name: 'initial', email: 'a@b.c' }));

      act(() => {
        result.current.setData({ name: 'changed', email: 'x@y.z' });
      });
      await act(async () => {
        await result.current.post('/contact_messages');
      });

      act(() => {
        result.current.reset();
      });

      expect(result.current.data).toEqual({ name: 'initial', email: 'a@b.c' });
      expect(result.current.errors).toEqual({});
    });

    it('reset() clears wasSuccessful', async () => {
      fetchMock.mockResolvedValue(mockResponse({ status: 201, body: { message: 'ok' } }));
      const { result } = renderHook(() => useRailsForm({ name: '' }));

      await act(async () => {
        await result.current.post('/contact_messages');
      });
      expect(result.current.wasSuccessful).toBe(true);

      act(() => {
        result.current.reset();
      });

      expect(result.current.wasSuccessful).toBe(false);
    });

    it('reset(field) restores only the given field and clears only its errors', async () => {
      fetchMock.mockResolvedValue(
        mockResponse({ status: 422, body: { errors: { name: ['bad'], email: ['bad'] } } }),
      );
      const { result } = renderHook(() => useRailsForm({ name: 'initial', email: 'a@b.c' }));

      act(() => {
        result.current.setData({ name: 'changed', email: 'x@y.z' });
      });
      await act(async () => {
        await result.current.post('/contact_messages');
      });

      act(() => {
        result.current.reset('name');
      });

      expect(result.current.data).toEqual({ name: 'initial', email: 'x@y.z' });
      expect(result.current.errors).toEqual({ email: ['bad'] });
    });

    it('renders per-field errors in the DOM after an invalid submit', async () => {
      fetchMock.mockResolvedValue(
        mockResponse({ status: 422, body: { errors: { name: ["can't be blank"], email: ['is invalid'] } } }),
      );

      function ExampleForm() {
        const form = useRailsForm({ name: '', email: '' });
        return (
          <form
            onSubmit={(event) => {
              event.preventDefault();
              void form.post('/contact_messages');
            }}
          >
            {form.errors.name?.map((message) => (
              <p key={message}>{`name ${message}`}</p>
            ))}
            {form.errors.email?.map((message) => (
              <p key={message}>{`email ${message}`}</p>
            ))}
            <button type="submit">Send</button>
          </form>
        );
      }

      render(<ExampleForm />);
      fireEvent.click(screen.getByRole('button', { name: 'Send' }));

      expect(await screen.findByText("name can't be blank")).toBeTruthy();
      expect(screen.getByText('email is invalid')).toBeTruthy();
    });

    it('clearErrors and setError manage error state manually', () => {
      const { result } = renderHook(() => useRailsForm({ name: '' }));

      act(() => {
        result.current.setError('name', 'is required');
      });
      expect(result.current.errors).toEqual({ name: ['is required'] });

      act(() => {
        result.current.setError('email', ['is invalid', 'is taken']);
      });
      act(() => {
        result.current.clearErrors('name');
      });
      expect(result.current.errors).toEqual({ email: ['is invalid', 'is taken'] });

      act(() => {
        result.current.clearErrors();
      });
      expect(result.current.errors).toEqual({});
      expect(result.current.hasErrors).toBe(false);
    });
  });
});
