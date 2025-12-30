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
# Both queries run in parallel
render_component("Dashboard", props: {
  users: async_prop { User.active },      # Starts immediately
  posts: async_prop { Post.recent }       # Starts immediately
})
# Total time: max(users_time, posts_time)
```

### Sequential (When Needed)

Chain dependent data:

```ruby
render_component("Profile", props: {
  user: async_prop {
    user = User.find(params[:id])
    {
      user: user,
      posts: user.posts.recent  # Depends on user
    }
  }
})
```

## Timeouts and Fallbacks

### Per-Prop Timeout

```ruby
users: async_prop(timeout: 5) {
  SlowExternalAPI.fetch_users
}
```

### Fallback Values

```ruby
users: async_prop(on_error: ->(e) { { error: true, message: e.message } }) {
  ExternalService.users
}
```

### React-side Fallback

```tsx
function UsersList() {
  const usersResult = useAsyncProp<UsersResult>('users');

  if (usersResult.error) {
    return <ErrorMessage message={usersResult.message} />;
  }

  return <ul>{usersResult.map(...)}</ul>;
}
```

## Caching Strategies

### Rails-side Caching

```ruby
users: async_prop {
  Rails.cache.fetch("active_users", expires_in: 5.minutes) do
    User.active.to_a
  end
}
```

### Component-level Caching

```ruby
render_component("Dashboard",
  props: { users: async_prop { User.active } },
  cache_key: ["dashboard", current_user.id, User.maximum(:updated_at)]
)
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
  config.logging_level = :debug
  config.trace_async_props = true
end
```

### Console Logging

```javascript
// In your React component
function UsersList() {
  const users = useAsyncProp('users');
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
users: async_prop {
  start = Time.now
  result = User.active.to_a
  Rails.logger.info "[AsyncProp] users: #{(Time.now - start) * 1000}ms"
  result
}
```

### Server Timing Headers

```ruby
# In your controller
def show
  timing_data = {}

  props = {
    users: async_prop {
      start = Time.now
      result = User.active
      timing_data[:users] = Time.now - start
      result
    }
  }

  render_component("Dashboard", props: props)

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

### Optimistic Updates

```tsx
function UsersList() {
  const [users, setUsers] = useState(useAsyncProp('users'));

  const addUser = async (userData) => {
    // Optimistic update
    const optimisticUser = { ...userData, id: 'temp', pending: true };
    setUsers([...users, optimisticUser]);

    // Actual API call
    const newUser = await api.createUser(userData);
    setUsers(users => users.map(u =>
      u.id === 'temp' ? newUser : u
    ));
  };

  return ...;
}
```

### Refresh on Focus

```tsx
function Dashboard() {
  const users = useAsyncProp('users');
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    const handleFocus = () => setRefreshKey(k => k + 1);
    window.addEventListener('focus', handleFocus);
    return () => window.removeEventListener('focus', handleFocus);
  }, []);

  return <UsersList key={refreshKey} users={users} />;
}
```

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
def show
  render_component("Dashboard", props: {
    users: async_prop { User.active },
    posts: async_prop { Post.recent }
  })
end
```

```tsx
// Component (add Suspense)
function Dashboard() {
  return (
    <>
      <Suspense fallback={<UsersSkeleton />}>
        <UsersList />
      </Suspense>
      <Suspense fallback={<PostsSkeleton />}>
        <PostsList />
      </Suspense>
    </>
  );
}
```

## Related Documentation

- [Async Props Overview](./README.md)
- [How It Works](./how-it-works.md)
- [API Reference](./api-reference.md)
