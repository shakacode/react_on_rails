#!/usr/bin/env node
/**
 * Reproduction of the EXACT bug pattern in node-renderer
 *
 * THE BUG: onResponseStart is called with `void` (fire-and-forget),
 * meaning the response setup happens asynchronously while the
 * request handler continues/completes.
 *
 * When combined with res.send(stream) delaying headers, this creates
 * a race condition where the request handler finishes before headers
 * are sent.
 */

import Fastify from 'fastify';
import http2 from 'node:http2';
import { PassThrough } from 'node:stream';
import { createInterface } from 'node:readline';

const PORT = 3463;

async function startServer() {
  const fastify = Fastify({
    http2: true,
    logger: false,
  });

  fastify.removeAllContentTypeParsers();
  fastify.addContentTypeParser('*', (req, payload, done) => {
    done(null, payload);
  });

  /**
   * THE EXACT BUG PATTERN from node-renderer:
   *
   * handleIncrementalRenderStream() does:
   *   void onResponseStart(response);  // <-- NOT AWAITED!
   *
   * This means setResponse() runs in the background while the
   * request stream processing continues.
   */
  fastify.post('/void-response-bug', async (req, res) => {
    const startTime = Date.now();
    console.log(`[SERVER] Request received at ${Date.now() - startTime}ms`);

    const requestStream = req.raw;
    const rl = createInterface({ input: requestStream });

    // Process NDJSON stream
    let firstLineReceived = false;

    for await (const line of rl) {
      console.log(`[SERVER] Received line at ${Date.now() - startTime}ms`);

      if (!firstLineReceived) {
        firstLineReceived = true;

        // Create response stream
        const responseStream = new PassThrough();

        // THE BUG: void (fire-and-forget) - doesn't wait for headers to be sent!
        void (async () => {
          console.log(`[SERVER] Starting async response at ${Date.now() - startTime}ms`);

          // Simulate some async work (like in setResponse)
          await new Promise(r => setTimeout(r, 10));

          res.header('content-type', 'application/x-ndjson');
          res.status(200);

          console.log(`[SERVER] Calling res.send(stream) at ${Date.now() - startTime}ms`);
          res.send(responseStream);
          console.log(`[SERVER] After res.send() - headersSent: ${res.raw.headersSent} at ${Date.now() - startTime}ms`);

          // Write data after delay
          setTimeout(() => {
            console.log(`[SERVER] Writing data at ${Date.now() - startTime}ms`);
            responseStream.write('{"html":"<div>SSR</div>"}\n');
            responseStream.end();
          }, 50);
        })();

        // DON'T return here - continue processing stream (like node-renderer does)
      } else {
        console.log(`[SERVER] Update chunk received at ${Date.now() - startTime}ms`);
      }
    }

    // Stream ended
    console.log(`[SERVER] Request stream ended at ${Date.now() - startTime}ms`);
    // Note: The function returns here, but the async response might still be pending!
  });

  /**
   * FIXED VERSION: await the response setup
   */
  fastify.post('/await-response-fixed', async (req, res) => {
    const startTime = Date.now();
    console.log(`[SERVER] Request received at ${Date.now() - startTime}ms`);

    const requestStream = req.raw;
    const rl = createInterface({ input: requestStream });

    let firstLineReceived = false;
    let responsePromise;

    for await (const line of rl) {
      console.log(`[SERVER] Received line at ${Date.now() - startTime}ms`);

      if (!firstLineReceived) {
        firstLineReceived = true;

        const responseStream = new PassThrough();

        // FIXED: Await the response setup
        responsePromise = (async () => {
          console.log(`[SERVER] Starting response at ${Date.now() - startTime}ms`);

          // Use writeHead for immediate headers
          res.raw.writeHead(200, { 'content-type': 'application/x-ndjson' });
          console.log(`[SERVER] After writeHead() - headersSent: ${res.raw.headersSent} at ${Date.now() - startTime}ms`);

          // Wait for stream to complete
          await new Promise((resolve) => {
            setTimeout(() => {
              console.log(`[SERVER] Writing data at ${Date.now() - startTime}ms`);
              res.raw.write('{"html":"<div>SSR</div>"}\n');
              res.raw.end();
              resolve(undefined);
            }, 50);
          });
        })();
      }
    }

    console.log(`[SERVER] Request stream ended at ${Date.now() - startTime}ms`);

    // Wait for response to complete before returning
    if (responsePromise) {
      await responsePromise;
    }
  });

  await fastify.listen({ port: PORT });
  return fastify;
}

