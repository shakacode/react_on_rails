# Async-HTTP Migration: Issues Found and Fixes Applied

This document serves as a reference for the HTTPX to async-http migration, documenting all issues discovered and fixes applied during the migration process.

## Overview

The migration from HTTPX to async-http for React on Rails Pro's Node renderer communication required addressing several critical issues related to:

1. Multipart form encoding
2. Streaming request retry logic
3. Bidirectional HTTP/2 streaming lifecycle
4. Worker graceful shutdown handling

---

## Issue #1: Multipart Array Encoding

### Problem

When uploading bundles, the `targetBundles` array was being encoded incorrectly in multipart form data.

**Before (Broken):**

```ruby
form["targetBundles"] = ["hash1", "hash2"]
# encode_multipart converted this to:
# name="targetBundles" value="[\"hash1\", \"hash2\"]"  <- Literal string!
```

The Node renderer's `extractBodyArrayField` function expected either:

- Multiple fields with `name="targetBundles[]"` (one per element)
- Or an actual array value (created when multipart parser groups same-named fields)

### Fix

**File:** `react_on_rails_pro/lib/react_on_rails_pro/request.rb`

Added proper array handling in `encode_multipart`:

```ruby
def encode_multipart(form)
  boundary = "----ReactOnRailsPro#{SecureRandom.hex(16)}"
  parts = []

  form.each do |key, value|
    if value.is_a?(Hash) && value[:body]
      encode_multipart_file(parts, boundary, key, value)
    elsif value.is_a?(Array)
      # NEW: Encode array as multiple fields with [] suffix
      encode_multipart_array(parts, boundary, key, value)
    else
      encode_multipart_field(parts, boundary, key, value)
    end
  end

  parts << "--#{boundary}--\r\n"
  [parts.join, "multipart/form-data; boundary=#{boundary}"]
end

# NEW METHOD
def encode_multipart_array(parts, boundary, key, value)
  value.each do |item|
    parts << "--#{boundary}\r\n"
    parts << "Content-Disposition: form-data; name=\"#{key}[]\"\r\n\r\n"
    parts << item.to_s
    parts << "\r\n"
  end
end
```

**After (Fixed):**

```
name="targetBundles[]" value="hash1"
name="targetBundles[]" value="hash2"
```

---

## Issue #2: 410 Retry Never Triggered

### Problem

When the Node renderer returned 410 (STATUS_SEND_BUNDLE), the retry logic in `StreamRequest` never triggered because `process_response_chunks` collected the error body but never raised an `HTTPError`.

**Before (Broken):**

```ruby
def process_response_chunks(stream_response, error_body)
  loop_response_lines(stream_response) do |chunk|
    if stream_response.status >= 400
      error_body << chunk  # Collected error but...
      next
    end
    yield processed_chunk
  end
  # ...no exception raised! Loop just ended.
end
```

The `each_chunk` method expected an `HTTPError` to be raised:

```ruby
loop do
  stream_response = @request_executor.call(send_bundle, barrier)
  process_response_chunks(stream_response, error_body, &block)
  break  # Always breaks - retry never happens!
rescue ReactOnRailsPro::Request::HTTPError => e
  send_bundle = handle_http_error(e, error_body, send_bundle)  # Never reached
end
```

### Fix

**File:** `react_on_rails_pro/lib/react_on_rails_pro/stream_request.rb`

Added HTTPError raise after processing error chunks:

```ruby
def process_response_chunks(stream_response, error_body)
  loop_response_lines(stream_response) do |chunk|
    if stream_response.status >= 400
      error_body << chunk
      next
    end

    processed_chunk = chunk.strip
    yield processed_chunk unless processed_chunk.empty?
  end

  # NEW: Raise HTTPError to trigger retry logic
  return unless stream_response.status >= 400

  raise ReactOnRailsPro::Request::HTTPError.new(
    "HTTP error from renderer",
    status: stream_response.status,
    body: error_body
  )
end
```

---

## Issue #3: Barrier Reused on Retry (Fiber Conflict)

### Problem

In `StreamRequest.each_chunk`, the same `Async::Barrier` was created once and reused across retry attempts. When a 410 error occurred:

1. First request started a `barrier.async` fiber writing to the request body
2. 410 response received, loop retried
3. Second request started ANOTHER fiber on the SAME barrier
4. Old fiber from first request was still running/waiting
5. Both fibers competed for resources, causing errors

**Before (Broken):**

```ruby
def each_chunk(&block)
  Sync do
    barrier = Async::Barrier.new  # Created ONCE

    loop do
      stream_response = @request_executor.call(send_bundle, barrier)
      # On retry, old fibers still attached to this barrier!
      process_response_chunks(stream_response, error_body, &block)
      break
    rescue HTTPError => e
      send_bundle = handle_http_error(e, error_body, send_bundle)
      # Old fibers NOT stopped before retry
    end

    barrier.wait
  end
end
```

### Fix

**File:** `react_on_rails_pro/lib/react_on_rails_pro/stream_request.rb`

Create new barrier per attempt and stop old fibers on error:

