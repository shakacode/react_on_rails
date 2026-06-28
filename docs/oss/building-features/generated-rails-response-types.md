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
app/javascript/generated/react_on_rails_response_types.d.ts
```

Override the destination when needed:

```bash
REACT_ON_RAILS_RESPONSE_TYPES_OUT=app/frontend/types/rails_response_types.d.ts \
  bundle exec rake react_on_rails:generate_response_types
```

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

export type RailsResponseType<TName extends keyof RailsResponseTypes> = RailsResponseTypes[TName];
```

## Use With TanStack Query

Import either the concrete response type or the keyed lookup helper:

```tsx
import { useQuery } from '@tanstack/react-query';
import type { RailsResponseType } from '../generated/react_on_rails_response_types';
import { apiFetch } from '../lib/apiFetch';

type ProjectsIndexResponse = RailsResponseType<'projects.index'>;

const projectsQuery = useQuery({
  queryKey: ['projects', status, page],
  queryFn: () => apiFetch<ProjectsIndexResponse>(`/api/projects?status=${status}&page=${page}`),
});
```

The key string in `RailsResponseTypes` is intentionally independent of the route path. Use a stable
controller/action-style name such as `projects.index` so later route changes do not churn client types.

## Supported Field Specs

| Rails contract spec                  | TypeScript output                 |
| ------------------------------------ | --------------------------------- |
| `:string`                            | `string`                          |
| `:number`, `:integer`, `:float`      | `number`                          |
| `:boolean`, `:bool`                  | `boolean`                         |
| `:json`                              | `JsonValue`                       |
| `"Project"`                          | `Project`                         |
| `{ array: "Project" }` or `[:string]` | `Project[]` or `string[]`         |
| `{ fields: { id: :number } }`        | `{ id: number; }`                 |
| `{ type: :string, optional: true }`   | `field?: string`                  |
| `{ type: :string, nullable: true }`   | `field: string \| null`           |

When an object field itself has a property named `type`, wrap it in `fields:` so the contract is
unambiguous:

```ruby
fields: {
  event: {
    fields: {
      type: :string,
      payload: :json
    }
  }
}
```

## Boundary

This task generates TypeScript declarations only. It does not validate payloads at runtime, infer schema
from serializers, create routes, or generate a client caller. Serializer adapters and typed mutation/RPC
helpers can build on the same `RailsResponseTypes` map later without changing the generated type shape.

## Related

- [Using TanStack Query](./tanstack-query.md)
- [React on Rails Pro and TanStack Start](../../pro/react-server-components/tanstack-start-comparison.md)
