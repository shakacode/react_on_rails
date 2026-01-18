/**
 * HTTP/2 server for testing bidirectional streaming with worker.disconnect().
 * Simulates the node-renderer incremental rendering endpoint.
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

if (cluster.isPrimary) {
  console.log(`[PRIMARY] Starting primary process ${process.pid}`);

  // Generate certificates if needed
  if (!fs.existsSync(keyPath) || !fs.existsSync(certPath)) {
    console.log('[PRIMARY] Generating self-signed certificates...');
    const { execSync } = await import('child_process');
    execSync(`openssl req -x509 -newkey rsa:2048 -keyout ${keyPath} -out ${certPath} -days 1 -nodes -subj "/CN=localhost" 2>/dev/null`, { stdio: 'inherit' });
  }

  const worker = cluster.fork();

  worker.on('message', (msg) => {
    if (msg.type === 'disconnect-me') {
      console.log(`[PRIMARY] Calling worker.disconnect() (triggered by request ${msg.requestId}, chunk ${msg.chunk})`);
      worker.disconnect();
      console.log('[PRIMARY] worker.disconnect() called');
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
  let disconnectTriggered = false;

  server.on('error', (err) => console.error('[WORKER] Server error:', err));

  server.on('session', (session) => {
    const sessionId = Date.now();
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

    console.log(`[WORKER] Request #${reqId} started`);

    stream.on('error', (err) => console.error(`[WORKER] Request #${reqId} stream error: ${err.message}`));
    stream.on('close', () => console.log(`[WORKER] Request #${reqId} stream closed, rstCode: ${stream.rstCode}`));

    // Handle incoming data (request body chunks)
    stream.on('data', (data) => {
      chunkCount++;
      let parsed;
      try {
        parsed = JSON.parse(data.toString().trim());
      } catch (e) {
        parsed = { raw: data.toString().trim() };
      }

      console.log(`[WORKER] Request #${reqId} received chunk ${chunkCount}: requestId=${parsed.requestId}, chunk=${parsed.chunk}`);

      // Send response headers if not sent
      if (!headersSent) {
        headersSent = true;
        stream.respond({ ':status': 200, 'content-type': 'application/x-ndjson' });
      }

      // Echo back a response chunk
      const responseChunk = JSON.stringify({
        requestId: reqId,
        responseChunk: chunkCount,
        echoedChunk: parsed.chunk,
        time: Date.now()
      }) + '\n';

      try {
        stream.write(responseChunk);
        console.log(`[WORKER] Request #${reqId} sent response chunk ${chunkCount}`);
      } catch (e) {
        console.log(`[WORKER] Request #${reqId} failed to write: ${e.message}`);
      }

      // Check if this chunk should trigger disconnect
      if (parsed.triggerDisconnect && !disconnectTriggered) {
        disconnectTriggered = true;
        console.log(`[WORKER] Request #${reqId} chunk ${chunkCount} TRIGGERING DISCONNECT`);
        process.send({ type: 'disconnect-me', requestId: reqId, chunk: chunkCount });
      }
    });

    // Handle end of request body
    stream.on('end', () => {
      console.log(`[WORKER] Request #${reqId} request body ended (${chunkCount} chunks received)`);
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
    });
  });

  server.listen(PORT, () => {
    console.log(`[WORKER] HTTP/2 server listening on port ${PORT}`);
  });

  process.on('disconnect', () => {
    console.log('[WORKER] IPC disconnected');
  });
}
