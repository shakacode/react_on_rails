---
sidebar_label: 'Forms and form libraries'
description: 'Build React forms on RSC pages with React 19, Conform, React Hook Form, or TanStack Form while Rails handles validation and writes.'
---

# Forms and Form Libraries on RSC Pages

Build an interactive form that submits to Rails, displays field errors without losing the user's
input, and refreshes the surrounding React Server Component after a successful save. This guide
shows the same review form with React 19 built-ins, Conform, React Hook Form + zod, and TanStack Form.

In every example, the form is a **Client Component** marked with `'use client'`. Rails validates
and saves the submission. The Server Component renders the latest saved review from Rails props.
A React function passed to `<form action>` can run in the browser: it does not require a Server
Action or `'use server'`.

## Before you start

Start with an [RSC-enabled Pro app](./index.md#requirements), or follow the
[existing-app setup guide](./upgrading-existing-pro-app.md). These examples use React 19.

Choose the form approach that fits your application:

- **[React 19 built-ins](#react-19-built-ins):** use `useActionState` and `useFormStatus` for a small form without an
  additional form library.
- **[Conform](#conform):** use its field metadata, schema validation, and submission results with React form
  Actions.
- **[React Hook Form + zod](#react-hook-form--zod):** keep its field registration and resolver APIs, and map Rails errors
  with `setError`.
- **[TanStack Form](#tanstack-form):** keep its typed field APIs and map Rails errors with `setErrorMap`.
- **[`useRailsForm`](../../oss/building-features/forms.md):** use the built-in Rails form hook when
  you want controlled fields, CSRF handling, pending state, and Rails error mapping together.

The shown forms require JavaScript, including when their initial HTML is server-rendered. For
submission without JavaScript, use a
[standard Rails form](../../oss/building-features/mutations.md#choose-the-rails-entry-point).

## One Rails endpoint for every form

The example collects a name and a comment. Rails deliberately rejects the name `Reserved`, even
though it passes the browser and schema checks. That gives you a reliable way to try a server-only
validation failure.

All four forms send the same request:

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

For invalid input, Rails responds with HTTP `422` and field names mapped to arrays of messages:

```json
{
  "errors": {
    "name": ["This reviewer name is reserved."]
  }
}
```

For valid input, Rails responds with HTTP `201` and `{ "review": { "name": "Ada", "comment": "A useful review." } }`.

### Validate and save in Rails

This teaching example keeps the latest review in the visitor's Rails session, so you can run it
without a database table. In your application, use your normal model, authorization, and persistence
inside the controller; the client request and error contract can stay the same.

```ruby
# app/models/rsc_form_submission.rb
class RscFormSubmission
  include ActiveModel::Model

  attr_accessor :name, :comment

  validates :name, :comment, presence: true
  validates :name, length: { maximum: 50 }
  validates :comment, length: { maximum: 200 }
  validate :reviewer_name_is_available

  private

  def reviewer_name_is_available
    errors.add(:name, "This reviewer name is reserved.") if name == "Reserved"
  end
end
```

Add the form routes and a dedicated RSC payload route. Put the specific payload route before your
app's general `rsc_payload_route` declaration:

```ruby
# config/routes.rb
get "rsc_forms/:library" => "rsc_forms#show", as: :rsc_forms
post "rsc_forms" => "rsc_forms#create"
get "rsc_payload/RscFormsPage" => "rsc_forms#rsc_payload"
```

The controller reloads the saved review from the Rails session on both initial page and RSC
payload requests. The browser selects the example; Rails supplies the saved data.

```ruby
# app/controllers/rsc_forms_controller.rb
class RscFormsController < ApplicationController
  include ReactOnRailsPro::RSCPayloadRenderer
  include ReactOnRails::Controller::FormResponders

  # Keep the browser examples protected even when the dummy runs in test mode.
  self.allow_forgery_protection = true

  FORM_LIBRARIES = %w[builtins conform rhf tanstack].freeze
  private_constant :FORM_LIBRARIES

  before_action { response.headers["Cache-Control"] = "no-store" }

  def show
    return head :not_found unless FORM_LIBRARIES.include?(params[:library])

    @form_props = form_props(params[:library])
    stream_view_containing_react_components(template: "rsc_forms/show")
  end

  def create
    submission = RscFormSubmission.new(params.require(:review).permit(:name, :comment))
    return render_model_errors(submission) unless submission.valid?

    # An anonymous demo stores just this visitor's latest review, without a database.
    review = { "name" => submission.name, "comment" => submission.comment }
    session[:rsc_form_review] = review
    render json: { review: }, status: :created
  end

  private

  def form_props(library)
    { library:, savedReview: session[:rsc_form_review] }
  end

  def rsc_payload_component_name
    "RscFormsPage"
  end

  def rsc_payload_component_props
    library = super["library"]
    raise JSON::ParserError, "Unknown form library" unless FORM_LIBRARIES.include?(library)

    # The browser selects the example; saved data always comes from this session.
    form_props(library)
  end
end
```

`render_model_errors` comes from the optional `FormResponders` concern. An existing controller can
return the same `422` JSON itself. Keep Rails CSRF protection enabled and include the usual token
meta tags in the layout:

```erb
<%= csrf_meta_tags %>
```

### Render the form inside an RSC page

The comparison page below imports **all four** Client Components, so it needs all four component
files and their dependencies. To run the complete comparison, install the tested packages:

```bash
pnpm add \
  @conform-to/react@1.21.3 @conform-to/zod@1.21.3 \
  react-hook-form@7.92.0 @hookform/resolvers@5.9.1 \
  @tanstack/react-form@1.33.5 zod@4.1.13
```

To adopt just one recipe, install only the dependencies listed in its section and import and render
only that form in your existing RSC page. The React built-ins recipe needs no additional form package.

For the complete comparison, put the four Client Components from the sections below in
`components/RscForms`. This page chooses one based on the validated `library` prop:

```jsx
// client/app/ror-auto-load-components/RscFormsPage.jsx
import React from 'react';
import BuiltInForm from '../components/RscForms/BuiltInForm';
import ConformForm from '../components/RscForms/ConformForm';
import HookForm from '../components/RscForms/HookForm';
import TanStackForm from '../components/RscForms/TanStackForm';

const forms = { builtins: BuiltInForm, conform: ConformForm, rhf: HookForm, tanstack: TanStackForm };

export default function RscFormsPage({ library, savedReview }) {
  const Form = forms[library];
  return (
    <section>
      <Form />
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

Render that registered Server Component from the Rails view:

```erb
<%# app/views/rsc_forms/show.html.erb %>
<%= stream_react_component("RscFormsPage", props: @form_props, id: "rsc-forms-example") %>
```

With auto-bundling enabled, put the page in your configured component registration directory.
Otherwise, [register it in the server and client bundles](./create-without-ssr.md#register-the-react-server-component-page)
using `registerServerComponent`. That registration supplies the `RSCRoute` ancestor needed by
`useCurrentRSCRoute()`.

After a successful POST, `refetch()` requests `/rsc_payload/RscFormsPage`. Rails reads the updated
session, and **Latest saved review** changes without a full page navigation. Reload data on that
endpoint; replaying the browser's old props would leave the page stale.

If your app uses async props, configure the
[async props provider for refetch](../streaming-ssr.md#rscrouterefetch-and-async-props)
instead of assuming the initial view's emit block will run again.

## Share submission and feedback handling

Each form below imports the same
[submission helper](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/client/app/components/RscForms/shared.tsx).
Copy the **complete linked file** and save it as `shared.tsx` next to the form files. It exports
`emptyReview`, the value and error types, `useReviewSubmission`, and `SubmissionFeedback`.
The snippets below explain parts of that file; they are not a complete replacement for it.

The request uses the nested body expected by Rails:

```tsx
import { createRailsAction, RailsActionRequestError } from 'react-on-rails-pro/railsAction';

export type ReviewValues = { name: string; comment: string };
export type ReviewErrors = Partial<Record<keyof ReviewValues | 'base', string[]>>;
export const emptyReview: ReviewValues = { name: '', comment: '' };

const postReview = createRailsAction<ReviewValues>({
  path: '/rsc_forms',
  body: (review) => ({ review }),
});
```

`createRailsAction` handles JSON, same-origin requests, and the Rails CSRF token. The helper catches
`RailsActionRequestError` for a `422`, checks the response shape, and returns field errors for the
chosen library to display. This is the error-adaptation part of the shared helper:

```tsx
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
  return {
    base: ['Could not confirm the save. Check whether the review was saved before trying again.'],
  };
}
```

The full helper also checks the successful response, calls `refetch()`, and keeps save failures
separate from refresh failures:

- **Validation or request failure:** return errors and keep the entered values.
- **Save and refresh succeed:** clear the form and show **Saved.**
- **Save succeeds but refresh fails in production:** report **Saved, but refreshing failed.** and
  offer **Retry refresh**. Retry repeats the RSC read, not the POST.

> [!NOTE]
> Recoverable RSC refresh behavior applies in production. In development, failed refetches
> deliberately throw through the route to expose the error and component context; the route may
> unmount before the form's feedback can appear. Late streamed errors can also remount Client
> Components during production recovery. See
> [Manually refetching a server component](./inside-client-components.md#manually-refetching-a-server-component)
> for the full behavior and how to place feedback outside the route when it must survive a remount.

A failed response is not always proof that no write occurred. If a request loses its response after
Rails saves, check the saved state before repeating an operation that must not happen twice. The
helper asks you to check the saved state when a successful response has an unexpected shape or
cannot be read as JSON, and when a request's outcome is uncertain.

### Schema for the library examples

Conform, React Hook Form, and TanStack Form share this small client validation schema. Rails still
runs its own validation; the schema gives faster feedback and does not replace the controller's
checks. The built-in example uses HTML `required` and `maxLength` constraints instead.

```tsx
// components/RscForms/schema.ts
import { z } from 'zod';

export const reviewSchema = z.object({
  name: z.string().trim().min(1, 'Enter your name.').max(50, 'Use 50 characters or fewer.'),
  comment: z.string().trim().min(1, 'Enter a comment.').max(200, 'Use 200 characters or fewer.'),
});
```

## React 19 built-ins

This version needs no form library. `useActionState` runs a browser function that posts to Rails.
`useFormStatus` reads the pending state from inside the form.

React resets uncontrolled fields after a form Action completes. On failure, return the submitted
values and use them as the next `defaultValue`; on success, return empty values. The built-in
example preserves rejected values with the tested React version. See
[React's validation and value-preservation example](https://react.dev/reference/react/useActionState#displaying-validation-errors-and-preserving-form-values).

```tsx
// components/RscForms/BuiltInForm.tsx
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

## Conform

Install the packages used by this example:

```bash
pnpm add @conform-to/react@1.21.3 @conform-to/zod@1.21.3 zod@4.1.13
```

Conform's `lastResult` connects the previous submission to field metadata and values. Use
`parsed.reply({ fieldErrors, formErrors })` for Rails validation errors, and
`parsed.reply({ resetForm: true })` after a successful save. This example cancels React's native
form reset with `onReset` so Conform controls when the fields clear: without that handler, the
tested Conform/React combination loses rejected values. With zod v4, import `parseWithZod` from
`@conform-to/zod/v4`.

```tsx
// components/RscForms/ConformForm.tsx
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

See Conform's [React form API](https://conform.guide/api/react/useForm) and
[zod adapter](https://conform.guide/api/zod/parseWithZod) for additional validation modes.

## React Hook Form + zod

Install the packages used by this example:

```bash
pnpm add react-hook-form@7.92.0 @hookform/resolvers@5.9.1 zod@4.1.13
```

The resolver handles client validation. After Rails returns `422`, pass each field's message to
`setError`; use `root.server` for a request-level error. Returning without `reset()` keeps the
entered values. `isSubmitting` includes the awaited save and RSC refresh.

```tsx
// components/RscForms/HookForm.tsx
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

See React Hook Form's [`setError`](https://react-hook-form.com/docs/useform/seterror) and
[`reset`](https://react-hook-form.com/docs/useform/reset) references.

## TanStack Form

Install the packages used by this example:

```bash
pnpm add @tanstack/react-form@1.33.5 zod@4.1.13
```

TanStack Form accepts the zod schema through its Standard Schema support. Map Rails field errors
into the form's `onSubmit` error map. Keep request-level errors in form feedback, and call
`formApi.reset()` after success. `form.Subscribe` keeps the submit button's pending state reactive.

```tsx
// components/RscForms/TanStackForm.tsx
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

See TanStack Form's [validation guide](https://tanstack.com/form/latest/docs/framework/react/guides/validation)
and [submission guide](https://tanstack.com/form/latest/docs/framework/react/guides/submission-handling).

## Compare the tested patterns

This table describes the examples on this page. The libraries offer other submission and validation
patterns; this is not an exhaustive library feature matrix.

| Concern                 | React 19 built-ins               | Conform                            | React Hook Form + zod | TanStack Form           |
| ----------------------- | -------------------------------- | ---------------------------------- | --------------------- | ----------------------- |
| Form lives in           | Client Component                 | Client Component                   | Client Component      | Client Component        |
| Submit mechanism        | React form Action                | React form Action                  | `handleSubmit`        | `form.handleSubmit`     |
| Client validation       | HTML constraints                 | zod + Conform                      | zod resolver          | zod via Standard Schema |
| Rails field errors      | Action state                     | `parsed.reply()`                   | `setError()`          | `setErrorMap()`         |
| Pending state           | `useFormStatus`                  | `useFormStatus`                    | `isSubmitting`        | `form.Subscribe`        |
| Preserve rejected input | Returned values + `defaultValue` | `lastResult` + cancel native reset | Keep library values   | Keep library values     |
| Reset after save        | Return empty values              | `resetForm: true`                  | `reset()`             | `formApi.reset()`       |

All four use the shared CSRF-aware Rails request, show request-level failures, and refresh the RSC
page after a confirmed save. The examples use React 19.3.1 and the library versions in the install
commands above; see the [fixture package manifest](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/package.json)
for the complete test app dependencies. Bundle cost depends on your build and other imports; measure
your app when that affects your choice.

## Try the working examples

The [React on Rails Pro dummy app](https://github.com/shakacode/react_on_rails/tree/main/react_on_rails_pro/spec/dummy)
contains the forms, Rails controller, and RSC page shown above. With that app running, visit:

| Example               | Path                  |
| --------------------- | --------------------- |
| React 19 built-ins    | `/rsc_forms/builtins` |
| Conform               | `/rsc_forms/conform`  |
| React Hook Form + zod | `/rsc_forms/rhf`      |
| TanStack Form         | `/rsc_forms/tanstack` |

For each form:

1. Submit with an empty required field and check the browser or schema feedback.
2. Enter `Reserved` and a comment, then save. The Rails error should appear and both values should remain.
3. Change the name to `Ada` and save. The form should clear and **Latest saved review** should display
   the saved name and comment.
4. Reload the page. The latest review should still appear for that browser session.

The fixture's [browser specs](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/e2e-tests/rsc_forms.spec.ts)
also exercise pending state, failed requests, and successful responses with invalid JSON or an
unexpected shape. Its production-only cases cover refresh
failure/retry (`RSC_FORMS_PRODUCTION=1`).
Set that flag only after building the client with `NODE_ENV=production`; it does not change an
existing bundle.
The separate [request specs](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/spec/requests/rsc_forms_spec.rb)
check CSRF protection, `422` errors, strong parameters, session isolation, and fresh RSC props.

The [Marketplace form-library examples](https://github.com/shakacode/react-on-rails-demo-marketplace-rsc/pull/250)
provide another application-scale reference.

## Related guides

- [Forms and Mutations with `useRailsForm`](../../oss/building-features/forms.md)
- [Mutations without Server Actions](../../oss/building-features/mutations.md)
- [RSC data fetching](../../oss/migrating/rsc-data-fetching.md)
- [RSC inside Client Components](./inside-client-components.md)
