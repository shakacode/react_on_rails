---
sidebar_label: 'Forms and form libraries'
description: 'Build React forms on RSC pages with React 19, Conform, React Hook Form, or TanStack Form while Rails handles validation and writes.'
---

# Forms and Form Libraries on RSC Pages

Build a review form that submits to Rails, displays validation errors without losing the user's
input, and refreshes the surrounding React Server Component after a successful save. Choose one
recipe: React 19 built-ins, Conform, React Hook Form + zod, or TanStack Form.

Complete the shared setup once, then follow **only your chosen recipe**. Each recipe supplies a
Client Component and a small `ReviewPage.jsx` that imports it directly. These are alternative
versions of the same page; you do not need the other forms or their packages.

## Before you start

Start with an [RSC-enabled Pro app](./index.md#requirements), or follow the
[existing-app setup guide](./upgrading-existing-pro-app.md). These examples use React 19.

- **[React 19 built-ins](#react-19-built-ins):** `useActionState` and `useFormStatus`, without an
  additional form library.
- **[Conform](#conform):** field metadata, schema validation, and submission results with React form
  Actions.
- **[React Hook Form + zod](#react-hook-form--zod):** field registration and a validation resolver,
  with Rails errors mapped through `setError`.
- **[TanStack Form](#tanstack-form):** typed field APIs and Rails errors mapped through `setErrorMap`.

If you prefer a Rails-specific hook with controlled fields, CSRF handling, pending state, and error
mapping together, see [`useRailsForm`](../../oss/building-features/forms.md).

All shown forms require JavaScript, including when their initial HTML is server-rendered. For
submission without JavaScript, use a
[standard Rails form](../../oss/building-features/mutations.md#choose-the-rails-entry-point).
A browser function passed to `<form action>` does not require a Server Action or `'use server'`:
Rails owns the write in every recipe below.

## Shared setup

The examples use `client/app/components/RscForms` for form files and
`client/app/ror-auto-load-components` for the registered page. Use your app's configured JavaScript
and component registration directories if they differ.

### 1. Add the Rails endpoint

Each form posts a name and comment to the same Rails endpoint:

```http
POST /rsc_forms
Content-Type: application/json
Accept: application/json
X-CSRF-Token: <token from the Rails layout>
```

```json
{
  "review": {
    "name": "Reserved",
    "comment": "A useful review."
  }
}
```

Rails deliberately rejects `Reserved`, even though it passes the browser and schema checks. The
response uses HTTP `422` and field names mapped to arrays of messages:

```json
{
  "errors": {
    "name": ["This reviewer name is reserved."]
  }
}
```

For valid input, Rails responds with HTTP `201` and
`{ "review": { "name": "Ada", "comment": "A useful review." } }`.

This example keeps the latest review in the visitor's session so it needs no database table. In your
application, use your normal model, authorization, and persistence; the request and error contract
can stay the same.

```ruby
# app/models/rsc_form_submission.rb
class RscFormSubmission
  include ActiveModel::Model

  attr_accessor :name, :comment

  validates :name, :comment, presence: true
  validates :name, length: { maximum: 50 }
  validates :comment, length: { maximum: 200 }
  validate :review_fields_are_strings
  validate :reviewer_name_is_available

  private

  def review_fields_are_strings
    %i[name comment].each do |field|
      errors.add(field, "must be a string") unless public_send(field).is_a?(String)
    end
  end

  def reviewer_name_is_available
    errors.add(:name, "This reviewer name is reserved.") if name == "Reserved"
  end
end
```

Add one page route, one write route, and a fixed RSC payload route. Put the specific payload route
before your app's general `rsc_payload_route` declaration:

```ruby
# config/routes.rb
get "rsc_forms" => "rsc_forms#show", as: :rsc_forms
post "rsc_forms" => "rsc_forms#create"
get "rsc_payload/ReviewPage" => "rsc_forms#rsc_payload"
```

The initial page and every payload request load the latest review from the Rails session:

```ruby
# app/controllers/rsc_forms_controller.rb
class RscFormsController < ApplicationController
  include ReactOnRailsPro::RSCPayloadRenderer
  include ReactOnRails::Controller::FormResponders

  self.allow_forgery_protection = true
  before_action { response.headers["Cache-Control"] = "no-store" }

  def show
    @form_props = form_props
    stream_view_containing_react_components(template: "rsc_forms/show")
  end

  def create
    submission = RscFormSubmission.new(params.require(:review).permit(:name, :comment))
    return render_model_errors(submission) unless submission.valid?

    review = { "name" => submission.name, "comment" => submission.comment }
    session[:rsc_form_review] = review
    render json: { review: }, status: :created
  end

  private

  def form_props
    { savedReview: session[:rsc_form_review] }
  end

  def rsc_payload_component_name
    "ReviewPage"
  end

  def rsc_payload_component_props
    form_props
  end
end
```

`render_model_errors` comes from the optional `FormResponders` concern. Your existing controller
can return the same `422` JSON itself. Keep Rails CSRF protection enabled and include the usual
meta tags in the layout:

```erb
<%= csrf_meta_tags %>
```

### 2. Render and refresh the page

Every recipe below provides its own `ReviewPage.jsx`. Render that registered Server Component from
the same Rails view:

```erb
<%# app/views/rsc_forms/show.html.erb %>
<%= stream_react_component("ReviewPage", props: @form_props, id: "review-page") %>
```

With auto-bundling enabled, save `ReviewPage.jsx` in your configured component registration directory.
Otherwise, [register it in the server and client bundles](./create-without-ssr.md#register-the-react-server-component-page)
using `registerServerComponent`. That registration supplies the `RSCRoute` ancestor used by the
submission helper below.

After a successful POST, `refetch()` requests `/rsc_payload/ReviewPage`. Rails reloads the session,
and **Latest saved review** updates without a full page navigation. The payload endpoint must read
fresh data; replaying the browser's old props would leave the page stale.

If your app uses async props, configure the
[async props provider for refetch](../streaming-ssr.md#rscrouterefetch-and-async-props)
instead of assuming the initial view's emit block runs again.

### 3. Add shared submission handling

Save the complete helper below as `client/app/components/RscForms/shared.tsx`. Every recipe uses it
to submit the nested request with the existing CSRF-aware `createRailsAction` API, validate response
shapes, display request errors, and refresh the page after a confirmed save.

<details>
<summary>Complete shared.tsx — used by every recipe</summary>

```tsx
// client/app/components/RscForms/shared.tsx
'use client';

import React, { useRef, useState } from 'react';
import { createRailsAction, RailsActionRequestError } from 'react-on-rails-pro/railsAction';
import { useCurrentRSCRoute } from 'react-on-rails-pro/RSCRoute';

export type ReviewValues = { name: string; comment: string };
export type ReviewErrors = Partial<Record<keyof ReviewValues | 'base', string[]>>;

export const emptyReview: ReviewValues = { name: '', comment: '' };

const postReview = createRailsAction<ReviewValues>({
  path: '/rsc_forms',
  body: (review) => ({ review }),
});

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function submissionErrors(error: unknown): ReviewErrors {
  if (error instanceof RailsActionRequestError && error.response.status === 422) {
    const body: unknown = error.responseBody;
    const errors: ReviewErrors = {};
    if (isRecord(body) && isRecord(body.errors)) {
      const fieldErrors = body.errors;
      const keys = ['name', 'comment', 'base'] as const;
      keys.forEach((key) => {
        const messages: unknown = fieldErrors[key];
        if (
          Array.isArray(messages) &&
          messages.length > 0 &&
          messages.every((value) => typeof value === 'string')
        ) {
          errors[key] = messages;
        }
      });
    }
    if (Object.keys(errors).length > 0) return errors;
    return { base: ['The server could not validate this review. Please try again.'] };
  }
  return { base: ['Could not confirm the save. Check whether the review was saved before trying again.'] };
}

export function useReviewSubmission() {
  const { refetch, retry, refetchError, clearRefetchError } = useCurrentRSCRoute();
  const [saved, setSaved] = useState(false);
  const [localRefreshError, setLocalRefreshError] = useState(false);
  const [retrying, setRetrying] = useState(false);
  const operation = useRef(0);

  async function submit(values: ReviewValues): Promise<ReviewErrors | null> {
    // A new submission supersedes any refresh retry that is still in flight.
    operation.current += 1;
    setRetrying(false);
    setSaved(false);
    setLocalRefreshError(false);
    clearRefetchError();
    let response: unknown;
    try {
      response = await postReview(values);
    } catch (error: unknown) {
      return submissionErrors(error);
    }
    // A successful HTTP response may already have saved the review. Do not
    // suggest repeating the write when its response cannot be interpreted.
    if (
      !isRecord(response) ||
      !isRecord(response.review) ||
      typeof response.review.name !== 'string' ||
      typeof response.review.comment !== 'string'
    ) {
      return {
        base: [
          'The server returned an unexpected response. Check whether the review was saved before trying again.',
        ],
      };
    }
    setSaved(true);
    clearRefetchError();
    try {
      await refetch();
    } catch {
      setLocalRefreshError(true);
    }
    return null;
  }

  async function retryRefresh() {
    operation.current += 1;
    const retryOperation = operation.current;
    setRetrying(true);
    try {
      await retry();
      if (retryOperation === operation.current) setLocalRefreshError(false);
    } catch {
      if (retryOperation === operation.current) setLocalRefreshError(true);
    } finally {
      if (retryOperation === operation.current) setRetrying(false);
    }
  }

  return {
    submit,
    saved,
    refreshFailed: saved && (localRefreshError || refetchError !== null),
    retrying,
    retryRefresh,
  };
}

export function SubmissionFeedback({ submission }: { submission: ReturnType<typeof useReviewSubmission> }) {
  const message = submission.refreshFailed ? 'Saved, but refreshing failed.' : 'Saved.';
  return (
    <div>
      <p role="status">{submission.saved ? message : ''}</p>
      {submission.refreshFailed ? (
        <button
          type="button"
          disabled={submission.retrying}
          onClick={() => {
            void submission.retryRefresh();
          }}
        >
          {submission.retrying ? 'Refreshing…' : 'Retry refresh'}
        </button>
      ) : null}
    </div>
  );
}
```

</details>

A `422` returns field errors and keeps the entered values. A confirmed save clears the form and
shows **Saved.** If the write succeeds but the production RSC refresh fails, the helper shows
**Saved, but refreshing failed.** and offers **Retry refresh**. That retry repeats only the read;
it does not submit the form again.

> [!NOTE]
> Recoverable refresh behavior applies in production. In development, failed refetches deliberately
> throw through the route to expose the error and component context; the route may unmount before
> form feedback appears. Late streamed errors can also remount Client Components during production
> recovery. See [Manually refetching a server component](./inside-client-components.md#manually-refetching-a-server-component)
> for the full behavior and how to place feedback outside the route when it must survive a remount.

A failed or unreadable response does not prove that no write occurred. The helper preserves input
and asks the user to check the saved state before retrying when it cannot confirm the outcome,
including invalid JSON or an unexpected success response. Your application's retry behavior should
respect whether repeating the operation could create a duplicate.

### 4. Add a schema if your recipe uses one

Skip this step for React built-ins. Conform, React Hook Form, and TanStack Form use the same client
schema. Install zod with your chosen recipe's command below, then save this file. Rails still
validates every submission; client validation provides earlier feedback.

```tsx
// client/app/components/RscForms/schema.ts
import { z } from 'zod';

export const reviewSchema = z.object({
  name: z.string().trim().min(1, 'Enter your name.').max(50, 'Use 50 characters or fewer.'),
  comment: z.string().trim().min(1, 'Enter a comment.').max(200, 'Use 200 characters or fewer.'),
});
```

## React 19 built-ins

**Dependencies:** none beyond the React 19 and React on Rails Pro packages already configured in
your app. Skip the shared zod schema.

Create `BuiltInForm.tsx` next to `shared.tsx`. `useActionState` runs a browser function that posts to
Rails; `useFormStatus` reads pending state from inside the form. On failure, the Action returns the
submitted values as the next `defaultValue`; on success, it returns empty values. The tested React
version preserves rejected input when React resets the uncontrolled fields. See
[React's value-preservation example](https://react.dev/reference/react/useActionState#displaying-validation-errors-and-preserving-form-values).

```tsx
// client/app/components/RscForms/BuiltInForm.tsx
'use client';

import React, { useActionState, useId } from 'react';
import { useFormStatus } from 'react-dom';
import {
  emptyReview,
  SubmissionFeedback,
  useReviewSubmission,
  type ReviewErrors,
  type ReviewValues,
} from './shared';

type FormState = { values: ReviewValues; errors: ReviewErrors };

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Saving…' : 'Save review'}
    </button>
  );
}

export default function BuiltInForm() {
  const id = useId();
  const submission = useReviewSubmission();
  const [state, action] = useActionState(
    async (_previous: FormState, data: FormData): Promise<FormState> => {
      const name = data.get('name');
      const comment = data.get('comment');
      const values = {
        name: typeof name === 'string' ? name : '',
        comment: typeof comment === 'string' ? comment : '',
      };
      const errors = await submission.submit(values);
      return errors ? { values, errors } : { values: emptyReview, errors: {} };
    },
    { values: emptyReview, errors: {} },
  );

  return (
    <div>
      <form action={action}>
        <label htmlFor={`${id}-name`}>
          Name
          <input
            id={`${id}-name`}
            name="name"
            defaultValue={state.values.name}
            required
            maxLength={50}
            aria-invalid={Boolean(state.errors.name)}
            aria-describedby={state.errors.name ? `${id}-name-error` : undefined}
          />
        </label>
        <p id={`${id}-name-error`}>{state.errors.name?.join(' ')}</p>
        <label htmlFor={`${id}-comment`}>
          Comment
          <textarea
            id={`${id}-comment`}
            name="comment"
            defaultValue={state.values.comment}
            required
            maxLength={200}
            aria-invalid={Boolean(state.errors.comment)}
            aria-describedby={state.errors.comment ? `${id}-comment-error` : undefined}
          />
        </label>
        <p id={`${id}-comment-error`}>{state.errors.comment?.join(' ')}</p>
        {state.errors.base ? <p role="alert">{state.errors.base.join(' ')}</p> : null}
        <SubmitButton />
      </form>
      <SubmissionFeedback submission={submission} />
    </div>
  );
}
```

Create the page with a direct import of this form:

```jsx
// client/app/ror-auto-load-components/ReviewPage.jsx
import React from 'react';
import BuiltInForm from '../components/RscForms/BuiltInForm';

export default function ReviewPage({ savedReview }) {
  return (
    <section>
      <h1>Write a review</h1>
      <BuiltInForm />
      <h2>Latest saved review</h2>
      {savedReview ? (
        <p>
          {savedReview.name}: {savedReview.comment}
        </p>
      ) : (
        <p>No review saved yet.</p>
      )}
    </section>
  );
}
```

Open `/rsc_forms`. Submit `Reserved` with a comment to see the Rails error and retained input, then
change the name to `Ada` and save. The form should clear and **Latest saved review** should update.

## Conform

Install only the dependencies for this recipe and add the shared schema:

```bash
pnpm add @conform-to/react@1.21.3 @conform-to/zod@1.21.3 zod@4.1.13
```

Create `ConformForm.tsx` next to `shared.tsx` and `schema.ts`. `lastResult` connects submission results
to field metadata and values. Map Rails errors with `parsed.reply({ fieldErrors, formErrors })` and
reset after a save with `parsed.reply({ resetForm: true })`.

The `onReset` handler cancels React's automatic native reset so Conform controls when fields clear.
Without it, the tested Conform/React combination loses rejected values. With zod v4, import
`parseWithZod` from `@conform-to/zod/v4`.

```tsx
// client/app/components/RscForms/ConformForm.tsx
'use client';

import React, { useActionState, useId } from 'react';
import { useFormStatus } from 'react-dom';
import {
  useForm,
  getFormProps,
  getInputProps,
  getTextareaProps,
  type SubmissionResult,
} from '@conform-to/react';
import { parseWithZod } from '@conform-to/zod/v4';
import { reviewSchema } from './schema';
import { emptyReview, SubmissionFeedback, useReviewSubmission } from './shared';

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Saving…' : 'Save review'}
    </button>
  );
}

export default function ConformForm() {
  const id = useId();
  const submission = useReviewSubmission();
  const [lastResult, action] = useActionState(
    async (_previous: SubmissionResult | undefined, data: FormData) => {
      const parsed = parseWithZod(data, { schema: reviewSchema });
      if (parsed.status !== 'success') return parsed.reply();
      const errors = await submission.submit(parsed.value);
      if (errors) {
        const { base, ...fieldErrors } = errors;
        return parsed.reply({
          fieldErrors,
          formErrors: base,
        });
      }
      return parsed.reply({ resetForm: true });
    },
    undefined,
  );
  const [form, fields] = useForm({
    id,
    defaultValue: emptyReview,
    lastResult,
    onValidate: ({ formData }) => parseWithZod(formData, { schema: reviewSchema }),
  });

  return (
    <div>
      <form
        {...getFormProps(form)}
        action={action}
        // Conform resets after reply({ resetForm: true }); preserve rejected
        // values by cancelling React's automatic native reset after an Action.
        onReset={(event) => event.preventDefault()}
      >
        <label htmlFor={fields.name.id}>
          Name
          <input {...getInputProps(fields.name, { type: 'text' })} required maxLength={50} />
        </label>
        <p id={fields.name.errorId}>{fields.name.errors?.join(' ')}</p>
        <label htmlFor={fields.comment.id}>
          Comment
          <textarea {...getTextareaProps(fields.comment)} required maxLength={200} />
        </label>
        <p id={fields.comment.errorId}>{fields.comment.errors?.join(' ')}</p>
        {form.errors ? (
          <p id={form.errorId} role="alert">
            {form.errors.join(' ')}
          </p>
        ) : null}
        <SubmitButton />
      </form>
      <SubmissionFeedback submission={submission} />
    </div>
  );
}
```

Use this version of `ReviewPage.jsx`:

```jsx
// client/app/ror-auto-load-components/ReviewPage.jsx
import React from 'react';
import ConformForm from '../components/RscForms/ConformForm';

export default function ReviewPage({ savedReview }) {
  return (
    <section>
      <h1>Write a review</h1>
      <ConformForm />
      <h2>Latest saved review</h2>
      {savedReview ? (
        <p>
          {savedReview.name}: {savedReview.comment}
        </p>
      ) : (
        <p>No review saved yet.</p>
      )}
    </section>
  );
}
```

Open `/rsc_forms`. Submit `Reserved` with a comment, check that both values remain with the Rails
error, then change the name to `Ada` and save. The form should clear and the saved review should update.
See Conform's [React form API](https://conform.guide/api/react/useForm) and
[zod adapter](https://conform.guide/api/zod/parseWithZod) for other validation modes.

## React Hook Form + zod

Install only the dependencies for this recipe and add the shared schema:

```bash
pnpm add react-hook-form@7.92.0 @hookform/resolvers@5.9.1 zod@4.1.13
```

Create `HookForm.tsx` next to `shared.tsx` and `schema.ts`. The resolver handles client validation;
Rails `422` messages go to `setError`, with request-level errors under `root.server`. Returning
without `reset()` keeps the entered values. `isSubmitting` includes the awaited save and RSC refresh.

```tsx
// client/app/components/RscForms/HookForm.tsx
'use client';

import React, { useId } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { reviewSchema } from './schema';
import { emptyReview, SubmissionFeedback, useReviewSubmission, type ReviewValues } from './shared';

export default function HookForm() {
  const id = useId();
  const submission = useReviewSubmission();
  const {
    register,
    handleSubmit,
    setError,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<ReviewValues>({
    defaultValues: emptyReview,
    resolver: zodResolver(reviewSchema),
  });

  const save = handleSubmit(async (values) => {
    const serverErrors = await submission.submit(values);
    if (serverErrors) {
      let focusFirst = true;
      (['name', 'comment'] as const).forEach((field) => {
        const message = serverErrors[field]?.[0];
        if (message) {
          setError(field, { type: 'server', message }, { shouldFocus: focusFirst });
          focusFirst = false;
        }
      });
      if (serverErrors.base)
        setError('root.server', { type: 'server', message: serverErrors.base.join(' ') });
      return;
    }
    reset(emptyReview);
  });

  return (
    <div>
      <form
        onSubmit={(event) => {
          void save(event);
        }}
        noValidate
      >
        <label htmlFor={`${id}-name`}>
          Name
          <input
            {...register('name')}
            id={`${id}-name`}
            required
            maxLength={50}
            aria-invalid={Boolean(errors.name)}
            aria-describedby={errors.name ? `${id}-name-error` : undefined}
          />
        </label>
        <p id={`${id}-name-error`}>{errors.name?.message}</p>
        <label htmlFor={`${id}-comment`}>
          Comment
          <textarea
            {...register('comment')}
            id={`${id}-comment`}
            required
            maxLength={200}
            aria-invalid={Boolean(errors.comment)}
            aria-describedby={errors.comment ? `${id}-comment-error` : undefined}
          />
        </label>
        <p id={`${id}-comment-error`}>{errors.comment?.message}</p>
        {errors.root?.server ? <p role="alert">{errors.root.server.message}</p> : null}
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Saving…' : 'Save review'}
        </button>
      </form>
      <SubmissionFeedback submission={submission} />
    </div>
  );
}
```

Use this version of `ReviewPage.jsx`:

```jsx
// client/app/ror-auto-load-components/ReviewPage.jsx
import React from 'react';
import HookForm from '../components/RscForms/HookForm';

export default function ReviewPage({ savedReview }) {
  return (
    <section>
      <h1>Write a review</h1>
      <HookForm />
      <h2>Latest saved review</h2>
      {savedReview ? (
        <p>
          {savedReview.name}: {savedReview.comment}
        </p>
      ) : (
        <p>No review saved yet.</p>
      )}
    </section>
  );
}
```

Open `/rsc_forms`. Submit `Reserved` with a comment, check the Rails field error and retained input,
then save as `Ada`. The form should clear and the saved review should update. See React Hook Form's
[`setError`](https://react-hook-form.com/docs/useform/seterror) and
[`reset`](https://react-hook-form.com/docs/useform/reset) references.

## TanStack Form

Install only the dependencies for this recipe and add the shared schema:

```bash
pnpm add @tanstack/react-form@1.33.5 zod@4.1.13
```

Create `TanStackForm.tsx` next to `shared.tsx` and `schema.ts`. Its Standard Schema support accepts
the zod schema. Map Rails errors into the `onSubmit` error map and call `formApi.reset()` after
success. `form.Subscribe` keeps the submit button's pending state reactive.

```tsx
// client/app/components/RscForms/TanStackForm.tsx
'use client';

import React, { useId, useState } from 'react';
import { useForm } from '@tanstack/react-form';
import { reviewSchema } from './schema';
import { emptyReview, SubmissionFeedback, useReviewSubmission } from './shared';

export default function TanStackForm() {
  const id = useId();
  const submission = useReviewSubmission();
  const [baseErrors, setBaseErrors] = useState<string[]>([]);
  const form = useForm({
    defaultValues: emptyReview,
    validators: { onSubmit: reviewSchema },
    onSubmit: async ({ value, formApi }) => {
      setBaseErrors([]);
      const errors = await submission.submit(value);
      if (errors) {
        formApi.setErrorMap({
          onSubmit: { fields: { name: errors.name?.[0], comment: errors.comment?.[0] } },
        });
        setBaseErrors(errors.base ?? []);
        return;
      }
      formApi.reset();
    },
  });

  return (
    <div>
      <form
        onSubmit={(event) => {
          event.preventDefault();
          void form.handleSubmit();
        }}
        noValidate
      >
        {(['name', 'comment'] as const).map((name) => (
          <form.Field key={name} name={name}>
            {(field) => {
              const hasErrors = field.state.meta.errors.length > 0;
              const props = {
                id: `${id}-${name}`,
                name: field.name,
                value: field.state.value,
                onBlur: field.handleBlur,
                onChange: (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
                  field.handleChange(event.target.value),
                required: true,
                'aria-invalid': hasErrors,
                'aria-describedby': hasErrors ? `${id}-${name}-error` : undefined,
              };
              return (
                <div>
                  <label htmlFor={props.id}>{name === 'name' ? 'Name' : 'Comment'}</label>
                  {name === 'name' ? (
                    <input {...props} maxLength={50} />
                  ) : (
                    <textarea {...props} maxLength={200} />
                  )}
                  <p id={`${id}-${name}-error`}>
                    {field.state.meta.errors
                      .map((error) => (typeof error === 'string' ? error : error?.message))
                      .join(' ')}
                  </p>
                </div>
              );
            }}
          </form.Field>
        ))}
        {baseErrors.length > 0 ? <p role="alert">{baseErrors.join(' ')}</p> : null}
        <form.Subscribe selector={(state) => state.isSubmitting}>
          {(isSubmitting) => (
            <button type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Saving…' : 'Save review'}
            </button>
          )}
        </form.Subscribe>
      </form>
      <SubmissionFeedback submission={submission} />
    </div>
  );
}
```

Use this version of `ReviewPage.jsx`:

```jsx
// client/app/ror-auto-load-components/ReviewPage.jsx
import React from 'react';
import TanStackForm from '../components/RscForms/TanStackForm';

export default function ReviewPage({ savedReview }) {
  return (
    <section>
      <h1>Write a review</h1>
      <TanStackForm />
      <h2>Latest saved review</h2>
      {savedReview ? (
        <p>
          {savedReview.name}: {savedReview.comment}
        </p>
      ) : (
        <p>No review saved yet.</p>
      )}
    </section>
  );
}
```

Open `/rsc_forms`. Submit `Reserved` with a comment, check the Rails field error and retained input,
then save as `Ada`. The form should clear and the saved review should update. See TanStack Form's
[validation guide](https://tanstack.com/form/latest/docs/framework/react/guides/validation) and
[submission guide](https://tanstack.com/form/latest/docs/framework/react/guides/submission-handling).

## Compare the tested patterns

This table covers only these recipes; the libraries support other submission and validation patterns.

| Concern                 | React 19 built-ins               | Conform                            | React Hook Form + zod | TanStack Form           |
| ----------------------- | -------------------------------- | ---------------------------------- | --------------------- | ----------------------- |
| Submit mechanism        | React form Action                | React form Action                  | `handleSubmit`        | `form.handleSubmit`     |
| Client validation       | HTML constraints                 | zod + Conform                      | zod resolver          | zod via Standard Schema |
| Rails field errors      | Action state                     | `parsed.reply()`                   | `setError()`          | `setErrorMap()`         |
| Pending state           | `useFormStatus`                  | `useFormStatus`                    | `isSubmitting`        | `form.Subscribe`        |
| Preserve rejected input | Returned values + `defaultValue` | `lastResult` + cancel native reset | Keep library values   | Keep library values     |
| Reset after save        | Return empty values              | `resetForm: true`                  | `reset()`             | `formApi.reset()`       |

All four forms are Client Components, use the shared CSRF-aware request, and refresh RSC content
after a confirmed save. The examples use React 19.3.1 and the package versions shown above; see the
[fixture package manifest](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/package.json)
for the complete test dependencies. Measure your app's build if bundle cost affects your choice.

## Try the runnable examples

The guide uses one `ReviewPage` for your chosen recipe. The
[Pro dummy app](https://github.com/shakacode/react_on_rails/tree/main/react_on_rails_pro/spec/dummy)
provides four independently registered pages so you can try each form without changing files:

| Recipe                | Dummy app path        |
| --------------------- | --------------------- |
| React 19 built-ins    | `/rsc_forms/builtins` |
| Conform               | `/rsc_forms/conform`  |
| React Hook Form + zod | `/rsc_forms/rhf`      |
| TanStack Form         | `/rsc_forms/tanstack` |

For any recipe, try an empty required field, then `Reserved`, then a valid name. After saving, reload
the page to confirm the latest review remains in that browser session.

The [browser specs](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/e2e-tests/rsc_forms.spec.ts)
cover pending state, Rails validation, retained input, successful saves, and unusable responses.
Production-only cases exercise refresh failures, refresh-only retry, and an older retry failing
after a newer save. Set `RSC_FORMS_PRODUCTION=1` only after building the client with
`NODE_ENV=production`; the flag does not change an existing bundle.
The [request specs](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/spec/requests/rsc_forms_spec.rb)
check CSRF protection, field types, strong parameters, session isolation, and fresh RSC props.

The [Marketplace form examples](https://github.com/shakacode/react-on-rails-demo-marketplace-rsc/pull/250)
provide another application reference.

## Related guides

- [Forms and Mutations with `useRailsForm`](../../oss/building-features/forms.md)
- [Mutations without Server Actions](../../oss/building-features/mutations.md)
- [RSC data fetching](../../oss/migrating/rsc-data-fetching.md)
- [RSC inside Client Components](./inside-client-components.md)
