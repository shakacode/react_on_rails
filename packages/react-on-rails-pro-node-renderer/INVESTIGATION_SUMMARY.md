# Investigation Summary: Why `res.send(stream)` Failed for HTTP/2 Bidirectional Streaming

## The Problem

When using `stream_react_component_with_async_props` without a sleep in the async props block, the client received **empty SSR HTML** (0 bytes of response data).

## Verified: The Bug is NOT in httpx

A test script (`test_httpx_late_headers.rb`) was created to verify httpx's behavior:
- Ruby HTTP/2 server delays 2 seconds AFTER receiving client's END_STREAM
- Server then sends HEADERS + DATA
- **Result: httpx correctly received the full response**

This proves httpx handles late HEADERS correctly. The bug is entirely server-side.

## The Fix

In `worker.ts`, the `setResponse` function was changed from:

```typescript
// OLD (broken)
res.header('content-type', 'application/x-ndjson');
res.status(200);
await res.send(stream);
```

To:

```typescript
// NEW (working)
res.raw.writeHead(status, headers);
for await (const chunk of stream) {
  res.raw.write(chunk);
}
res.raw.end();
```

## Why the Fix Works

### Key Difference: Header Timing

1. **`res.send(stream)`** (Fastify abstraction):
   - Fastify sets up a pipe internally
   - **Headers are NOT sent immediately** (`headersSent=false` after `send()`)
   - Headers are sent when the pipe starts flowing (first data event)
   - This is lazy/deferred behavior optimized for typical use cases

2. **`res.raw.writeHead()`** (Direct HTTP/2):
   - **Headers are sent IMMEDIATELY** (`headersSent=true` after `writeHead()`)
   - HTTP/2 HEADERS frame is sent on the wire
   - Data frames can follow immediately

### The Race Condition

In the bidirectional streaming scenario:

1. Client (httpx) sends NDJSON request data with all async prop values
2. Server processes the request and starts the response
3. **With `res.send(stream)`**: Headers are queued but not sent immediately
4. Client sends END_STREAM flag (request body complete)
5. **Critical moment**: With `res.send(stream)`, headers may not be sent yet
6. httpx client sees END_STREAM on request, may close/reset the stream
7. Response data is lost

### Why "no sleep" triggers the issue

- **With sleep**: Delay gives time for Fastify's pipe to start flowing and send headers
- **Without sleep**: Everything happens too fast, headers aren't sent before request ends

### httpx-specific behavior

The issue only manifests with the httpx Ruby client, not with Node.js http2 client.
This suggests httpx has specific behavior around bidirectional streams where:
- It may expect HEADERS frame before request END_STREAM
- It may treat the stream as complete if no HEADERS are received in time
- The HTTP/2 `stream_bidi` plugin has timing assumptions

## Testing Results

All tests with Node.js http2 client worked correctly with both approaches.
This confirms the issue is specific to the httpx client's HTTP/2 implementation
or its bidirectional streaming plugin.

## Files Changed

- `packages/react-on-rails-pro-node-renderer/src/worker.ts` - `setResponse` function

## Network Latency Does NOT Cause This Bug

A concern was raised: if the bug were in httpx, could network latency alone trigger it?

**Answer: No.** The test proves httpx correctly handles HEADERS arriving 2+ seconds after
sending END_STREAM. The bug only occurs when the **server** receives END_STREAM before
starting its response.

With the fix (`writeHead()` immediately):
1. Server commits HEADERS to the network stack immediately
2. Even if HEADERS are delayed in transit due to latency, the server-side state has
   already transitioned to "response started"
3. When END_STREAM arrives at the server, the buggy cleanup logic cannot trigger
4. httpx receives HEADERS whenever they arrive - timing is irrelevant

## Recommendation

For HTTP/2 streaming responses, always use direct `res.raw.writeHead()` + `res.raw.write()`
instead of Fastify's `res.send(stream)` to ensure headers are sent immediately.

This is especially important for bidirectional streaming where the server must
start the response before the client completes its request.
