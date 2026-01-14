# Stream Bidi Race Condition Bug Analysis

## Problem Summary

`stream_react_component_with_async_props` returns empty SSR HTML when the async props block doesn't contain any `sleep` statements.

## Symptoms

- Node renderer receives all data (initial request + update chunks + END_STREAM)
- Node renderer generates HTML correctly (logs show SSR chunks)
- Ruby side's `response.each` yields NO chunks

```ruby
# Ruby logs:
[Ruby Side] Starting to iterate response...
[Ruby Side] Finished iterating response.  # <-- No chunks received!
```

## Root Cause Analysis

### The Code Flow

1. **In `render_code_with_incremental_updates`:**
   ```ruby
   request = connection.build_request("POST", path, body: [], stream: true)
   response = connection.request(request, stream: true)  # Returns StreamResponse, NO HTTP yet
   request << initial_data
   barrier.async do
     async_props_block.call(emitter)  # Sends update chunks via request <<
   ensure
     request.close  # Sends END_STREAM
   end
   response  # Returns immediately
   ```

2. **Later in `StreamRequest#each_chunk`:**
   ```ruby
   Sync do
     barrier = Async::Barrier.new
     stream_response = @request_executor.call(send_bundle, barrier)  # Step 1 above
     process_response_chunks(stream_response)  # Calls response.each
     barrier.wait
   end
   ```

3. **In `StreamResponse#each`:**
   ```ruby
   @request.stream = self
   @on_chunk = block
   response = @session.request(@request)  # <-- ACTUAL HTTP request sent here
   ```

### The Race Condition

**WITHOUT sleep:**
1. `barrier.async { ... }` is scheduled
2. `response` (StreamResponse) is returned
3. When `response.each` calls `@session.request(@request)`:
   - httpx starts establishing HTTP/2 connection
   - **BUT** Async fiber scheduler runs the barrier.async task first!
   - Task runs COMPLETELY (all `request <<` calls + `request.close`)
   - Task completes, control returns to httpx
4. httpx sees closed request, sends everything + END_STREAM
5. httpx might not properly wait for response in this state

**WITH sleep:**
1. Same initial setup
2. When `response.each` calls `@session.request(@request)`:
   - httpx starts HTTP/2 connection
   - Fiber yields, barrier.async task runs
   - Task hits `sleep`, yields back
   - httpx continues, sends initial data
   - Response starts flowing back
   - Task continues, sends more data + closes
3. Response chunks are properly interleaved

### Key Insight

The bug occurs when `request.close` is called **before** `@session.request(@request)` has established proper bidirectional communication. The httpx `stream_bidi` plugin may not handle this case correctly.

## Potential Fixes

### Fix 1: Delay `request.close` (Workaround)

Add a minimal yield before closing to ensure HTTP connection is established:

```ruby
# In render_code_with_incremental_updates
barrier.async do
  Async::Task.current.yield  # Allow HTTP connection to establish
  async_props_block.call(emitter)
ensure
  request.close
end
```

### Fix 2: Ensure response iteration starts first

Signal that response reading has started before sending data:

```ruby
response_started = Async::Variable.new

barrier.async do
  response_started.wait  # Wait until response.each starts
  async_props_block.call(emitter)
ensure
  request.close
end

# Set this at the start of response iteration
```

### Fix 3: Fix in httpx (Proper Solution)

The `stream_bidi` plugin should handle the case where:
1. Request body is fully buffered before HTTP connection established
2. `request.close` is called before `@session.request` completes
3. Response should still be read even when request is immediately closed

## Test Files

- `stream_bidi_race_condition_demo.rb` - Basic threading test (doesn't reproduce)
- `stream_bidi_async_race_demo.rb` - Async Ruby test (doesn't reproduce)
- `stream_bidi_delayed_response_demo.rb` - Server delay test (doesn't reproduce)
- `stream_bidi_exact_reproduction.rb` - Exact RoR Pro flow (doesn't reproduce with Ruby server)
- `test_actual_node_renderer.rb` - Test against real Node renderer (requires running renderer)

## Why Ruby Server Demos Don't Reproduce

The bug is specific to the interaction between:
1. httpx's stream_bidi plugin
2. Async Ruby's fiber scheduler
3. The actual Node.js Fastify HTTP/2 server

The Ruby HTTP/2 server (using `http-2` gem) handles the edge case correctly, but the real Node server + httpx combination exhibits the bug.

## Recommended Next Steps

1. Start the Node renderer and run `test_actual_node_renderer.rb`
2. If bug reproduces, create a minimal httpx issue with reproduction steps
3. Implement Fix 1 as a workaround until httpx is fixed
