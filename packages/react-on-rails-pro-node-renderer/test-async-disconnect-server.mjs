/**
 * HTTP/2 server that triggers worker.disconnect() ASYNCHRONOUSLY
 * after a fixed delay - simulating production behavior where
 * PRIMARY decides to shutdown worker independent of request state.
 */

import cluster from 'cluster';
import http2 from 'http2';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = 9999;

const keyPath = path.join(__dirname, 'test-key.pem');
const certPath = path.join(__dirname, 'test-cert.pem');

// Parse command line args
const DISCONNECT_DELAY_MS = parseInt(process.argv[2] || '500', 10);

if (cluster.isPrimary) {
  console.log(`[PRIMARY] Starting primary process ${process.pid}`);
  console.log(`[PRIMARY] Will call worker.disconnect() ${DISCONNECT_DELAY_MS}ms after first request`);

  // Generate certificates if needed
  if (!fs.existsSync(keyPath) || !fs.existsSync(certPath)) {
    console.log('[PRIMARY] Generating self-signed certificates...');
    const { execSync } = await import('child_process');
    execSync(`openssl req -x509 -newkey rsa:2048 -keyout ${keyPath} -out ${certPath} -days 1 -nodes -subj "/CN=localhost" 2>/dev/null`, { stdio: 'inherit' });
  }

  const worker = cluster.fork();
  let disconnectScheduled = false;

  worker.on('message', (msg) => {
    if (msg.type === 'first-request-received' && !disconnectScheduled) {
      disconnectScheduled = true;
      console.log(`[PRIMARY] First request received, scheduling disconnect in ${DISCONNECT_DELAY_MS}ms`);

      // Call worker.disconnect() after delay - ASYNC, independent of request processing
      setTimeout(() => {
        console.log(`[PRIMARY] Calling worker.disconnect() NOW (async, after ${DISCONNECT_DELAY_MS}ms delay)`);
        worker.disconnect();
        console.log('[PRIMARY] worker.disconnect() called');
      }, DISCONNECT_DELAY_MS);
    }
  });

  worker.on('disconnect', () => console.log('[PRIMARY] Worker disconnected'));
  worker.on('exit', (code) => {
    console.log(`[PRIMARY] Worker exited with code ${code}`);
    try { fs.unlinkSync(keyPath); fs.unlinkSync(certPath); } catch (e) {}
    process.exit(0);
  });

} else {
  console.log(`[WORKER] Starting worker process ${process.pid}`);

  const server = http2.createSecureServer({
    key: fs.readFileSync(keyPath),
    cert: fs.readFileSync(certPath),
    allowHTTP1: false,
  });

  let requestCounter = 0;
  let firstRequestNotified = false;

  server.on('error', (err) => console.error('[WORKER] Server error:', err));

  server.on('session', (session) => {
    console.log(`[WORKER] New HTTP/2 session`);
    session.on('goaway', (errorCode) => {
      const names = ['NO_ERROR','PROTOCOL_ERROR','INTERNAL_ERROR','FLOW_CONTROL_ERROR'];
      console.log(`[WORKER] Session GOAWAY: ${names[errorCode] || errorCode}`);
    });
    session.on('close', () => console.log(`[WORKER] Session closed`));
    session.on('error', (err) => console.error(`[WORKER] Session error: ${err.message}`));
  });

  server.on('stream', (stream, headers) => {
    const pathHeader = headers[':path'];
    if (pathHeader !== '/incremental-render') {
      stream.respond({ ':status': 404 });
      stream.end('Not found');
      return;
    }

    requestCounter++;
    const reqId = requestCounter;
    let chunkCount = 0;
    let headersSent = false;
    let responseChunkCount = 0;

    console.log(`[WORKER] Request #${reqId} started`);

    // Notify PRIMARY of first request (to schedule disconnect)
    if (!firstRequestNotified) {
      firstRequestNotified = true;
      process.send({ type: 'first-request-received' });
    }

    stream.on('error', (err) => console.error(`[WORKER] Request #${reqId} stream error: ${err.message}`));
    stream.on('close', () => console.log(`[WORKER] Request #${reqId} stream closed, rstCode: ${stream.rstCode}`));

    // Handle incoming data (request body chunks)
    stream.on('data', (data) => {
      chunkCount++;
      const timestamp = Date.now();
      let parsed;
      try {
        parsed = JSON.parse(data.toString().trim());
      } catch (e) {
        parsed = { raw: data.toString().trim() };
      }

      console.log(`[WORKER] Request #${reqId} received chunk ${chunkCount} at ${timestamp}`);

      // Send response headers if not sent
      if (!headersSent) {
        headersSent = true;
        stream.respond({ ':status': 200, 'content-type': 'application/x-ndjson' });
      }

      // Simulate some processing delay (like React SSR)
      setTimeout(() => {
        responseChunkCount++;
        const responseChunk = JSON.stringify({
          requestId: reqId,
          responseChunk: responseChunkCount,
          echoedChunk: parsed.chunk,
          time: Date.now()
        }) + '\n';

        try {
          const written = stream.write(responseChunk);
          console.log(`[WORKER] Request #${reqId} sent response chunk ${responseChunkCount}, backpressure: ${!written}`);
        } catch (e) {
          console.log(`[WORKER] Request #${reqId} failed to write: ${e.message}`);
        }
      }, 50); // Small delay to simulate processing
    });

    // Handle end of request body
    stream.on('end', () => {
      console.log(`[WORKER] Request #${reqId} request body ended (${chunkCount} chunks received)`);

      // Wait a bit for any pending response chunks, then end
      setTimeout(() => {
        if (!headersSent) {
          headersSent = true;
          stream.respond({ ':status': 200, 'content-type': 'application/x-ndjson' });
        }
        try {
          stream.end(JSON.stringify({ requestId: reqId, done: true, totalChunks: chunkCount }) + '\n');
          console.log(`[WORKER] Request #${reqId} response ended`);
        } catch (e) {
          console.log(`[WORKER] Request #${reqId} failed to end: ${e.message}`);
        }
      }, 100);
    });
  });

  server.listen(PORT, () => {
    console.log(`[WORKER] HTTP/2 server listening on port ${PORT}`);
  });

  process.on('disconnect', () => {
    console.log('[WORKER] IPC disconnected');
  });
}