```ruby
def each_chunk(&block)
  Sync do
    send_bundle = false
    error_body = +""
    barrier = nil

    loop do
      # NEW: Create fresh barrier for each attempt
      barrier = Async::Barrier.new

      stream_response = @request_executor.call(send_bundle, barrier)
      process_response_chunks(stream_response, error_body, &block)
      break
    rescue ReactOnRailsPro::Request::HTTPError => e
      # NEW: Stop running fibers from failed request before retrying
      barrier&.stop
      send_bundle = handle_http_error(e, error_body, send_bundle)
    rescue Async::TimeoutError => e
      barrier&.stop
      raise ReactOnRailsPro::Error, "..."
    end

    barrier&.wait
  end
end
```

---

## Issue #4: Fiber Stuck Waiting for `request_body.empty?`

### Problem

In `render_code_with_incremental_updates`, the barrier fiber had an ensure block that waited for the request body queue to drain:

```ruby
ensure
  request_body.close_write
  Async::Task.current.yield until request_body.empty?  # Could wait forever!
```

When the HTTP/2 stream was closed due to a 410 error:

1. Data in the request body queue could never be transmitted
2. `empty?` never returned true (queue has data but stream is closed)
3. Fiber waited indefinitely
4. `barrier.wait` hung forever

### Fix

**File:** `react_on_rails_pro/lib/react_on_rails_pro/request.rb`

Handle closed body and limit wait cycles:

```ruby
barrier.async do
  request_body.write("#{initial_data.to_json}\n")
  async_props_block.call(emitter)
rescue Protocol::HTTP::Body::Writable::Closed
  # NEW: Handle body closed due to error (e.g., 410)
  Rails.logger.debug { "[ReactOnRailsPro] Request body closed during async props emission" }
ensure
  # NEW: Rescue in case body is already closed
  request_body.close_write rescue nil

  # NEW: Limit wait cycles to prevent infinite waiting
  max_yields = 100
  yield_count = 0
  until request_body.empty? || yield_count >= max_yields
    Async::Task.current.yield
    yield_count += 1
  end
end
```

---

## Issue #5: `onRequest` Hook Was Commented Out

### Problem

In `handleGracefulShutdown.ts`, the entire `onRequest` hook was commented out. This hook was responsible for incrementing `activeRequestsCount` when a request started.

Without the increment, the counter started at 0, and when `onResponse` fired and decremented, it went to -1.

**Before (Broken):**

```typescript
// The entire hook was commented out!
// app.addHook('onRequest', (req, reply, done) => {
//   log.debug('>>> HOOK: onRequest fired');
//   activeRequestsCount += 1;
//   // ... event listeners ...
//   done();
// });
```

**Log evidence:**

```
Worker #6 request completed (source: onResponse), active requests: -1
```

### Fix

**File:** `packages/react-on-rails-pro-node-renderer/src/worker/handleGracefulShutdown.ts`

Uncommented and restored the `onRequest` hook:

```typescript
app.addHook('onRequest', (req, reply, done) => {
  log.debug('>>> HOOK: onRequest fired for %s %s', req.method, req.url);
  activeRequestsCount += 1;

  // Set up completion tracking event listeners
  reply.raw.on('close', () => {
    decrementRequestCount(req, 'reply.raw-close');
  });

  reply.raw.on('finish', () => {
    decrementRequestCount(req, 'reply.raw-finish');
  });

  // ... more listeners for robust tracking ...

  done();
});
```

---

## Issue #6: Graceful Shutdown Didn't Close Server

### Problem

In the shutdown handler, `app.close()` was commented out, so the server kept accepting new connections during shutdown.

**Before (Broken):**

```typescript
process.on('message', (msg) => {
  if (msg === SHUTDOWN_WORKER_MESSAGE) {
    isShuttingDown = true;
    if (activeRequestsCount === 0) {
      worker.destroy();
    } else {
      // void app.close();  // COMMENTED OUT!
    }
  }
});
```

### Fix

**File:** `packages/react-on-rails-pro-node-renderer/src/worker/handleGracefulShutdown.ts`

Uncommented `app.close()`:

```typescript
process.on('message', (msg) => {
  if (msg === SHUTDOWN_WORKER_MESSAGE) {
    isShuttingDown = true;
    if (activeRequestsCount === 0) {
      worker.destroy();
    } else {
      log.debug('Closing server and waiting for requests to complete');
      void app.close(); // NOW ACTIVE
    }
  }
});
```

---

## Issue #7: Single-Process Mode Not Supported

### Problem

`handleGracefulShutdown` returned early if `cluster.worker` was undefined, which happens in single-process mode (`workersCount === 0`).

**Before (Broken):**

```typescript
const handleGracefulShutdown = (app: FastifyInstance) => {
  const { worker } = cluster;
  if (!worker) {
    log.error('handleGracefulShutdown is called on master');
    return; // NO HOOKS REGISTERED IN SINGLE-PROCESS MODE!
  }
  // ... hooks only registered if worker exists
};
```

### Fix

