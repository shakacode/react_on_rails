#!/usr/bin/env node
/**
 * Aggressive reproduction of Fastify HTTP/2 streaming bug
 *
 * This script tries harder to reproduce the actual empty response bug
 * by simulating the exact conditions that occur with httpx stream_bidi.
 *
 * The bug: When using res.send(stream) with HTTP/2, if the client sends
 * END_STREAM before headers are sent, the response is empty.
 */

import Fastify from 'fastify';
import http2 from 'node:http2';
import { Readable } from 'node:stream';
import { once } from 'node:events';

const PORT = 3458;

// Track all frames sent/received for debugging
let frameLog = [];

function logFrame(direction, type, streamId, flags) {
  frameLog.push({
    time: Date.now(),
    direction,
    type,
    streamId,
    flags,
  });
}

/**
 * Creates a stream that waits for an external signal before producing data.
 * This simulates async props where data arrives later via update chunks.
 */
function createWaitingStream() {
  let resolver;
  const dataPromise = new Promise(r => { resolver = r; });

  const stream = new Readable({
    async read() {
      // Wait for external signal before producing any data
      const data = await dataPromise;
      this.push(data);
      this.push(null);
    }
  });

  return {
    stream,
    sendData: (data) => resolver(data),
  };
}

/**
 * Creates a stream with configurable delay
 */
function createDelayedStream(delayMs) {
  let started = false;
  return new Readable({
    async read() {
      if (started) return;
      started = true;
      await new Promise(r => setTimeout(r, delayMs));
      this.push('{"result":"delayed data"}\n');
      this.push(null);
    }
  });
}

async function startServer() {
  const fastify = Fastify({
    http2: true,
    logger: false,
  });

  // Endpoint that waits indefinitely for data (simulates async props waiting)
  const waitingStreams = new Map();

  fastify.post('/waiting', async (req, res) => {
    const requestId = req.headers['x-request-id'];
    const { stream, sendData } = createWaitingStream();
    waitingStreams.set(requestId, sendData);

    console.log(`[SERVER /waiting] Request ${requestId} - setting up stream`);

    res.header('content-type', 'application/x-ndjson');
    res.status(200);

    // This is the problematic call - headers won't be sent until stream has data
    const result = res.send(stream);

    console.log(`[SERVER /waiting] After res.send() - headersSent: ${res.raw.headersSent}`);

    return result;
  });

  // Endpoint to trigger data for waiting stream
  fastify.post('/trigger/:requestId', async (req, res) => {
    const { requestId } = req.params;
    const sendData = waitingStreams.get(requestId);
    if (sendData) {
      sendData('{"triggered":"data"}\n');
      waitingStreams.delete(requestId);
      return { success: true };
    }
    return { success: false, error: 'Request not found' };
  });

  // Delayed stream endpoint
  fastify.post('/delayed/:delayMs', async (req, res) => {
    const delayMs = parseInt(req.params.delayMs, 10);
    console.log(`[SERVER /delayed] Starting with ${delayMs}ms delay`);

    const stream = createDelayedStream(delayMs);

    res.header('content-type', 'application/x-ndjson');
    res.status(200);

    const sendPromise = res.send(stream);

    console.log(`[SERVER /delayed] After res.send() - headersSent: ${res.raw.headersSent}`);

    return sendPromise;
  });

  // Working endpoint using raw
  fastify.post('/delayed-raw/:delayMs', async (req, res) => {
    const delayMs = parseInt(req.params.delayMs, 10);
    console.log(`[SERVER /delayed-raw] Starting with ${delayMs}ms delay`);

    const stream = createDelayedStream(delayMs);

    // Immediately send headers
    res.raw.writeHead(200, { 'content-type': 'application/x-ndjson' });
    console.log(`[SERVER /delayed-raw] After writeHead() - headersSent: ${res.raw.headersSent}`);

    for await (const chunk of stream) {
      res.raw.write(chunk);
    }
    res.raw.end();
  });

  await fastify.listen({ port: PORT });
  return { fastify, waitingStreams };
}

/**
 * Test that closes the request BEFORE triggering the response data
 */
