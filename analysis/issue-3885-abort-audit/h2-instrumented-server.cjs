/*
 * THROWAWAY REPRO for issue #3885 abort-path audit (report-only).
 *
 * Minimal cleartext HTTP/2 (h2c) server that streams ticks forever on
 * POST /stream and records per-stream lifecycle events, so we can observe
 * whether the Ruby client (ReactOnRailsPro::RendererHttpClient) sends
 * RST_STREAM upstream when its consuming Async task is stopped — i.e.
 * whether Rails propagates client disconnects to the node renderer.
 *
 * GET/POST /events returns the recorded events as JSON.
 */
const http2 = require('http2');

const port = Number(process.argv[2] || 3899);
const events = [];
const log = (msg) => events.push({ t: Date.now(), msg });

const server = http2.createServer();
server.on('stream', (stream, headers) => {
  const path = headers[':path'];
  if (path === '/events') {
    stream.respond({ ':status': 200, 'content-type': 'application/json' });
    stream.end(JSON.stringify(events));
    return;
  }

  log(`stream opened ${path}`);
  stream.respond({ ':status': 200, 'content-type': 'text/plain' });
  let i = 0;
  const interval = setInterval(() => {
    i += 1;
    if (stream.destroyed || stream.closed) {
      log(`producer observed destroyed stream at tick ${i}; stopping`);
      clearInterval(interval);
      return;
    }
    stream.write(`tick ${i}\n`);
    log(`wrote tick ${i}`);
    if (i >= 50) {
      log('producer finished naturally');
      clearInterval(interval);
      stream.end();
    }
  }, 100);

  stream.on('aborted', () => log('stream event: aborted'));
  stream.on('error', (err) => log(`stream event: error ${err.code || err.message}`));
  stream.on('close', () => {
    log(`stream event: close (rstCode=${stream.rstCode})`);
    clearInterval(interval);
  });
});

server.listen(port, '127.0.0.1', () => {
  process.stdout.write(`listening ${port}\n`);
});
