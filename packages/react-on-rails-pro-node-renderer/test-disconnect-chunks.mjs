#!/usr/bin/env node
/**
 * Test: Does worker.disconnect() prevent receiving remaining chunks on an existing connection?
 *
 * This script tests the hypothesis that worker.disconnect() should NOT interrupt
 * data reception on already-established HTTP connections when using Fastify with HTTP/2.
 *
 * Run: node test-disconnect-chunks.mjs
 */

import cluster from 'cluster';
import http2 from 'http2';
import Fastify from 'fastify';
import { setTimeout as delay } from 'timers/promises';

const PORT = 9876;
const CHUNK_COUNT = 10;
const CHUNK_DELAY_MS = 200;
const DISCONNECT_AFTER_CHUNK = 3; // Trigger disconnect after receiving this many chunks

// ============================================================================
// MASTER PROCESS
// ============================================================================
if (cluster.isPrimary) {
  console.log('═'.repeat(70));
  console.log('TEST: Does worker.disconnect() prevent receiving remaining chunks?');
  console.log('       (Using Fastify with HTTP/2, like the real node renderer)');
  console.log('═'.repeat(70));
  console.log(`\nConfig: ${CHUNK_COUNT} chunks, disconnect after chunk #${DISCONNECT_AFTER_CHUNK}`);
  console.log('');

  const worker = cluster.fork();
  let chunksReceivedByServer = 0;
  let chunksSentByClient = 0;

  worker.on('message', (msg) => {
    if (msg.type === 'ready') {
      console.log('[MASTER] Worker is ready, starting client...\n');
      runClient();
    } else if (msg.type === 'chunk_received') {
      chunksReceivedByServer = msg.chunkNum;
      console.log(`[MASTER] Worker received chunk #${msg.chunkNum}: "${msg.data}"`);
    } else if (msg.type === 'disconnect_called') {
      console.log(`[MASTER] ⚠️  worker.disconnect() was called after chunk #${msg.afterChunk}`);
    } else if (msg.type === 'request_complete') {
      console.log(`[MASTER] ✓ Request complete. Total chunks received: ${msg.totalChunks}`);
    }
  });

  worker.on('disconnect', () => {
    console.log('[MASTER] Worker disconnected event fired');
  });

  worker.on('exit', (code) => {
    console.log(`[MASTER] Worker exited with code ${code}`);
    printResults();
  });

  async function runClient() {
    console.log('[CLIENT] Connecting via HTTP/2...');

    const client = http2.connect(`http://localhost:${PORT}`);
    console.log(`[CLIENT] Session type: ${client.constructor.name}`);

    client.on('error', (err) => {
      console.log(`[CLIENT] Connection error: ${err.message}`);
    });

    const req = client.request({
      ':method': 'POST',
      ':path': '/test-chunks',
      'content-type': 'application/x-ndjson',
    });

    req.on('response', (headers) => {
      console.log(`[CLIENT] Got response status: ${headers[':status']}`);
    });

    let responseData = '';
    req.on('data', (chunk) => {
      responseData += chunk.toString();
    });

    req.on('end', () => {
      console.log(`[CLIENT] Response body: ${responseData}`);
      client.close();
    });

    req.on('error', (err) => {
      console.log(`[CLIENT] Request error: ${err.message}`);
    });

    // Send chunks with delays
    for (let i = 1; i <= CHUNK_COUNT; i++) {
      const chunkData = `${JSON.stringify({ chunk: i, data: `chunk-${i}-data` })}\n`;
      req.write(chunkData);
      chunksSentByClient = i;
      console.log(`[CLIENT] Sent chunk #${i}`);
      await delay(CHUNK_DELAY_MS);
    }

    req.end();
    console.log('[CLIENT] Finished sending all chunks');
  }

  function printResults() {
    console.log(`\n${'═'.repeat(70)}`);
    console.log('RESULTS');
    console.log('═'.repeat(70));
    console.log(`Chunks sent by client:     ${chunksSentByClient}`);
    console.log(`Chunks received by server: ${chunksReceivedByServer}`);
    console.log(`Disconnect called after:   chunk #${DISCONNECT_AFTER_CHUNK}`);
    console.log('');

    if (chunksReceivedByServer === CHUNK_COUNT) {
      console.log('✅ SUCCESS: All chunks were received after worker.disconnect()');
      console.log('   worker.disconnect() does NOT prevent receiving remaining chunks.');
    } else if (chunksReceivedByServer > DISCONNECT_AFTER_CHUNK) {
      console.log(
        `⚠️  PARTIAL: Received ${chunksReceivedByServer - DISCONNECT_AFTER_CHUNK} chunks after disconnect`,
      );
      console.log('   Some chunks were received, but not all.');
    } else {
      console.log('❌ FAILURE: No chunks received after worker.disconnect()');
      console.log('   worker.disconnect() DOES prevent receiving remaining chunks.');
    }
    console.log('═'.repeat(70));
  }
}

// ============================================================================
// WORKER PROCESS (Fastify with HTTP/2)
// ============================================================================
else {
  console.log(`[WORKER #${cluster.worker.id}] Starting Fastify HTTP/2 server...`);

  const app = Fastify({
    http2: true,
    logger: false,
  });

  let disconnectCalled = false;

  // Register NDJSON content type parser to get raw stream
  app.addContentTypeParser('application/x-ndjson', (req, payload, done) => {
    done(null, payload);
  });

  // Test endpoint that receives chunked NDJSON
  app.post('/test-chunks', async (request, reply) => {
    console.log('[WORKER] Received POST /test-chunks');

    let buffer = '';
    let chunkCount = 0;

    // Process the raw stream
    for await (const data of request.raw) {
      buffer += data.toString();

      // Process complete NDJSON lines
      let newlineIdx;
      while ((newlineIdx = buffer.indexOf('\n')) !== -1) {
        const line = buffer.slice(0, newlineIdx).trim();
        buffer = buffer.slice(newlineIdx + 1);

        if (line) {
          chunkCount++;
          try {
            JSON.parse(line); // Validate JSON
            process.send({ type: 'chunk_received', chunkNum: chunkCount, data: line });

            // Trigger disconnect after specified chunk
            if (chunkCount === DISCONNECT_AFTER_CHUNK && !disconnectCalled) {
              disconnectCalled = true;
              console.log(`[WORKER] Calling worker.disconnect() after chunk #${chunkCount}...`);
              process.send({ type: 'disconnect_called', afterChunk: chunkCount });
              cluster.worker.disconnect();
            }
          } catch (e) {
            console.log(`[WORKER] Failed to parse: ${line}`);
          }
        }
      }
    }

    console.log(`[WORKER] Stream ended. Total chunks received: ${chunkCount}`);
    process.send({ type: 'request_complete', totalChunks: chunkCount });

    return { received: chunkCount };
  });

  app.addHook('onResponse', async (instance, done) => {
    console.log('[WORKER] onResponse hook triggered, cleaning up...');
    done();
  });

  // Start server
  app.listen({ port: PORT }, (err) => {
    if (err) {
      console.error(`[WORKER] Failed to start server: ${err.message}`);
      process.exit(1);
    }
    console.log(`[WORKER] Fastify server listening on port ${PORT}`);
    console.log(`[WORKER] Server type: ${app.server.constructor.name}`);
    process.send({ type: 'ready' });
  });
}
