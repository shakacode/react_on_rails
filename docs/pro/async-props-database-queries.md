# Database Queries in Async Props Blocks

This guide covers how to safely run ActiveRecord queries inside `stream_react_component_with_async_props` blocks. It explains when you need special configuration and when you don't.

> **Prerequisites:** `stream_react_component_with_async_props` requires Pro RSC support to be enabled — set `config.enable_rsc_support = true` in `config/initializers/react_on_rails_pro.rb` (it defaults to `false`) — and it must be rendered inside a [`stream_view_containing_react_components`](./streaming-ssr.md#4-render-the-view-using-the-stream_view_containing_react_components-helper) view. Without RSC support enabled the helper raises `ReactOnRailsPro::Error`; outside a streaming view it raises `ReactOnRails::Error`. The database/fiber configuration below is separate from these prerequisites.

## Quick Decision Guide

| Your usage pattern                                                 | Configuration needed?                              |
| ------------------------------------------------------------------ | -------------------------------------------------- |
| **One** async-props component per page, sequential queries         | No special config — just use ActiveRecord normally |
| **One** async-props component, parallel queries via `parent.async` | Yes — full fiber configuration required            |
| **Multiple** async-props components per page                       | Yes — full fiber configuration required            |

---

## One Component, Sequential Queries — No Special Config

If your page has a single `stream_react_component_with_async_props` call and you run queries sequentially (no `parent.async` fan-out), you can use ActiveRecord exactly as you normally would:

```erb
<%= stream_react_component_with_async_props("ProductPage",
      props: { name: @product.name }) do |emit|
  # Just normal ActiveRecord — no special setup needed
  reviews = @product.reviews.recent.limit(10).as_json(only: [:id, :text, :rating])
  emit.call("reviews", reviews)

  recommendations = @product.recommended_products.limit(5).as_json(only: [:id, :name])
  emit.call("recommendations", recommendations)
end %>
```

**Why this is safe:** Your props block runs in a single fiber. No other fiber is doing database queries at the same time. Whether or not the database driver is fiber-aware, there's no possibility of connection contention because only your fiber touches the database during this window.

**Caveat:** The queries run sequentially, so the total time is the sum of all queries. If this is acceptable (and it often is — the streaming shell is already delivered to the client while the queries run), this is the simplest and safest approach.

---

## When You Need Fiber Configuration

You need the full fiber configuration in two scenarios:

1. **Parallel queries within one component** — using `parent.async` to fan out
2. **Multiple async-props components on one page** — even with sequential queries in each

Both create multiple fibers that run database queries concurrently. Without configuration, these fibers share a single database connection, which corrupts the PostgreSQL wire protocol and produces wrong results or errors.

### What goes wrong without configuration

With the default `isolation_level = :thread`, all fibers on the same thread share one database connection. When the `pg` gem detects the fiber scheduler (installed by Pro's streaming helper), it switches to non-blocking mode — fibers yield during queries, allowing another fiber to send a query on the same connection. The PostgreSQL protocol can't handle interleaved queries on one connection, resulting in:

- `NoMethodError` on nil result objects (corrupted response parsing)
- Session state pollution (one fiber's `SET` command overwrites another's)
- Wrong query results delivered to the wrong fiber
- `PG::ConnectionBad` or `PG::UnableToSend` errors

These failures are non-deterministic and depend on timing, making them hard to reproduce in development but common under production load.

---

## Full Fiber Configuration

### Step 1: Set isolation level (Rails 7.1+)

```ruby
# config/application.rb
config.active_support.isolation_level = :fiber
```

This tells ActiveRecord to track connections per-fiber instead of per-thread. Each fiber that requests a database connection gets its own.

> **Rails version requirement:** This setting exists in Rails 7.0 but the connection pool only respects it starting in **Rails 7.1**. On Rails 7.0, the pool is hardcoded to use thread identity regardless of this setting. On Rails 6.x, the setting doesn't exist.

### Step 2: Size your connection pool

Each concurrent fiber checks out its own connection. Size the pool to accommodate the worst case:

```yaml
# config/database.yml
default: &default
  adapter: postgresql
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i * (1 + ENV.fetch("MAX_CONCURRENT_FIBERS_PER_REQUEST") { 3 }.to_i) %>
```

**Formula:** `pool >= threads × (1 + max_concurrent_fibers_per_request)`

Examples:

- 5 Puma threads, 3 parallel queries per request: `5 × 4 = 20`
- 5 Puma threads, 2 async-props components each doing 1 query: `5 × 3 = 15`
- 10 Puma threads, 1 async-props component with 5-way fan-out: `10 × 6 = 60`

If the pool is too small, fibers block waiting for a connection and eventually raise `ActiveRecord::ConnectionTimeoutError`.

### Step 3: Use `with_connection` in concurrent fibers

Wrap each fiber's database work in `with_connection` to ensure the connection is returned to the pool when the fiber finishes (or crashes):

```erb
<%= stream_react_component_with_async_props("Dashboard",
      props: { title: "Dashboard" }) do |emit|
  user_id = current_user.id  # capture before fanning out

  Sync do |parent|
    parent.async do
      posts = ActiveRecord::Base.connection_pool.with_connection do
        Post.for_user(user_id).recent.limit(20).as_json(only: [:id, :title])
      end
      emit.call("posts", posts)
    end

    parent.async do
      stats = ActiveRecord::Base.connection_pool.with_connection do
        DashboardStats.for(user_id).as_json(only: [:metric, :value])
      end
      emit.call("stats", stats)
    end
  end
end %>
```

**Why `with_connection` matters:** Without it, connections are "sticky" — they stay checked out until the fiber is garbage-collected and the pool's reaper thread runs (every 60 seconds by default). Under sustained load, this causes connections to accumulate and exhaust the pool. `with_connection` returns the connection immediately when the block exits, keeping the pool lean.

### Step 4: Verify your database driver

| Driver          | Fiber-aware?                         | Parallel queries work?     | Notes                                         |
| --------------- | ------------------------------------ | -------------------------- | --------------------------------------------- |
| **`pg`** (1.4+) | Yes — auto-detects `Fiber.scheduler` | Yes                        | Recommended. Default PostgreSQL adapter.      |
| **`trilogy`**   | Yes — designed for fibers            | Yes                        | Recommended MySQL client for fiber workloads. |
| **`mysql2`**    | No — uses blocking C calls           | No — serializes all fibers | Switch to `trilogy`, or use threads instead.  |
| **`sqlite3`**   | N/A — local file I/O                 | No benefit                 | No network wait to overlap.                   |

With a blocking driver (`mysql2`, `sqlite3`), concurrent fibers still run correctly — they just serialize. No corruption occurs, but you get no parallelism benefit.

---

## Capturing Request State

`CurrentAttributes` (and all state stored via `ActiveSupport::IsolatedExecutionState`) are fiber-scoped when `isolation_level = :fiber`. Values set in the controller are **invisible** in child fibers:

```ruby
# In controller:
Current.user = User.find(session[:user_id])  # set on the main fiber

# In async props block (child fiber):
Current.user  # => nil! Different fiber, different scope.
```

**Fix:** Capture values into local variables before spawning fibers:

```erb
<%= stream_react_component_with_async_props("Page", props: {}) do |emit|
  # Capture on main fiber — these closures carry the values into child fibers
  user_id    = Current.user.id
  account_id = Current.account.id

  Sync do |parent|
    parent.async do
      data = ActiveRecord::Base.connection_pool.with_connection do
        SomeModel.where(user_id: user_id, account_id: account_id).to_a
      end
      emit.call("data", data.as_json)
    end
  end
end %>
```

---

## Transaction Behavior

Each fiber with its own connection has **independent transaction state**. You cannot wrap multiple concurrent fibers in a single database transaction:

- Fiber A opens a transaction and inserts a row (uncommitted)
- Fiber B on a different connection cannot see that row (PostgreSQL MVCC)
- If Fiber A rolls back, Fiber B is unaffected

**Design implication:** Each `parent.async` fiber is an independent database session. If you need transactional consistency across multiple queries, run them sequentially in a single fiber rather than fanning them out.

---

## Multiple Async-Props Components (No Fan-Out)

If your page has multiple `stream_react_component_with_async_props` calls, even with sequential queries in each, you still need the full fiber configuration. Each component's block runs in its own fiber, so multiple blocks execute concurrently:

```erb
<%# Component 1 — its own fiber %>
<%= stream_react_component_with_async_props("UserStats", props: {}) do |emit|
  ActiveRecord::Base.connection_pool.with_connection do
    emit.call("stats", User.stats_for(current_user_id).as_json)
  end
end %>

<%# Component 2 — its own fiber, runs concurrently with component 1 %>
<%= stream_react_component_with_async_props("RecentOrders", props: {}) do |emit|
  ActiveRecord::Base.connection_pool.with_connection do
    emit.call("orders", Order.recent_for(current_user_id).as_json)
  end
end %>
```

Both blocks run concurrently (Pro spawns an `Async::Task` for each). Without `isolation_level = :fiber`, they share one connection and corrupt each other.

---

## Summary Checklist

For **one component, sequential queries** — no extra database/fiber configuration (beyond the prerequisites above):

- [x] Use ActiveRecord normally in the `emit` block

For **parallel queries or multiple components** — configure all of:

- [ ] `config.active_support.isolation_level = :fiber` (Rails 7.1+)
- [ ] Connection pool sized for concurrent fibers
- [ ] `with_connection { }` wrapping each fiber's DB access
- [ ] Capture `CurrentAttributes` into locals before `parent.async`
- [ ] Fiber-aware database driver (`pg` 1.4+ or `trilogy`)

---

## Troubleshooting

| Symptom                                           | Likely Cause                                                 | Fix                                                 |
| ------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------- |
| `NoMethodError: undefined method 'count' for nil` | Connection shared across fibers (missing `:fiber` isolation) | Set `isolation_level = :fiber`                      |
| `ActiveRecord::ConnectionTimeoutError`            | Pool too small for concurrent fibers                         | Increase `pool:` in database.yml                    |
| `Current.user` is nil in the props block          | `CurrentAttributes` are fiber-scoped                         | Capture into locals before `parent.async`           |
| Queries run sequentially despite fan-out          | Blocking driver or `isolation_level` not set                 | Check driver is `pg` 1.4+ and isolation is `:fiber` |
| Connection pool grows and never shrinks           | Using `ActiveRecord::Base.connection` without releasing      | Wrap in `with_connection { }`                       |
| Data inconsistency between concurrent fibers      | Fibers have independent transactions (expected)              | Don't rely on cross-fiber transaction visibility    |
