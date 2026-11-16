---
sidebar_label: 'Forms and form libraries'
description: 'Build React forms on RSC pages with React 19, Conform, React Hook Form, or TanStack Form while Rails handles validation and writes.'
---

# Forms and Form Libraries on RSC Pages

Build a review form that submits to Rails, preserves input when validation fails, and refreshes
the surrounding React Server Component after a save.

Complete the shared setup, then follow **one recipe**. Each provides a Client Component form and a
`ReviewPage.jsx` that imports it directly. Install only that recipe's packages.

## Before you start

Use React 19 in an [RSC-enabled Pro app](./index.md#requirements). To enable RSC in an existing app,
follow the [setup guide](./upgrading-existing-pro-app.md).

All four forms require JavaScript, even with server-rendered initial HTML. For submission without
JavaScript, use a [standard Rails form](../../oss/building-features/mutations.md#choose-the-rails-entry-point).
Rails handles every write; passing a browser function to `<form action>` requires no Server Action
or `'use server'` directive.

## Choose a recipe

- **[React 19 built-ins](#react-19-built-ins):** `useActionState` and `useFormStatus`, without an
  additional form library.
- **[Conform](#conform):** field metadata, schema validation, and submission results with React form
  Actions.
- **[React Hook Form + zod](#react-hook-form--zod):** field registration and a validation resolver,
  with Rails errors mapped through `setError`.
- **[TanStack Form](#tanstack-form):** typed field APIs and Rails errors mapped through `setErrorMap`.

For a Rails-specific hook combining controlled fields, CSRF handling, pending state, and error
mapping, see [`useRailsForm`](../../oss/building-features/forms.md).

## Shared setup

Save form files in `client/app/components/RscForms` and the registered page in
`client/app/ror-auto-load-components`, or use your app's configured directories.

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
    "name": "Ada",
    "comment": "A useful review."
  }
}
```

Rails responds with HTTP `201` and
`{ "review": { "name": "Ada", "comment": "A useful review." } }`.

To try a server validation error, change the name to `Reserved`. It passes the browser and schema
checks, but Rails returns HTTP `422` with field names mapped to arrays of messages:

```json
{
  "errors": {
    "name": ["This reviewer name is reserved."]
  }
}
```

The example stores the latest review in the visitor's session, without a database table. Use your
application's model, authorization, and persistence while keeping this request and error contract.

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

Add page, write, and fixed RSC payload routes. Place the payload route before your app's general
`rsc_payload_route` declaration:

```ruby
# config/routes.rb
get "rsc_forms" => "rsc_forms#show", as: :rsc_forms
post "rsc_forms" => "rsc_forms#create"
get "rsc_payload/ReviewPage" => "rsc_forms#rsc_payload"
```

Load the latest review from the Rails session for both the initial page and payload requests:

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

The optional `FormResponders` concern supplies `render_model_errors`; your controller can also return
the same `422` JSON directly. Keep Rails CSRF protection enabled and include its layout meta tags:

```erb
<%= csrf_meta_tags %>
```

### 2. Render and refresh the page

Each recipe provides a `ReviewPage.jsx` Server Component. Render it from this Rails view:

```erb
<%# app/views/rsc_forms/show.html.erb %>
<%= stream_react_component("ReviewPage", props: @form_props, id: "review-page") %>
```

With auto-bundling enabled, save `ReviewPage.jsx` in your component registration directory. Otherwise,
[register it in the server and client bundles](./create-without-ssr.md#register-the-react-server-component-page)
with `registerServerComponent`. Registration supplies the `RSCRoute` ancestor the submission helper needs.

After a save, `refetch()` requests `/rsc_payload/ReviewPage` and updates **Latest saved review** without
a full page navigation. The payload endpoint must read fresh data, as this controller does, rather
than replaying the browser's old props.

For async props, configure the [provider for refetch](../streaming-ssr.md#rscrouterefetch-and-async-props)
instead of relying on the initial view's emit block running again.

### 3. Add shared submission handling

Save this helper as `client/app/components/RscForms/shared.tsx`. It sends the CSRF-protected request
with `createRailsAction`, checks responses, displays request errors, and refreshes after a confirmed save.

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

#### Save and refresh feedback

A confirmed save clears the form and shows **Saved.** A `422` displays field errors and preserves
input. If the save succeeds but the production RSC refresh fails, the helper shows **Saved, but
refreshing failed.** The **Retry refresh** button repeats only the read.

Each form keeps its fields read-only while saving and refreshing, so the success reset cannot erase
new edits. Read-only fields remain focusable and included in the submitted values.

> [!NOTE]
> Refresh recovery applies in production. In development, failed refetches throw through the route
> to expose the error and component context; the route may unmount before feedback appears. Late
> streamed errors can also remount Client Components during production recovery. See
> [Manually refetching a server component](./inside-client-components.md#manually-refetching-a-server-component)
> for details and how to keep feedback outside the route when it must survive a remount.

A failed or unreadable response can leave the save outcome uncertain, including invalid JSON or
an unexpected success response. The helper preserves input and asks the user to check whether the
review was saved before retrying. Account for duplicate writes when designing retries in your app.

### 4. Add a schema if your recipe uses one

Skip this step for React built-ins. The other recipes use this client schema for earlier feedback;
Rails still validates every submission. Install zod with your recipe's command, then save this file.

```tsx
// client/app/components/RscForms/schema.ts
import { z } from 'zod';

export const reviewSchema = z.object({
  name: z.string().trim().min(1, 'Enter your name.').max(50, 'Use 50 characters or fewer.'),
  comment: z.string().trim().min(1, 'Enter a comment.').max(200, 'Use 200 characters or fewer.'),
});
```

## React 19 built-ins

### 1. Install dependencies

Use your app's existing React 19 and React on Rails Pro packages. No additional dependencies or
shared zod schema are needed.

### 2. Create the form

Preserve rejected input and clear fields after a save by returning values from `useActionState`:
submitted values on failure, empty values on success. These become the next `defaultValue`, preserving
input across React's uncontrolled field reset in the tested version. See
[React's value-preservation example](https://react.dev/reference/react/useActionState#displaying-validation-errors-and-preserving-form-values).

Save `BuiltInForm.tsx` next to `shared.tsx`. Its Action posts to Rails from the browser;
`useFormStatus` tracks pending state from inside the form.

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
  const [state, action, pending] = useActionState(
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
            readOnly={pending}
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
            readOnly={pending}
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

### 3. Create the page

Save `ReviewPage.jsx` with a direct import of the form:

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

### 4. Try the form

1. Open `/rsc_forms`. Save `Ada` with a comment. The fields clear and **Latest saved review** updates.
2. Submit `Reserved` with a comment. Rails shows a name error and both values remain.

## Conform

### 1. Install dependencies

Install these packages and add the shared schema:

```bash
pnpm add @conform-to/react@1.21.3 @conform-to/zod@1.21.3 zod@4.1.13
```

### 2. Create the form

Display Rails errors and preserve values through `lastResult`, which connects submission results to
Conform's field metadata. Use `parsed.reply({ fieldErrors, formErrors })` for errors and
`parsed.reply({ resetForm: true })` to clear the form after a save.

Save `ConformForm.tsx` next to `shared.tsx` and `schema.ts`. Keep the `onReset` handler: it cancels
React's automatic native reset, which otherwise loses rejected values in the tested combination.
For zod v4, import `parseWithZod` from `@conform-to/zod/v4`.

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
  const [lastResult, action, pending] = useActionState(
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
          <input
            {...getInputProps(fields.name, { type: 'text' })}
            readOnly={pending}
            required
            maxLength={50}
          />
        </label>
        <p id={fields.name.errorId}>{fields.name.errors?.join(' ')}</p>
        <label htmlFor={fields.comment.id}>
          Comment
          <textarea {...getTextareaProps(fields.comment)} readOnly={pending} required maxLength={200} />
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

### 3. Create the page

Save `ReviewPage.jsx` with a direct import of the form:

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

### 4. Try the form

1. Open `/rsc_forms`. Save `Ada` with a comment. The fields clear and **Latest saved review** updates.
2. Submit `Reserved` with a comment. Rails shows a name error and both values remain.

See Conform's [React form API](https://conform.guide/api/react/useForm) and
[zod adapter](https://conform.guide/api/zod/parseWithZod) for other validation modes.

## React Hook Form + zod

### 1. Install dependencies

Install these packages and add the shared schema:

```bash
pnpm add react-hook-form@7.92.0 @hookform/resolvers@5.9.1 zod@4.1.13
```

### 2. Create the form

Keep rejected input by calling `reset()` only after a save. Display Rails `422` messages with
`setError` and request errors under `root.server`; the zod resolver handles client validation.

Save `HookForm.tsx` next to `shared.tsx` and `schema.ts`. Its `isSubmitting` state includes both the
awaited save and RSC refresh.

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
            readOnly={isSubmitting}
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
            readOnly={isSubmitting}
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

### 3. Create the page

Save `ReviewPage.jsx` with a direct import of the form:

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

### 4. Try the form

1. Open `/rsc_forms`. Save `Ada` with a comment. The fields clear and **Latest saved review** updates.
2. Submit `Reserved` with a comment. Rails shows a name error and both values remain.

See React Hook Form's
[`setError`](https://react-hook-form.com/docs/useform/seterror) and
[`reset`](https://react-hook-form.com/docs/useform/reset) references.

## TanStack Form

### 1. Install dependencies

Install these packages and add the shared schema:

```bash
pnpm add @tanstack/react-form@1.33.5 zod@4.1.13
```

### 2. Create the form

Display Rails errors through the `onSubmit` error map and clear fields after a save with
`formApi.reset()`. Standard Schema support handles the zod schema; `useSelector` subscribes to
`isSubmitting` for the read-only fields and submit button.

Save `TanStackForm.tsx` next to `shared.tsx` and `schema.ts`:

```tsx
// client/app/components/RscForms/TanStackForm.tsx
'use client';

import React, { useId, useState } from 'react';
import { useForm, useSelector } from '@tanstack/react-form';
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
  const isSubmitting = useSelector(form.store, (state) => state.isSubmitting);

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
                readOnly: isSubmitting,
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
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Saving…' : 'Save review'}
        </button>
      </form>
      <SubmissionFeedback submission={submission} />
    </div>
  );
}
```

### 3. Create the page

Save `ReviewPage.jsx` with a direct import of the form:

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

### 4. Try the form

1. Open `/rsc_forms`. Save `Ada` with a comment. The fields clear and **Latest saved review** updates.
2. Submit `Reserved` with a comment. Rails shows a name error and both values remain.

See TanStack Form's
[validation guide](https://tanstack.com/form/latest/docs/framework/react/guides/validation) and
[submission guide](https://tanstack.com/form/latest/docs/framework/react/guides/submission-handling).

## Compare the tested patterns

These recipes demonstrate the following patterns; each library also supports other approaches.

| Concern                 | React 19 built-ins                 | Conform                            | React Hook Form + zod | TanStack Form           |
| ----------------------- | ---------------------------------- | ---------------------------------- | --------------------- | ----------------------- |
| Submit mechanism        | React form Action                  | React form Action                  | `handleSubmit`        | `form.handleSubmit`     |
| Client validation       | HTML constraints                   | zod + Conform                      | zod resolver          | zod via Standard Schema |
| Rails field errors      | Action state                       | `parsed.reply()`                   | `setError()`          | `setErrorMap()`         |
| Pending state           | `useActionState` + `useFormStatus` | `useActionState` + `useFormStatus` | `isSubmitting`        | `useSelector`           |
| Preserve rejected input | Returned values + `defaultValue`   | `lastResult` + cancel native reset | Keep library values   | Keep library values     |
| Reset after save        | Return empty values                | `resetForm: true`                  | `reset()`             | `formApi.reset()`       |

All four forms are Client Components. The examples use React 19.3.1 and the package versions above; see the
[fixture package manifest](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/package.json)
for all test dependencies. Measure your app's build if bundle cost affects your choice.

## Try the runnable examples

This guide uses one `ReviewPage` for your chosen recipe. The
[Pro dummy app](https://github.com/shakacode/react_on_rails/tree/main/react_on_rails_pro/spec/dummy)
has four registered pages so you can try every form without changing files:

| Recipe                | Dummy app path        |
| --------------------- | --------------------- |
| React 19 built-ins    | `/rsc_forms/builtins` |
| Conform               | `/rsc_forms/conform`  |
| React Hook Form + zod | `/rsc_forms/rhf`      |
| TanStack Form         | `/rsc_forms/tanstack` |

Save a review as `Ada`, then reload to confirm it remains in that browser session. Try `Reserved`
and an empty required field to see validation errors.

<details>
<summary>How these examples were verified</summary>

The [browser specs](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/e2e-tests/rsc_forms.spec.ts)
cover pending state, Rails validation, retained input, saves, and unusable responses. Production-only
cases cover refresh failures, refresh-only retry, and an older retry failing after a newer save.
To run those cases, build the client with `NODE_ENV=production` before setting `RSC_FORMS_PRODUCTION=1`;
the flag does not change an existing bundle.

The [request specs](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/spec/requests/rsc_forms_spec.rb)
check CSRF protection, field types, strong parameters, session isolation, and fresh RSC props.

</details>

## Related guides

- [Forms and Mutations with `useRailsForm`](../../oss/building-features/forms.md)
- [Mutations without Server Actions](../../oss/building-features/mutations.md)
- [RSC data fetching](../../oss/migrating/rsc-data-fetching.md)
- [RSC inside Client Components](./inside-client-components.md)
- [Marketplace form examples](https://github.com/shakacode/react-on-rails-demo-marketplace-rsc/pull/250)
