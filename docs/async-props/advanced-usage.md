# Advanced Async Props Usage

Advanced patterns, error handling, and optimization techniques for Async Props.

## Error Boundaries

Wrap async components with error boundaries to gracefully handle failures:

```tsx
import React, { Component, Suspense } from 'react';

class AsyncErrorBoundary extends Component {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  render() {
    if (this.state.hasError) {
      return <div className="error">Failed to load: {this.state.error.message}</div>;
    }
    return this.props.children;
  }
}

// Usage
function Dashboard() {
  return (
    <AsyncErrorBoundary>
      <Suspense fallback={<UsersSkeleton />}>
        <UsersList />
      </Suspense>
    </AsyncErrorBoundary>
  );
}
```

## Nested Suspense Boundaries

Create fine-grained loading states with nested boundaries:

```tsx
function Dashboard() {
  return (
    <div className="dashboard">
      {/* Header loads first */}
      <Suspense fallback={<HeaderSkeleton />}>
        <Header />
      </Suspense>

      <div className="content">
        {/* Sidebar and main content load independently */}
        <Suspense fallback={<SidebarSkeleton />}>
          <Sidebar />
        </Suspense>

        <main>
          {/* Nested: Stats load before chart */}
          <Suspense fallback={<StatsSkeleton />}>
            <Stats />
            <Suspense fallback={<ChartSkeleton />}>
              <Chart />
            </Suspense>
          </Suspense>
        </main>
      </div>
    </div>
  );
}
```

## Parallel vs Sequential Loading

### Parallel (Recommended)

All async props fetch simultaneously:

```ruby
<%= stream_react_component_with_async_props("Dashboard") do
  {
    users: User.active,      # Starts immediately
    posts: Post.recent       # Starts immediately
  }
end %>
```

### Sequential (When Needed)

Chain dependent data:

```ruby
<%= stream_react_component_with_async_props("Profile") do
  user = User.find(params[:id])
  {
    user: user,
    posts: user.posts.recent  # Depends on user
  }
end %>
```

## Error Handling

Async Props does not expose per-prop `timeout:` or `on_error:` options yet. If a fetch can fail, handle the error inside the async block and return a fallback value that your component can render.

### Fallback Values

```ruby
users: begin
  ExternalService.users
rescue => e
  Rails.logger.warn("users async prop failed: #{e.message}")
  []
end
```

### React-side Fallback

```tsx
async function UsersList({ getReactOnRailsAsyncProp }) {
  const usersResult = await getReactOnRailsAsyncProp<UsersResult>('users');

  if (usersResult.error) {
    return <ErrorMessage message={usersResult.message} />;
  }

  return <ul>{usersResult.map(...)}</ul>;
}
```

## Caching Strategies

### Rails-side Caching

```ruby
<%= stream_react_component_with_async_props("Dashboard") do
  {
    users: Rails.cache.fetch("active_users", expires_in: 5.minutes) do
      User.active.to_a
    end
  }
end %>
```

### Component-level Caching

```ruby
<%= stream_react_component_with_async_props("Dashboard", props: { title: "Dashboard" }) do
  {
    users: User.active
  }
end %>
```

## Optimizing Skeleton Loaders

### Match Content Dimensions

```tsx
// Bad: Generic skeleton
<div className="skeleton h-4 w-full" />

// Good: Matches actual content
<div className="skeleton h-[200px] w-full rounded-lg" /> {/* Card size */}
```

### Animate Thoughtfully

```css
.skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: skeleton-loading 1.5s ease-in-out infinite;
}

@keyframes skeleton-loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

## Debugging Async Props

### Enable Debug Mode

```ruby
# config/environments/development.rb
ReactOnRailsPro.configure do |config|
  config.tracing = true
end
```

### Console Logging

```javascript
// In your React component
async function UsersList({ getReactOnRailsAsyncProp }) {
  const users = await getReactOnRailsAsyncProp('users');
  console.log('[AsyncProp] users resolved:', users);
  return ...;
}
```

### React DevTools

1. Open React DevTools
2. Find Suspense components
3. Check their "fallback" and "children" states
4. Monitor hydration progress

## Performance Monitoring

### Track Async Prop Timing

```ruby
users: begin
  start = Time.now
  result = User.active.to_a
  Rails.logger.info "[AsyncProp] users: #{(Time.now - start) * 1000}ms"
  result
end
```

### Server Timing Headers

```ruby
# In your controller
def show
  timing_data = {}

  stream_react_component_with_async_props("Dashboard") do
    {
      users: begin
        start = Time.now
        result = User.active
        timing_data[:users] = Time.now - start
        result
      end
    }
  end

  response.headers['Server-Timing'] = timing_data.map { |k, v|
    "#{k};dur=#{(v * 1000).round}"
  }.join(', ')
end
```

## Testing Async Props

### RSpec Integration Tests

```ruby
RSpec.describe "Dashboard", type: :system do
  it "loads users progressively" do
    visit dashboard_path

    # Shell renders immediately
    expect(page).to have_css('.dashboard-header')
    expect(page).to have_css('.users-skeleton')

    # Wait for async content
    expect(page).to have_css('.users-list', wait: 10)
    expect(page).not_to have_css('.users-skeleton')
  end
end
```

### Jest Component Tests

```tsx
import { render, waitFor } from '@testing-library/react';
import { AsyncPropsProvider } from '@react-on-rails-pro/core';

test('renders with async props', async () => {
  const mockUsers = [{ id: 1, name: 'Alice' }];

  const { getByText, queryByText } = render(
    <AsyncPropsProvider initialProps={{ users: mockUsers }}>
      <Suspense fallback={<div>Loading...</div>}>
        <UsersList />
      </Suspense>
    </AsyncPropsProvider>
  );

  await waitFor(() => {
    expect(getByText('Alice')).toBeInTheDocument();
    expect(queryByText('Loading...')).not.toBeInTheDocument();
  });
});
```

## Common Patterns

### Read async props in an async Server Component

```tsx
async function UsersList({ getReactOnRailsAsyncProp }) {
  const users = await getReactOnRailsAsyncProp('users');
  return <UsersTable users={users} />;
}
```

There is no `useAsyncProp` hook in React on Rails Pro. If a Client Component needs to manage the data after hydration, pass the resolved value down from a Server Component and seed local state from that value.

## Migration from Traditional SSR

### Before (Traditional)

```ruby
# Controller
def show
  @users = User.active
  @posts = Post.recent
end
```

```erb
<!-- View -->
<%= react_component("Dashboard", props: { users: @users, posts: @posts }) %>
```

### After (Async Props)

```ruby
# Controller
<%= stream_react_component_with_async_props("Dashboard") do
  {
    users: User.active,
    posts: Post.recent
  }
end %>
```

```tsx
// Component (add Suspense)
async function Dashboard({ getReactOnRailsAsyncProp }) {
  const users = await getReactOnRailsAsyncProp('users');
  const posts = await getReactOnRailsAsyncProp('posts');

  return (
    <>
      <Suspense fallback={<UsersSkeleton />}>
        <UsersList users={users} />
      </Suspense>
      <Suspense fallback={<PostsSkeleton />}>
        <PostsList posts={posts} />
      </Suspense>
    </>
  );
}
```

## Related Documentation

- [Async Props Overview](./README.md)
- [How It Works](./how-it-works.md)
- [API Reference](./api-reference.md)