async function testWaitingStream() {
  console.log('\n' + '='.repeat(70));
  console.log('TEST: Close request before response data is available');
  console.log('='.repeat(70));

  const requestId = `req-${Date.now()}`;

  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT}`);

    const req = client.request({
      ':method': 'POST',
      ':path': '/waiting',
      'content-type': 'application/json',
      'x-request-id': requestId,
    });

    let responseData = '';
    let responseHeaders = null;
    let headersReceived = false;
    const startTime = Date.now();

    req.on('response', (headers) => {
      responseHeaders = headers;
      headersReceived = true;
      console.log(`[CLIENT] HEADERS received at ${Date.now() - startTime}ms`);
    });

    req.on('data', (chunk) => {
      responseData += chunk.toString();
      console.log(`[CLIENT] DATA received at ${Date.now() - startTime}ms: ${chunk.length} bytes`);
    });

    req.on('end', () => {
      console.log(`[CLIENT] Stream ended at ${Date.now() - startTime}ms`);
      console.log(`[CLIENT] Response status: ${responseHeaders?.[':status']}`);
      console.log(`[CLIENT] Response body: "${responseData}"`);
      console.log(`[CLIENT] Body length: ${responseData.length}`);

      client.close();
      resolve({
        status: responseHeaders?.[':status'],
        bodyLength: responseData.length,
        body: responseData,
        headersReceived,
      });
    });

    // Send request body
    req.write(JSON.stringify({ test: 'data' }));

    // Close request immediately (send END_STREAM)
    console.log(`[CLIENT] Sending END_STREAM at ${Date.now() - startTime}ms`);
    req.end();

    // After a delay, trigger the server to send response data
    setTimeout(async () => {
      console.log(`[CLIENT] Triggering server response at ${Date.now() - startTime}ms`);

      // Use a separate connection to trigger
      const triggerClient = http2.connect(`http://localhost:${PORT}`);
      const triggerReq = triggerClient.request({
        ':method': 'POST',
        ':path': `/trigger/${requestId}`,
        'content-type': 'application/json',
      });
      triggerReq.end();

      triggerReq.on('response', () => {
        triggerClient.close();
      });
    }, 500); // Trigger after 500ms - well after END_STREAM is sent
  });
}

/**
 * Test with delayed stream - close request during the delay
 */
async function testDelayedStream(path, delayMs) {
  console.log(`\n` + '='.repeat(70));
  console.log(`TEST: ${path} with ${delayMs}ms delay`);
  console.log('='.repeat(70));

  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT}`);

    const req = client.request({
      ':method': 'POST',
      ':path': `${path}/${delayMs}`,
      'content-type': 'application/json',
    });

    let responseData = '';
    let responseHeaders = null;
    const startTime = Date.now();

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
        delayMs,
        status: responseHeaders?.[':status'],
        bodyLength: responseData.length,
        body: responseData,
      });
    });

    req.on('error', (err) => {
      console.log(`[CLIENT] ERROR: ${err.message}`);
      client.close();
      resolve({ path, delayMs, error: err.message });
    });

    // Send and immediately close
    req.write('{}');
    console.log(`[CLIENT] Sending END_STREAM at ${Date.now() - startTime}ms`);
    req.end();
  });
}

/**
 * Test that resets the stream after sending END_STREAM but before HEADERS
 * This simulates what might happen if the client considers the request failed
 */
async function testStreamReset(delayMs) {
  console.log(`\n` + '='.repeat(70));
  console.log(`TEST: Reset stream before HEADERS (delay: ${delayMs}ms)`);
  console.log('='.repeat(70));

  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT}`);

    const req = client.request({
      ':method': 'POST',
      ':path': `/delayed/${delayMs}`,
      'content-type': 'application/json',
    });

    let responseData = '';
    let responseHeaders = null;
    let wasReset = false;
    const startTime = Date.now();

    req.on('response', (headers) => {
      responseHeaders = headers;
      console.log(`[CLIENT] HEADERS at ${Date.now() - startTime}ms`);
    });

    req.on('data', (chunk) => {
      responseData += chunk.toString();
    });

    req.on('end', () => {
      console.log(`[CLIENT] END at ${Date.now() - startTime}ms - body: ${responseData.length} bytes`);
      client.close();
      resolve({
        status: responseHeaders?.[':status'],
        bodyLength: responseData.length,
        wasReset,
      });
    });

    req.on('error', (err) => {
      console.log(`[CLIENT] ERROR at ${Date.now() - startTime}ms: ${err.message}`);
      client.close();
      resolve({ error: err.message, wasReset });
    });

    // Send and close
    req.write('{}');
    req.end();
    console.log(`[CLIENT] END_STREAM sent at ${Date.now() - startTime}ms`);

    // Reset the stream shortly after, before headers would arrive
    setTimeout(() => {
      if (!responseHeaders) {
        console.log(`[CLIENT] Resetting stream at ${Date.now() - startTime}ms (no HEADERS yet)`);
        wasReset = true;
        req.close(http2.constants.NGHTTP2_CANCEL);
      } else {
        console.log(`[CLIENT] HEADERS already received, not resetting`);
      }
    }, delayMs / 2); // Reset halfway through the delay
  });
}

/**
 * Test using a shared HTTP/2 session with multiple streams
 * to see if one stream closing affects another
 */