async function testEndpoint(path) {
  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT}`);
    const startTime = Date.now();

    const req = client.request({
      ':method': 'POST',
      ':path': path,
      'content-type': 'application/x-ndjson',
    });

    let responseData = '';
    let responseHeaders = null;

    req.on('response', (headers) => {
      responseHeaders = headers;
      console.log(`[CLIENT] HEADERS at ${Date.now() - startTime}ms - status: ${headers[':status']}`);
    });

    req.on('data', (chunk) => {
      responseData += chunk.toString();
      console.log(`[CLIENT] DATA at ${Date.now() - startTime}ms: ${chunk.length} bytes`);
    });

    req.on('end', () => {
      console.log(`[CLIENT] END at ${Date.now() - startTime}ms`);
      client.close();
      resolve({
        path,
        status: responseHeaders?.[':status'],
        bodyLength: responseData.length,
        body: responseData,
      });
    });

    req.on('error', (err) => {
      console.log(`[CLIENT] ERROR: ${err.message}`);
      client.close();
      resolve({ path, error: err.message });
    });

    // Send NDJSON
    const line1 = JSON.stringify({ type: 'initial', data: 'test' }) + '\n';
    const line2 = JSON.stringify({ type: 'update', data: 'chunk' }) + '\n';

    console.log(`[CLIENT] Sending line 1 at ${Date.now() - startTime}ms`);
    req.write(line1);
    console.log(`[CLIENT] Sending line 2 at ${Date.now() - startTime}ms`);
    req.write(line2);
    console.log(`[CLIENT] Sending END_STREAM at ${Date.now() - startTime}ms`);
    req.end();
  });
}

async function main() {
  console.log('='.repeat(70));
  console.log('void Response Bug Reproduction');
  console.log('='.repeat(70));
  console.log('');
  console.log('This reproduces the EXACT bug pattern in node-renderer:');
  console.log('  void onResponseStart(response);  // NOT AWAITED');
  console.log('');

  const server = await startServer();
  console.log(`Server on port ${PORT}\n`);

  // Test 1: void (fire-and-forget) response - THE BUG
  console.log('-'.repeat(70));
  console.log('TEST 1: void response (fire-and-forget) - THE BUG');
  console.log('-'.repeat(70));
  const result1 = await testEndpoint('/void-response-bug');
  console.log(`\nResult: status=${result1.status}, body=${result1.bodyLength} bytes`);
  console.log(`Body: "${result1.body || '(EMPTY)'}"\n`);

  await new Promise(r => setTimeout(r, 500));

  // Test 2: await response - FIXED
  console.log('-'.repeat(70));
  console.log('TEST 2: await response - FIXED');
  console.log('-'.repeat(70));
  const result2 = await testEndpoint('/await-response-fixed');
  console.log(`\nResult: status=${result2.status}, body=${result2.bodyLength} bytes`);
  console.log(`Body: "${result2.body || '(EMPTY)'}"\n`);

  // Summary
  console.log('='.repeat(70));
  console.log('SUMMARY');
  console.log('='.repeat(70));
  console.log('');
  console.log(`void response:  ${result1.bodyLength === 0 ? 'EMPTY (BUG!)' : `${result1.bodyLength} bytes`}`);
  console.log(`await response: ${result2.bodyLength === 0 ? 'EMPTY (BUG!)' : `${result2.bodyLength} bytes`}`);
  console.log('');

  if (result1.bodyLength === 0 && result2.bodyLength > 0) {
    console.log('*** BUG REPRODUCED ***');
    console.log('');
    console.log('The fire-and-forget pattern (void onResponseStart) combined with');
    console.log('res.send(stream) delaying headers causes empty responses.');
  }

  await server.close();
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
