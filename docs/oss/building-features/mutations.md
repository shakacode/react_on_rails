---
sidebar_label: 'Mutations'
description: 'How to handle Rails-owned form and data mutations in React on Rails without Next.js Server Actions or TanStack Start server functions.'
---

# Mutations without Server Actions

React on Rails keeps mutations in Rails. React Server Components change how read-only UI can be
rendered and streamed, but they do not move writes into the Node renderer. A React form, button, or
TanStack Query mutation should submit to a Rails route, let the controller run the same
authentication, authorization, strong parameters, ActiveRecord transactions, and validations that a
server-rendered Rails form would use, then return JSON or navigate.

Do **not** add `'use server'` to React on Rails application code. In React on Rails, the Node renderer
is a rendering process. It does not own Rails models, sessions, cookies, CSRF verification, or
transactions. Use a Client Component, a standard Rails form, or a TanStack Query mutation that calls a
Rails controller endpoint.

## Side-by-side map

| Concern                 | Next.js Server Actions                                                                                              | TanStack Start server functions                                                                                               | React on Rails                                                                                                                                                   |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Client call site        | `<form action={createPost}>`, `formAction`, or an event handler that invokes a Server Function.                     | `createServerFn({ method: 'POST' })`, often called from a component, loader, hook, event handler, or TanStack Query mutation. | `form_with`, `useRailsForm`, `createRailsAction`, or a CSRF-aware `fetch`/TanStack Query mutation.                                                               |
| Where server logic runs | The Next.js app server, inside an async function marked with `'use server'` or exported from a `'use server'` file. | The TanStack Start server, inside the `createServerFn` handler.                                                               | The Rails controller action, backed by Rails models, policies, jobs, mailers, and transactions.                                                                  |
| Request shape           | Framework-owned POST request to the Server Action endpoint.                                                         | Framework-owned same-origin RPC request to the server function endpoint.                                                      | Ordinary Rails HTTP route, usually JSON for React islands or a normal HTML form post for full-page flows.                                                        |
| Security boundary       | Verify authentication and authorization inside the action; Next.js applies same-origin Server Action protections.   | Validate input in the server function; Start documents same-origin RPC and CSRF middleware for server functions.              | Use Rails sessions, `csrf_meta_tags`, controller filters, strong parameters, and policy checks. React helpers attach CSRF headers for JSON requests.             |
| Validation errors       | Return serializable error state or throw/redirect according to the action pattern.                                  | Return serializable error state, throw, redirect, or feed TanStack Query mutation state.                                      | Return `422` JSON such as `{ "errors": { "name": ["can't be blank"] } }`; `useRailsForm` maps this to field errors.                                              |
| After the write         | Call Next cache revalidation helpers, redirect, or return updated UI/data.                                          | Invalidate TanStack Query cache, redirect, or update route state.                                                             | Let Rails redirect for full-page flows, return a safe `redirect_to` JSON hint, invalidate TanStack Query cache, or let the next Rails render stream fresh props. |

The practical translation is:

- **Next.js Server Action**: "call this server function from my form."
- **TanStack Start server function**: "call this typed same-origin server function from my app."
- **React on Rails**: "call this Rails controller route from my React UI."

## Choose the Rails entry point

Use the narrowest path that matches the UI:

- **Standard Rails forms**: best when a full-page submit and redirect are acceptable, or when the
  feature should work without JavaScript.
- **[`useRailsForm`](./forms.md)**: best for React-controlled forms that need field errors,
  `processing`, reset behavior, CSRF handling, and a small `useForm`-style API.