**File:** `packages/react-on-rails-pro-node-renderer/src/worker/handleGracefulShutdown.ts`

Support both cluster and single-process modes:

```typescript
const handleGracefulShutdown = (app: FastifyInstance) => {
  const { worker } = cluster;
  // Support both cluster mode and single-process mode
  const workerId = worker?.id ?? 'single';

  // ... rest of setup ...

  // Only register shutdown message handler in cluster mode
  if (worker) {
    process.on('message', (msg) => {
      // ... shutdown handling with worker.destroy()
    });
  }

  // Hooks are ALWAYS registered regardless of mode
  app.addHook('onRequest', ...);
  // ... other hooks
};
```

---

## Issue #8: Counter Could Go Negative

### Problem

Even with deduplication via the `REQUEST_COUNTED_DOWN` symbol, edge cases could cause the counter to go negative if an event fired before the request was properly tracked.

### Fix

**File:** `packages/react-on-rails-pro-node-renderer/src/worker/handleGracefulShutdown.ts`

Added safety check:

```typescript
const decrementRequestCount = (req, source) => {
  if (req[REQUEST_COUNTED_DOWN]) {
    log.debug('Already counted down, skipping');
    return;
  }
  req[REQUEST_COUNTED_DOWN] = true;

  // NEW: Safety check - never go below 0
  if (activeRequestsCount <= 0) {
    log.warn('Attempted to decrement below 0 (source: %s)', source);
    return;
  }

  activeRequestsCount -= 1;
  // ... rest of logic
};
```

---

## Complete Flow After All Fixes

### Scenario: Bundles Don't Exist (410 Retry)

```
1. Rails calls render_code_with_incremental_updates
   └─ StreamRequest.create block called with send_bundle=false

2. barrier.async fiber starts
   └─ Writes initial NDJSON to request_body
   └─ Starts executing async_props_block

3. client.post sends request to Node

4. Node validates bundles, returns 410
   └─ HTTP/2 stream closes

5. barrier.async fiber detects closed body
   └─ Catches Protocol::HTTP::Body::Writable::Closed
   └─ Logs debug message
   └─ ensure block runs with yield limit (doesn't hang)

6. process_response_chunks raises HTTPError (FIX #2)

7. each_chunk catches HTTPError
   └─ Calls barrier.stop (FIX #3) - stops writing fiber
   └─ handle_http_error returns true for 410

8. Loop creates NEW barrier (FIX #3)
   └─ Calls upload_assets with proper array encoding (FIX #1)
   └─ targetBundles[] sent correctly to Node

9. upload_assets succeeds
   └─ Node now has bundles

10. Second attempt succeeds
    └─ Component renders with bundles available
    └─ HTML streams back to Rails
```

---

## Key Differences: HTTPX vs async-http

| Aspect                      | HTTPX                    | async-http                           |
| --------------------------- | ------------------------ | ------------------------------------ |
| **Async Context**           | Implicit                 | Explicit `Sync do` block required    |
| **Response Reading**        | Can read outside request | MUST read inside Sync block          |
| **Form Encoding**           | Automatic via plugins    | Manual encoding required             |
| **Array in Multipart**      | Automatic                | Manual `key[]` suffix                |
| **Bidirectional Streaming** | Plugin (`stream_bidi`)   | Native with `Body::Writable`         |
| **Body Closing**            | `close()` safe           | Use `close_write()` to preserve data |
| **Connection Pooling**      | Built-in                 | Via `Async::HTTP::Client`            |
| **Error Types**             | `HTTPX::TimeoutError`    | `Async::TimeoutError`, `IOError`     |

---

## Files Modified

1. **`react_on_rails_pro/lib/react_on_rails_pro/request.rb`**
   - Multipart array encoding
   - Fiber error handling and yield limits

2. **`react_on_rails_pro/lib/react_on_rails_pro/stream_request.rb`**
   - HTTPError raising on 4xx status
   - Barrier-per-attempt pattern
   - barrier.stop on error

3. **`packages/react-on-rails-pro-node-renderer/src/worker/handleGracefulShutdown.ts`**
   - Restored onRequest hook
   - Enabled app.close()
   - Single-process mode support
   - Negative counter safety check

---

## Testing Recommendations

When testing the async-http migration, verify:

1. **Bundle Upload**
   - Delete bundles from Node renderer
   - Make a request
   - Verify 410 → upload → retry works

2. **Incremental Rendering**
   - Use `stream_react_component_with_async_props`
   - Verify async props are delivered
   - Check HTML streams correctly

3. **Graceful Shutdown**
   - Start request, trigger shutdown mid-request
   - Verify request completes before worker exits
   - Check no requests are dropped

4. **Error Recovery**
   - Simulate network errors
   - Verify proper error messages
   - Check no hung fibers

---

## References

- [async-http Documentation](https://github.com/socketry/async-http)
- [protocol-http Body::Writable](https://github.com/socketry/protocol-http/blob/main/lib/protocol/http/body/writable.rb)
- [HTTP/2 Bidirectional Streaming](https://www.codeotaku.com/journal/2019-01/streaming-http-for-ruby/index)
