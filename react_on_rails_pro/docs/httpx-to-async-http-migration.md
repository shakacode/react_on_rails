# Migration from HTTPX to async-http

This document describes the migration of React on Rails Pro from the HTTPX gem to the async-http gem for HTTP/2 communication with the Node renderer.

## Why Migrate?

HTTPX had limitations with streaming and async tasks. The async-http gem provides:
- Native HTTP/2 bidirectional streaming support
- Better integration with Ruby's fiber-based concurrency
- Active maintenance by the Socketry team

## Files Changed

| File | Change |
|------|--------|
| `request.rb` | Complete rewrite to use async-http |
| `stream_request.rb` | Updated response handling for async-http |
| `async_props_emitter.rb` | Changed `<<` to `.write()` |
| `node_rendering_pool.rb` | Simplified - `render_code` now returns body directly |
| `react_on_rails_pro.rb` | Removed HTTPX require, added async-http |
| `httpx_stream_bidi_patch.rb` | Deleted (no longer needed) |
| `react_on_rails_pro.gemspec` | Replaced `httpx` with `async-http` |

## Problems Encountered and Solutions

### Problem 1: `TypeError: no implicit conversion of Async::HTTP::Protocol::HTTP2::Input into String`

**Cause:** async-http's `response.body` returns an `Input` object, not a string like HTTPX.

**Solution:** Use `response.read` to get the body as a string:
```ruby
# Before (HTTPX)
response.body

# After (async-http)
response.read
```

### Problem 2: `Connection closed with 1 active stream(s)!`

**Cause:** `response.read` was being called OUTSIDE the `Sync` block. In async-http, the HTTP/2 stream lives in the async context. When `Sync` ends, the context is torn down and the stream becomes invalid.

**Solution:** Read the response body INSIDE the `Sync` block:
```ruby
# Before (broken)
def render_code(path, js_code, send_bundle)
  Sync do
    response = perform_request(path, form: form)
  end
  response.read  # ERROR: Outside Sync block!
end

# After (fixed)
def render_code(path, js_code, send_bundle)
  Sync do
    response = perform_request(path, form: form)
    response.read  # Inside Sync block
  end
end
```

### Problem 3: `Line not terminated properly!` (HTTP/1.1 vs HTTP/2)

**Cause:** The Node renderer uses HTTP/2 (h2c - cleartext), but async-http defaults to HTTP/1.1 for non-TLS connections.

**Solution:** Force HTTP/2 protocol in endpoint configuration:
```ruby
endpoint = Async::HTTP::Endpoint.parse(
  url,
  timeout: timeout,
  protocol: Async::HTTP::Protocol::HTTP2  # Force HTTP/2
)
```

### Problem 4: `IO::TimeoutError: read timeout` (Bidirectional Streaming Deadlock)

**Cause:** For bidirectional streaming, there was a deadlock:
- `client.post()` waits for response headers before returning
- Server waits for request body data before sending response headers
- We were writing data AFTER `client.post()` returned

**Solution:** Spawn the write fiber BEFORE calling `client.post()`. The fiber runs when `client.post()` yields during I/O:
```ruby
# Before (deadlock)
response = client.post(path, headers, request_body)  # Blocks forever
request_body.write(initial_data)                      # Never reached

# After (fixed)
barrier.async do
  request_body.write(initial_data)  # Runs when client.post yields
  async_props_block.call(emitter)
ensure
  request_body.close_write
end

response = client.post(path, headers, request_body)  # Now works
```

### Problem 5: Last async prop not sent to server

**Cause:** Using `close()` instead of `close_write()`. Looking at protocol-http source:

```ruby
def close(error = nil)
  @queue.clear   # <-- DISCARDS pending data!
  @queue.close
end

def close_write(error = nil)
  @queue.close   # <-- Just closes, data preserved
end
```

**Solution:** Use `close_write()` to signal completion without discarding pending data:
```ruby
# Before (data loss)
request_body.close

# After (fixed)
request_body.close_write
```

## Key Differences: HTTPX vs async-http

| Aspect | HTTPX | async-http |
|--------|-------|------------|
| Response body | `response.body` returns string | `response.read` returns string |
| Streaming body iteration | `response.each` | `response.body.each` |
| Bidirectional streaming | `stream_bidi` plugin | `Body::Writable` with fiber scheduling |
| Protocol selection | `fallback_protocol: "h2"` | `protocol: Async::HTTP::Protocol::HTTP2` |
| Async context | Not required | Must be inside `Sync` block |
| Request body close | Automatic | Use `close_write()` to preserve data |

## Fiber Scheduling for Bidirectional Streaming

In async-http, bidirectional streaming requires understanding fiber scheduling:

1. `barrier.async { ... }` **schedules** a fiber but doesn't run it immediately
2. The fiber runs when the current fiber **yields** (during I/O operations)
3. `client.post()` yields when waiting for I/O, allowing scheduled fibers to run

This is why we spawn the write fiber BEFORE `client.post()`:

```
Timeline:
─────────────────────────────────────────────────────────────────
Main fiber:     [spawn write fiber] → [client.post starts] → [yields on I/O] → [resumes] → [returns response]
                                                     ↓
Write fiber:                                    [runs] → [writes data] → [yields]
                                                              ↓
HTTP sender:                                             [sends to server]
                                                              ↓
Server:                                                  [receives data] → [sends response]
```

## References

- [async-http GitHub](https://github.com/socketry/async-http)
- [protocol-http GitHub](https://github.com/socketry/protocol-http)
- [Streaming HTTP for Ruby](https://www.codeotaku.com/journal/2019-01/streaming-http-for-ruby/index) by Samuel Williams
- [Protocol::HTTP::Body::Writable source](https://github.com/socketry/protocol-http/blob/main/lib/protocol/http/body/writable.rb)