- **[`createRailsAction`](./generated-rails-response-types.md#use-with-typed-rails-actions) with
  TanStack Query**: best for buttons, tables, optimistic updates, and typed mutation responses.
- **Manual `fetch` with React on Rails authenticity helpers**: fine for one-off calls, but centralize
  same-origin, JSON, and CSRF behavior once the pattern repeats.

## Recipe: React form, Rails controller

This is the Rails-native equivalent of a Next.js `<form action={createPost}>` Server Action or a
TanStack Start `createServerFn({ method: 'POST' })` mutation: keep the server logic in Rails and make
the Client Component submit JSON to that route.

### Rails route and controller

```ruby
# config/routes.rb
resources :projects, only: [:new, :create, :show]
```

```ruby
# app/controllers/projects_controller.rb
class ProjectsController < ApplicationController
  include ReactOnRails::Controller::FormResponders

  def create
    project = current_account.projects.build(project_params)
    # Run your normal authorization here, for example `authorize project`.

    if project.save
      render json: {
        project: { id: project.id, name: project.name },
        redirect_to: project_path(project)
      }, status: :created
    else
      render_model_errors(project)
    end
  end

  private

  def project_params
    if params.key?(:project)
      params.require(:project).permit(:name, :status)
    else
      params.permit(:name, :status)
    end
  end
end
```

### Client Component

```tsx
'use client';

import type { FormEvent } from 'react';
import { useRailsForm } from 'react-on-rails/useRailsForm';

type ProjectFormData = {
  name: string;
  status: 'draft' | 'active';
};

export default function ProjectForm({ action }: { action: string }) {
  const form = useRailsForm<ProjectFormData>({ name: '', status: 'draft' });

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    void form
      .post(action, {
        onSuccess: ({ redirectTo }) => {
          if (redirectTo) {
            window.location.assign(redirectTo);
          } else {
            form.reset();
          }
        },
      })
      .catch(() => {
        form.setError('base', 'Something went wrong. Please try again.');
      });
  };

  return (
    <form onSubmit={handleSubmit}>
      <label>
        Name
        <input value={form.data.name} onChange={(event) => form.setData('name', event.target.value)} />
      </label>
      {form.errors.name?.map((message) => (
        <p className="error" key={message}>
          {message}
        </p>
      ))}

      <label>
        Status
        <select
          value={form.data.status}
          onChange={(event) => form.setData('status', event.target.value as ProjectFormData['status'])}
        >
          <option value="draft">Draft</option>
          <option value="active">Active</option>
        </select>
      </label>
      {form.errors.status?.map((message) => (
        <p className="error" key={message}>
          {message}
        </p>
      ))}

      {form.errors.base?.map((message) => (
        <p className="error" key={message}>
          {message}
        </p>
      ))}

      <button type="submit" disabled={form.processing}>
        {form.processing ? 'Creating...' : 'Create project'}
      </button>
    </form>
  );
}
```

`base` is not special to Rails; it is just a conventional field name for errors that are not attached
to one input. Use any key your app renders consistently.

### Render it from Rails or RSC

For an ordinary React island:

```erb
<%= react_component("ProjectForm", props: { action: projects_path }) %>
```

For a React Server Components page, keep the form as a Client Component and pass ordinary serializable
props from the Server Component:

```tsx
// ProjectPage.tsx -- Server Component
import ProjectForm from './ProjectForm.client';

export default function ProjectPage({ projectsPath }: { projectsPath: string }) {
  return <ProjectForm action={projectsPath} />;
}
```

The write still goes to `ProjectsController#create`. The Server Component can render the initial page
from Rails-provided props or async props, but the mutation belongs to Rails.

## Recipe: TanStack Query mutation

When the UI is a live table, command button, optimistic update, or cache-managed island, use TanStack
Query for client state and keep the write endpoint in Rails.

```tsx
'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createRailsAction, RailsActionRequestError } from 'react-on-rails/railsAction';

type ProjectFormData = {
  name: string;
  status: string;
};

type ProjectResponse = {
  project: { id: number; name: string; status: string };
};

const createProject = createRailsAction<{ project: ProjectFormData }, ProjectResponse>({
  path: '/projects',
});

export function useCreateProjectMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createProject,
    onSuccess: ({ project }) => {
      queryClient.setQueryData(['project', String(project.id)], { project });
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    },
    onError: (error) => {
      if (error instanceof RailsActionRequestError && error.response.status === 422) {
        // Map your app's validation-error JSON into local form state.
      }
    },
  });
}
```

This is close to a TanStack Start server-function call at the component boundary, but the server code
is still the Rails controller. If your app generates TypeScript response types from Rails, replace the
hand-written `ProjectResponse` with
[`RailsResponseType<'projects.create'>`](./generated-rails-response-types.md#use-with-typed-rails-actions).

## RSC and cache refresh

React on Rails RSC pages usually read data from Rails controller props or
[`stream_react_component_with_async_props`](../migrating/rsc-data-fetching.md#data-fetching-in-react-on-rails-pro).
After a mutation, choose the refresh mechanism that matches the UI:

- Full-page Rails flow: redirect from the controller or return a same-origin `redirect_to` JSON hint
  and navigate to it.
- TanStack Query island: invalidate or update the affected query keys.
- RSC route: navigate to a route that Rails renders again, or trigger the app's client router to load
  the next page state.
- Fragment/component cache: expire or revalidate from Rails callbacks, jobs, or controller code, not
  from a Node-renderer Server Action.

For the migration-specific warning, see
[Mutations: Rails Controllers, Not Server Actions](../migrating/rsc-data-fetching.md#mutations-rails-controllers-not-server-actions).

## Testing checklist

- Controller/request spec: valid write, invalid `422` error JSON, authorization failure, and redirect
  hint when used.
- Client component test: submit state, CSRF-backed request helper behavior, validation-error rendering,
  and cache invalidation or navigation callback.
- System test: only for full user flows where routing, streaming, or hydration is the risk.

## Related docs

- [Forms and Mutations with `useRailsForm`](./forms.md)
- [Using TanStack Query](./tanstack-query.md)
- [Generated Rails response types](./generated-rails-response-types.md)
- [RSC data fetching and mutation guidance](../migrating/rsc-data-fetching.md#mutations-rails-controllers-not-server-actions)
- [React on Rails Pro and Next.js: RSC Architectures Compared](../../pro/react-server-components/nextjs-comparison.md)
- [React on Rails Pro and TanStack Start: Two Ways to Own the Full Stack](../../pro/react-server-components/tanstack-start-comparison.md)
- [Next.js Mutating Data](https://nextjs.org/docs/app/getting-started/mutating-data)
- [TanStack Start Server Functions](https://tanstack.com/start/latest/docs/framework/react/guide/server-functions)