async function testMultipleStreams() {
  console.log(`\n` + '='.repeat(70));
  console.log('TEST: Multiple concurrent streams on same connection');
  console.log('='.repeat(70));

  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT}`);
    const results = [];
    let completed = 0;
    const startTime = Date.now();

    // Start 5 concurrent requests with different delays
    const delays = [100, 200, 300, 400, 500];

    for (const delay of delays) {
      const req = client.request({
        ':method': 'POST',
        ':path': `/delayed/${delay}`,
        'content-type': 'application/json',
      });

      let responseData = '';
      let responseHeaders = null;

      req.on('response', (headers) => {
        responseHeaders = headers;
      });

      req.on('data', (chunk) => {
        responseData += chunk.toString();
      });

      req.on('end', () => {
        results.push({
          delay,
          status: responseHeaders?.[':status'],
          bodyLength: responseData.length,
          time: Date.now() - startTime,
        });

        completed++;
        if (completed === delays.length) {
          client.close();
          resolve(results);
        }
      });

      req.on('error', (err) => {
        results.push({ delay, error: err.message });
        completed++;
        if (completed === delays.length) {
          client.close();
          resolve(results);
        }
      });

      req.write('{}');
      req.end();
    }

    console.log(`[CLIENT] Started ${delays.length} concurrent requests`);
  });
}

async function main() {
  console.log('='.repeat(70));
  console.log('Fastify HTTP/2 Streaming Bug - Aggressive Reproduction');
  console.log('='.repeat(70));
  console.log('');
  console.log('Attempting to reproduce empty response bug...');
  console.log('');

  const { fastify, waitingStreams } = await startServer();
  console.log(`Server started on port ${PORT}`);

  const results = {};

  // Test 1: Waiting stream (external trigger)
  results.waiting = await testWaitingStream();

  // Test 2: Delayed stream with res.send()
  results.delayed500 = await testDelayedStream('/delayed', 500);

  // Test 3: Delayed stream with res.raw.writeHead()
  results.delayedRaw500 = await testDelayedStream('/delayed-raw', 500);

  // Test 4: Stream reset before headers
  results.reset = await testStreamReset(500);

  // Test 5: Multiple concurrent streams
  results.concurrent = await testMultipleStreams();

  // Summary
  console.log('\n' + '='.repeat(70));
  console.log('SUMMARY');
  console.log('='.repeat(70));

  console.log('\n1. Waiting stream (trigger after END_STREAM):');
  console.log(`   Status: ${results.waiting.status}, Body: ${results.waiting.bodyLength} bytes`);
  console.log(`   ${results.waiting.bodyLength === 0 ? '*** EMPTY RESPONSE - BUG! ***' : 'OK'}`);

  console.log('\n2. Delayed stream with res.send():');
  console.log(`   Status: ${results.delayed500.status}, Body: ${results.delayed500.bodyLength} bytes`);
  console.log(`   ${results.delayed500.bodyLength === 0 ? '*** EMPTY RESPONSE - BUG! ***' : 'OK'}`);

  console.log('\n3. Delayed stream with res.raw.writeHead():');
  console.log(`   Status: ${results.delayedRaw500.status}, Body: ${results.delayedRaw500.bodyLength} bytes`);
  console.log(`   ${results.delayedRaw500.bodyLength === 0 ? '*** EMPTY RESPONSE - BUG! ***' : 'OK'}`);

  console.log('\n4. Stream reset before headers:');
  if (results.reset.error) {
    console.log(`   Error: ${results.reset.error}`);
  } else {
    console.log(`   Status: ${results.reset.status}, Body: ${results.reset.bodyLength} bytes`);
  }
  console.log(`   Was reset: ${results.reset.wasReset}`);

  console.log('\n5. Concurrent streams:');
  const emptyResponses = results.concurrent.filter(r => r.bodyLength === 0 && !r.error);
  console.log(`   Total: ${results.concurrent.length}, Empty: ${emptyResponses.length}`);
  for (const r of results.concurrent) {
    console.log(`   delay=${r.delay}ms: ${r.error ? `ERROR: ${r.error}` : `${r.bodyLength} bytes in ${r.time}ms`}`);
  }

  // Final analysis
  console.log('\n' + '='.repeat(70));
  console.log('ANALYSIS');
  console.log('='.repeat(70));

  const bugReproduced =
    results.waiting.bodyLength === 0 ||
    results.delayed500.bodyLength === 0 ||
    emptyResponses.length > 0;

  if (bugReproduced) {
    console.log('\n*** BUG REPRODUCED ***');
    console.log('Empty responses were received when using res.send(stream) with async streams.');
  } else {
    console.log('\nBug did not reproduce with Node.js HTTP/2 client.');
    console.log('However, the bug DOES occur with httpx Ruby client.');
    console.log('');
    console.log('The issue is that res.send(stream) delays HEADERS until stream has data.');
    console.log('This can be observed by the "headersSent: false" logs after res.send().');
    console.log('');
    console.log('With res.raw.writeHead(), headers are sent immediately (headersSent: true).');
  }

  console.log('\n' + '='.repeat(70));
  console.log('CONCLUSION');
  console.log('='.repeat(70));
  console.log('');
  console.log('The root cause is Fastify\'s lazy header sending with res.send(stream):');
  console.log('');
  console.log('  res.send(stream)       -> headersSent = false (delayed until data)');
  console.log('  res.raw.writeHead()    -> headersSent = true  (immediate)');
  console.log('');
  console.log('For HTTP/2 bidirectional streaming, headers should be sent immediately');
  console.log('to prevent race conditions with client END_STREAM.');
  console.log('');

  await fastify.close();
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
