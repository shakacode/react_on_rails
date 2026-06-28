---
sidebar_label: 'Generated Rails Response Types'
description: 'Generate TypeScript declarations from explicit Rails JSON response contracts for TanStack Query and other client data consumers.'
---

# Generated Rails Response Types

React on Rails can generate TypeScript declarations for the JSON response shapes your Rails app exposes
to client-side data consumers such as TanStack Query. Rails stays the source of truth for the data and
authorization; the generated `.d.ts` file gives the React side importable response types instead of
hand-written interfaces that drift.

This first supported path is an explicit Rails contract. Define the contract next to the serializer,
query object, or controller that owns the JSON shape, then run a rake task to emit TypeScript.
The task loads the Rails environment and eager loads app code before generating declarations so contracts
registered from app classes are available.

## Define Response Contracts

Register reusable object types and endpoint response types from Rails:

```ruby
# config/initializers/react_on_rails_response_types.rb
ReactOnRails::TypeScriptResponseTypes.define_type(
  "Project",
  fields: {
    id: :number,
    name: :string,
    status: :string,
    archived: :boolean
  }
)

ReactOnRails::TypeScriptResponseTypes.define_response(
  "projects.index",
  type_name: "ProjectsIndexResponse",
  fields: {
    projects: { array: "Project" },
    meta: {
      fields: {
        page: :number,
        per_page: :number,
        total: :number
      }
    }
  }
)
```

Use the same shape in the Rails response:

```ruby
# app/controllers/api/projects_controller.rb
def index
  result = ProjectsQuery.from_params(Current.user.projects, params).result

  render json: {
    projects: result[:records].map { |project| ProjectSerializer.one(project) },
    meta: result[:meta]
  }
end
```

## Generate the TypeScript File

Run:

```bash
bundle exec rake react_on_rails:generate_response_types
```

By default, the task writes:

```text
app/javascript/types/react_on_rails_response_types.d.ts
```

Override the destination when needed:

```bash
REACT_ON_RAILS_RESPONSE_TYPES_OUT=app/frontend/types/rails_response_types.d.ts \
  bundle exec rake react_on_rails:generate_response_types
```

The override must resolve inside `Rails.root`; the task rejects absolute paths or traversal outside the app.

The generated file contains named interfaces and a response lookup map:

```ts
export interface Project {
  id: number;
  name: string;
  status: string;
  archived: boolean;
}

export interface ProjectsIndexResponse {
  projects: Project[];
  meta: {
    page: number;
    per_page: number;
    total: number;
  };
}

export interface RailsResponseTypes {
  "projects.index": ProjectsIndexResponse;
}

export type RailsResponseTypeName = keyof RailsResponseTypes;
export type RailsResponseType<TName extends RailsResponseTypeName> = RailsResponseTypes[TName];
```

## Use With TanStack Query

Import either the concrete response type or the keyed lookup helper:

```tsx
import { useQuery } from '@tanstack/react-query';
import type { RailsResponseType } from '../types/react_on_rails_response_types';
import { apiFetch } from '../lib/apiFetch';

type ProjectsIndexResponse = RailsResponseType<'projects.index'>;

const projectsQuery = useQuery({
  queryKey: ['projects', status, page],
  queryFn: () => apiFetch<ProjectsIndexResponse>(`/api/projects?status=${status}&page=${page}`),
});
```

The key string in `RailsResponseTypes` is intentionally independent of the route path. Use a stable
controller/action-style name such as `projects.index` so later route changes do not churn client types.

## Use With Typed Rails Actions

For mutations, pair the generated response lookup with the CSRF-aware caller from
`react-on-rails/railsAction`. The helper does not generate routes or validate payloads at runtime; Rails
still owns the route, strong parameters, authorization, and JSON rendering. The generated type only
connects the client call site to the response contract you declared in Rails:

```ruby
ReactOnRails::TypeScriptResponseTypes.define_response(
  "projects.create",
  type_name: "ProjectsCreateResponse",
  fields: {
    project: "Project"
  }
)
```

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createRailsAction, RailsActionRequestError } from 'react-on-rails/railsAction';
import type { RailsResponseType } from '../generated/react_on_rails_response_types';

type ProjectFormValues = {
  name: string;
  status: string;
};

type CreateProjectVariables = {
  project: ProjectFormValues;
};

type CreateProjectResponse = RailsResponseType<'projects.create'>;

const createProject = createRailsAction<CreateProjectVariables, CreateProjectResponse>({
  path: '/api/projects',
});

function NewProjectButton() {
  const queryClient = useQueryClient();
  const mutation = useMutation({
    mutationFn: createProject,
    onSuccess: ({ project }) => {
      queryClient.setQueryData(['project', String(project.id)], { project });
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    },
    onError: (error) => {
      if (error instanceof RailsActionRequestError && error.response.status === 422) {
        // Map your app's validation-error JSON into form state here.
      }
    },
  });

  return <button onClick={() => mutation.mutate({ project: { name: 'Apollo', status: 'active' } })}>Create</button>;
}
```

Use `body` when the Rails endpoint expects a wrapper that differs from the variables passed to
`mutation.mutate`, and use a `path` function for member actions:

```ts
const archiveProject = createRailsAction<{ id: number }, RailsResponseType<'projects.archive'>>({
  method: 'PATCH',
  path: ({ id }) => `/api/projects/${id}/archive`,
  body: () => ({}),
});
```

## Supported Field Specs

| Rails contract spec                  | TypeScript output                 |
| ------------------------------------ | --------------------------------- |
| `:string`                            | `string`                          |
| `:number`, `:integer`, `:float`      | `number`                          |
| `:boolean`, `:bool`                  | `boolean`                         |
| `:date`                              | `string`                          |
| `:json`                              | `JsonValue`                       |
| `:any`                               | `any`                             |
| `:unknown`                           | `unknown`                         |
| `:null`                              | `null`                            |
| `"Project"`                          | `Project`                         |
| `{ raw: "Date" }`                    | `Date`                            |
| `{ array: "Project" }` or `[:string]` | `Project[]` or `string[]`         |
| `{ fields: { id: :number } }`        | `{ id: number; }`                 |
| `{ type: :string, optional: true }`   | `field?: string`                  |
| `{ type: :string, nullable: true }`   | `field: string \| null`           |

Use symbols for built-in scalar aliases and strings for named TypeScript contract references.
String references must match a registered contract `type_name`; unknown identifiers fail generation.
Use `{ raw: "..." }` for built-in or third-party TypeScript types that should be emitted verbatim,
such as `Date` or `Record<string, string>`.

When an object field itself uses option-like property names (`type`, `array`, `fields`, `raw`, `nullable`, or
`optional`), wrap it in `fields:` so the contract is unambiguous:

```ruby
fields: {
  event: {
    fields: {
      type: :string,
      optional: :boolean,
      payload: :json
    }
  }
}
```

## Boundary

This task generates TypeScript declarations only. It does not validate payloads at runtime, infer schema
from serializers, create routes, or generate route-specific callers. The optional
`react-on-rails/railsAction` helper builds on the same `RailsResponseTypes` map by letting the client
choose `RailsResponseType<'projects.create'>` for the response generic.

## Related

- [Using TanStack Query](./tanstack-query.md)
- [React on Rails Pro and TanStack Start](../../pro/react-server-components/tanstack-start-comparison.md)
