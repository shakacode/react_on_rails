# Troubleshooting

For issues related to upgrading from GitHub Packages to public distribution, see the [Upgrading Guide](./updating.md).

## Streaming SSR request hangs indefinitely

**Symptom**: Requests to streaming pages (or RSC payload endpoints) hang forever and never complete.

**Cause**: A compression middleware (`Rack::Deflater`, `Rack::Brotli`) is configured with an `:if` condition that calls `body.each` to check the response size. This destructively consumes streaming chunks from the `SizedQueue`, causing a deadlock.

**Fix**: See the "Compression Middleware Compatibility" section in the [Streaming Server Rendering guide](./streaming-server-rendering.md).
