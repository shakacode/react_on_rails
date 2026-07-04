# Forms and Mutations with `useRailsForm`

Wiring a React form to a Rails controller by hand means reading the CSRF token,
building a `fetch` call, serializing the body, mapping Rails model errors back
onto fields, and tracking a `processing` flag. `useRailsForm` makes that
turnkey while keeping Rails as the mutation layer: your form posts JSON to a
**real Rails controller action** — the same strong parameters, ActiveModel
validations, and authorization a server-rendered form would use. No API layer,
no client-side validation duplication, no new protocol.

There are two pieces, both opt-in:

1. **`useRailsForm`** (npm package) — a React hook with `data`/`setData`,
   `errors`, `processing`, submit verbs, and automatic CSRF attachment.
2. **`ReactOnRails::Controller::FormResponders`** (gem) — a controller concern
   whose `render_model_errors(record)` renders ActiveModel errors in the JSON
   shape the hook expects.

The contract between them is one blessed error shape:

```json
// HTTP 422
{ "errors": { "name": ["can't be blank"], "email": ["is invalid"] } }
```

The hook works against **any** endpoint returning that shape; the concern is a
convenience, not a requirement.

For the framework-level comparison with Next.js Server Actions and TanStack
Start server functions, see
[Mutations without Server Actions](./mutations.md).

Compatibility: `react-on-rails/useRailsForm` requires React 16.8 or newer
because it is a hook. Apps still on React 16.0-16.7 can continue using the
package's other React 16 APIs, but this subpath throws a clear error until React
is upgraded to a hooks-capable version.

## Quick start

### Client

```tsx
import React from 'react';
import { useRailsForm } from 'react-on-rails/useRailsForm';

export default function ContactForm() {
  const form = useRailsForm({ name: '', email: '', message: '' });

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void form
      .post('/contact_messages', {
        onSuccess: () => form.reset(),
      })
      .catch(() => {
        form.setError('base', 'Something went wrong. Please try again.');
      });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={form.data.name} onChange={(e) => form.setData('name', e.target.value)} />
      {form.errors.name?.[0] && <p className="error">{form.errors.name[0]}</p>}

      <input value={form.data.email} onChange={(e) => form.setData('email', e.target.value)} />
      {form.errors.email?.[0] && <p className="error">{form.errors.email[0]}</p>}

      <textarea value={form.data.message} onChange={(e) => form.setData('message', e.target.value)} />
      {form.errors.message?.[0] && <p className="error">{form.errors.message[0]}</p>}

      <button type="submit" disabled={form.processing}>
        {form.processing ? 'Sending…' : 'Send'}
      </button>
    </form>
  );
}
```

### Server

```ruby
class ContactMessagesController < ApplicationController
  include ReactOnRails::Controller::FormResponders

  def create
    contact_message = ContactMessage.new(contact_message_params)
    if contact_message.save
      render json: { message: "Thanks!" }, status: :created
    else
      render_model_errors(contact_message) # 422 + { errors: { field: [messages] } }
    end
  end

  private

  def contact_message_params
    # useRailsForm posts a flat JSON body; Rails JSON params wrapping (on by
    # default for new apps) may also nest it under :contact_message — accept both.
    if params.key?(:contact_message)
      params.require(:contact_message).permit(:name, :email, :message)
    else
      params.permit(:name, :email, :message)
    end
  end
end
```

That's the whole round trip: submitting invalid data renders per-field errors
under each input; fixing them and resubmitting succeeds. Validations stay in
the model — the client renders whatever the server says.

A runnable example lives in the dummy app:
`react_on_rails/spec/dummy/client/app/startup/RailsFormExample.client.tsx`
(rendered at `/rails_form`) posting to
`react_on_rails/spec/dummy/app/controllers/contact_messages_controller.rb`.

## What the hook sends

Every submit issues a `fetch` with:

- the HTTP method you chose (`post`, `put`, `patch`, `delete`, or
  `submit(method, url)`),
- `Content-Type: application/json` and `Accept: application/json`,
- `X-CSRF-Token` read from the standard Rails `<meta name="csrf-token">` tag
  (via the same `authenticityToken`/`authenticityHeaders` utilities exposed on
  the `ReactOnRails` object) plus `X-Requested-With: XMLHttpRequest`,
- `credentials: 'same-origin'` so the Rails session cookie is included,
- `JSON.stringify(data)` as the body — except for `delete`, which sends **no
  body** (DELETE bodies are legal per RFC 9110 but are stripped or rejected by
  many proxies and CDNs in practice; put the resource identifier in the URL).

The CSRF token is read from the meta tag at submit time, so a token rendered
with the page is picked up without any configuration. Your layout must render
`<%= csrf_meta_tags %>` (the Rails default) — without the meta tag the hook
throws before calling `fetch`, so the form cannot accidentally submit as an
anonymous or reset session. If your app rotates tokens during long-lived
sessions, refresh the
meta tag (e.g., re-render it after sign-in) — the next submit reads the
current value.

Field keys are passed through untouched: if your Rails model says
`errors: { first_name: [...] }`, the hook gives you
`form.errors.first_name`. Use snake_case keys in `data` to match your strong
parameters (a `transform` option for key mapping is planned — see
[Scope and roadmap](#scope-and-roadmap)).

## Hook API

```ts
const form = useRailsForm(initialData);
```

| Member                                 | Description                                                                                                                                                                                                                                               |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `data`                                 | Current form data (typed from `initialData`).                                                                                                                                                                                                             |
| `setData(key, value)`                  | Set one field. Also accepts a partial object (`setData({ a, b })`) or an updater function.                                                                                                                                                                |
| `errors`                               | `{ field: ["message", ...] }` from the last 422 response.                                                                                                                                                                                                 |
| `hasErrors`                            | `true` when `errors` is non-empty.                                                                                                                                                                                                                        |
| `processing`                           | `true` while a submission is in flight.                                                                                                                                                                                                                   |
| `wasSuccessful`                        | `true` once the most recent submission succeeded.                                                                                                                                                                                                         |
| `post/put/patch/delete(url, options?)` | Submit `data` with that verb. Returns a promise of the submit result. `delete` sends no request body — put the resource id in the URL.                                                                                                                    |
| `submit(method, url, options?)`        | Submit with an explicit method.                                                                                                                                                                                                                           |
| `reset(...fields)`                     | Restore all (or the given) fields to their initial values; clears matching errors and `wasSuccessful`. Initial values are the `initialData` from the first render — later prop changes are not tracked (Inertia `useForm` semantics); remount to re-seed. |
| `clearErrors(...fields)`               | Clear all (or the given) field errors.                                                                                                                                                                                                                    |
| `setError(field, messages)`            | Set errors for one field manually.                                                                                                                                                                                                                        |
| `RailsFormRequestError`                | Exported error class (import separately; it is not a `form` member) for non-2xx responses other than a mappable 422; carries the unread `Response` plus `responseBody` (parsed JSON) for an unmappable 422.                                               |

Per-submit `options`: `headers` (merged in; CSRF headers always win),
`onSuccess(result)`, and `onError(errors)`.

Calling `reset()` inside `onSuccess` starts a fresh editing cycle immediately, so
`wasSuccessful` is also reset to `false`. Keep separate success-message state if
the UI needs to keep showing a success banner after clearing the fields.

Response handling:

- **2xx** — `wasSuccessful` flips on, `errors` clears, and `onSuccess` receives
  `{ responseData, redirectTo, response }`.
- **422 with the documented `errors` shape** — `errors` is populated per field
  (single strings are normalized to arrays) and `onError` is called. An empty
  `errors` object is still handled as a validation response with
  `{ ok: false, errors: {}, response }`. The promise resolves with
  `{ ok: false, errors, response }`.
- **Anything else** (including a 422 whose body doesn't match) — the promise
  rejects with `RailsFormRequestError`; network failures reject with the
  original fetch error.
- **Superseded submissions** — when an older in-flight submit settles after a
  newer submit has started, it resolves with `{ ok: false, stale: true }` plus
  the stale `response` or `error`. Stale submits do not update form state, call
  submit callbacks, or reject into an older `.catch()` handler after the newer
  submit has won.

## Redirects and `onSuccess`

The hook never navigates on its own. After a successful submit it surfaces a
redirect target as `result.redirectTo` when the JSON body contains a
`redirect_to` (or `redirectTo`) string hint pointing to a same-origin URL. Native
fetch redirects are disabled for CSRF-bearing submissions (`redirect: 'error'`),
so a Rails `redirect_to` response rejects instead of being followed in v1.
Relative hints resolve like browser URLs against the current page URL: for
example, `"?saved=1"` preserves the current path and changes only the query.
Return an explicit root-relative path such as `"/posts/1?saved=1"` when the
redirect should ignore the current page path.

Pass it to whatever owns navigation in your app:

```tsx
void form.post('/posts', {
  onSuccess: ({ redirectTo }) => {
    if (redirectTo) window.location.assign(redirectTo);
  },
});
```

This design is intentionally forward-compatible with the client-routing
integration tracked in
[Issue 3873](https://github.com/shakacode/react_on_rails/issues/3873): when a
client router is present, hand `redirectTo` to the router instead of
`window.location`.

## The controller concern

`ReactOnRails::Controller::FormResponders` ships with the `react_on_rails` gem
and adds one helper:

```ruby
render_model_errors(record, status: 422)
```

It renders `record.errors.messages` (any ActiveModel/ActiveRecord object) as
`{ errors: { field: [messages] } }`. It is deliberately tiny: if your API
already returns errors another way (JSON:API, custom serializers), keep it —
just map your shape to the documented one at the endpoint the form posts to.
Pass numeric HTTP status codes such as `400` or `422`; Rails status symbols are
intentionally rejected so Rack/Rails status-symbol renames cannot change the
wire response.
Because those ActiveModel messages are sent to the browser verbatim, review
custom validations for internal IDs, admin-only details, or security-sensitive
wording before using the concern on a model.

## Comparison with Inertia's `useForm`

`useRailsForm` deliberately mirrors the parts of
[Inertia.js `useForm`](https://inertia-rails.dev/guide/forms) teams use for
CRUD, without coupling your controllers to a response protocol — the endpoint
stays a normal Rails JSON action you can curl or reuse for mobile clients.

| Inertia `useForm`                  | `useRailsForm`                           |
| ---------------------------------- | ---------------------------------------- |
| `data`, `setData`                  | `data`, `setData` (same overloads)       |
| `errors` (`string` per field)      | `errors` (`string[]` per field)          |
| `processing`                       | `processing`                             |
| `wasSuccessful`                    | `wasSuccessful`                          |
| `post/put/patch/delete(url)`       | `post/put/patch/delete(url)`             |
| `reset`, `clearErrors`, `setError` | `reset`, `clearErrors`, `setError`       |
| `transform(fn)`                    | Planned (v2)                             |
| `recentlySuccessful`               | Planned (v2)                             |
| `progress` (file uploads)          | Planned (v2 — requires an XHR transport) |
| Automatic visit/redirect           | Not automatic — `redirectTo` is surfaced |

Versus React 19 / Next.js `useActionState` + `useFormStatus`: those pair with
Server Actions (`'use server'`), which introduce an RPC endpoint per action.
React on Rails intentionally keeps mutations in Rails controllers —
`useRailsForm` is the ergonomic path for that, and the separate
[Server Functions RFC (Issue 3867)](https://github.com/shakacode/react_on_rails/issues/3867)
explores the complementary RSC-side story. The two are designed to compose: if
Server Functions land, this hook remains the plain-controller bridge.
For side-by-side migration examples, see
[Mutations without Server Actions](./mutations.md).

## Scope and roadmap

v1 is fetch-only and covers submit verbs, `data`/`setData`, `errors`,
`processing`, `wasSuccessful`, CSRF auto-attach, and 422 error mapping
([Issue 3872](https://github.com/shakacode/react_on_rails/issues/3872)).
Deferred to a follow-up release: `transform`, `recentlySuccessful`, `onFinish`,
and file uploads with `progress` (which needs an `XMLHttpRequest`/duplex-stream
transport). Navigation, prefetching, and router integration belong to
[Issue 3873](https://github.com/shakacode/react_on_rails/issues/3873).
