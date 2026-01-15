#!/usr/bin/env node
/**
 * Minimal reproduction of Fastify HTTP/2 streaming bug
 *
 * BUG SUMMARY:
 * When using `res.send(stream)` with HTTP/2, Fastify delays sending the HEADERS
 * frame until the stream starts producing data. In bidirectional streaming scenarios
 * where the client sends END_STREAM before the server's stream produces data,
 * the response can be lost or empty.
 *
 * AFFECTED SCENARIO:
 * - HTTP/2 bidirectional streaming (client sends body while expecting streaming response)
 * - Server returns an async stream that doesn't produce data immediately
 * - Client closes its side (END_STREAM) before server's headers are sent
 *
 * WORKAROUND:
 * Use `res.raw.writeHead()` + manual streaming instead of `res.send(stream)`
 *
 * EXPECTED BEHAVIOR:
 * Headers should be sent immediately when `res.send(stream)` is called,
 * not lazily when the stream produces data.
 *
 * To run: node fastify_http2_bug_repro.mjs
 * Requirements: npm install fastify
 */

import Fastify from 'fastify';
import http2 from 'node:http2';
import { Readable } from 'node:stream';
import { setImmediate } from 'node:timers/promises';

const PORT = 3457;
const STREAM_DELAY_MS = 50; // Delay before stream produces data

/**
 * Creates an async stream that delays before producing data.
 * This simulates real-world scenarios where data is fetched asynchronously.
 */
function createAsyncStream(delayMs) {
  let started = false;
  return new Readable({
    async read() {
      if (started) return;
      started = true;

      // Simulate async data fetching (database query, API call, etc.)
      await new Promise(resolve => setTimeout(resolve, delayMs));

      this.push(JSON.stringify({ status: 'ok', message: 'Hello from async stream' }) + '\n');
      this.push(null); // End stream
    }
  });
}

/**
 * Alternative: Immediate stream for comparison
 */
function createImmediateStream() {
  let started = false;
  return new Readable({
    read() {
      if (started) return;
      started = true;
      this.push(JSON.stringify({ status: 'ok', message: 'Hello from immediate stream' }) + '\n');
      this.push(null);
    }
  });
}

async function startServer() {
  const fastify = Fastify({
    http2: true,
    logger: false,
  });

  // Track when headers are actually sent
  fastify.addHook('onSend', async (request, reply, payload) => {
    const timestamp = Date.now();
    console.log(`  [SERVER ${request.url}] onSend hook - headersSent: ${reply.raw.headersSent}, time: ${timestamp}`);
  });

  /**
   * BROKEN ENDPOINT: Uses res.send(stream) with async stream
   * Headers are sent LAZILY when stream produces data
   */
  fastify.post('/async-send', async (req, res) => {
    console.log(`  [SERVER /async-send] Request received`);
    const stream = createAsyncStream(STREAM_DELAY_MS);

    res.header('content-type', 'application/x-ndjson');
    res.status(200);

    // This is the problematic pattern:
    // - send() sets up internal piping
    // - Headers are NOT sent immediately
    // - Headers are sent when stream emits first 'data' event
    const result = res.send(stream);

    console.log(`  [SERVER /async-send] After res.send() - headersSent: ${res.raw.headersSent}`);

    return result;
  });

  /**
   * WORKING ENDPOINT: Uses res.raw.writeHead() with async stream
   * Headers are sent IMMEDIATELY
   */
  fastify.post('/async-raw', async (req, res) => {
    console.log(`  [SERVER /async-raw] Request received`);
    const stream = createAsyncStream(STREAM_DELAY_MS);

    // This works correctly:
    // - writeHead() sends HEADERS frame immediately
    // - Data is written as it becomes available
    res.raw.writeHead(200, { 'content-type': 'application/x-ndjson' });

    console.log(`  [SERVER /async-raw] After writeHead() - headersSent: ${res.raw.headersSent}`);

    for await (const chunk of stream) {
      res.raw.write(chunk);
    }
    res.raw.end();
  });

  /**
   * CONTROL: Immediate stream with res.send()
   * This usually works because data is available immediately
   */
  fastify.post('/immediate-send', async (req, res) => {
    console.log(`  [SERVER /immediate-send] Request received`);
    const stream = createImmediateStream();

    res.header('content-type', 'application/x-ndjson');
    res.status(200);

    const result = res.send(stream);

    // Even here, headersSent might be false immediately after send()
    console.log(`  [SERVER /immediate-send] After res.send() - headersSent: ${res.raw.headersSent}`);

    return result;
  });

  await fastify.listen({ port: PORT });
  return fastify;
}

/**
 * HTTP/2 client that simulates bidirectional streaming behavior
 * where the client closes (END_STREAM) quickly after sending data.
 */
async function testEndpoint(path, closeImmediately = true) {
  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT}`);

    client.on('error', (err) => {
      console.error(`  [CLIENT ${path}] Connection error:`, err.message);
      resolve({ path, error: err.message });
    });

    const req = client.request({
      ':method': 'POST',
      ':path': path,
      'content-type': 'application/json',
    });

    let responseData = '';
    let responseHeaders = null;
    let headersReceivedTime = null;
    const startTime = Date.now();

    req.on('response', (headers) => {
      responseHeaders = headers;
      headersReceivedTime = Date.now();
      console.log(`  [CLIENT ${path}] Received HEADERS at ${headersReceivedTime - startTime}ms - status: ${headers[':status']}`);
    });

    req.on('data', (chunk) => {
      responseData += chunk.toString();
      console.log(`  [CLIENT ${path}] Received DATA at ${Date.now() - startTime}ms - ${chunk.length} bytes`);
    });

    req.on('end', () => {
      const endTime = Date.now();
      console.log(`  [CLIENT ${path}] Stream ended at ${endTime - startTime}ms`);
      client.close();
      resolve({
        path,
        status: responseHeaders?.[':status'],
        bodyLength: responseData.length,
        body: responseData,
        headersTime: headersReceivedTime ? headersReceivedTime - startTime : null,
        totalTime: endTime - startTime,
      });
    });

    req.on('error', (err) => {
      console.error(`  [CLIENT ${path}] Request error:`, err.message);
      client.close();
      resolve({ path, error: err.message });
    });

    // Simulate bidirectional streaming: send body then close immediately
    console.log(`  [CLIENT ${path}] Sending request body...`);
    req.write(JSON.stringify({ test: 'data', timestamp: Date.now() }));

    if (closeImmediately) {
      // Close immediately - this is the problematic case
      // The client sends END_STREAM before server might have sent HEADERS
      console.log(`  [CLIENT ${path}] Closing request (END_STREAM) immediately`);
      req.end();
    } else {
      // Add small delay before closing
      setTimeout(() => {
        console.log(`  [CLIENT ${path}] Closing request (END_STREAM) after delay`);
        req.end();
      }, STREAM_DELAY_MS + 50);
    }
  });
}

/**
 * More aggressive test that tries to race the END_STREAM against headers
 * by sending multiple rapid requests
 */
async function testRapidRequests(path, count = 10) {
  const results = await Promise.all(
    Array(count).fill(null).map((_, i) =>
      new Promise((resolve) => {
        const client = http2.connect(`http://localhost:${PORT}`);

        const req = client.request({
          ':method': 'POST',
          ':path': path,
          'content-type': 'application/json',
        });

        let responseData = '';
        let responseHeaders = null;
        const startTime = Date.now();

        req.on('response', (headers) => {
          responseHeaders = headers;
        });

        req.on('data', (chunk) => {
          responseData += chunk.toString();
        });

        req.on('end', () => {
          client.close();
          resolve({
            index: i,
            status: responseHeaders?.[':status'],
            bodyLength: responseData.length,
            elapsed: Date.now() - startTime,
          });
        });

        req.on('error', (err) => {
          client.close();
          resolve({ index: i, error: err.message });
        });

        // Fire and close as fast as possible
        req.write('{}');
        req.end();
      })
    )
  );

  const empty = results.filter(r => r.bodyLength === 0 && !r.error);
  const errors = results.filter(r => r.error);
  const ok = results.filter(r => r.bodyLength > 0);

  return { total: count, ok: ok.length, empty: empty.length, errors: errors.length, results };
}

async function runTests() {
  console.log('='.repeat(80));
  console.log('Fastify HTTP/2 Streaming Bug Reproduction');
  console.log('='.repeat(80));
  console.log('');
  console.log('BUG: res.send(stream) delays HEADERS frame until stream produces data.');
  console.log('     In bidirectional streaming, if client sends END_STREAM before HEADERS,');
  console.log('     the response may be lost with some HTTP/2 clients (e.g., httpx).');
  console.log('');
  console.log(`Stream delay: ${STREAM_DELAY_MS}ms`);
  console.log('');

  const server = await startServer();
  console.log(`Server started on http://localhost:${PORT}`);
  console.log('');

  const results = [];

  // Test 1: Async stream with res.send() - BROKEN
  console.log('-'.repeat(80));
  console.log('TEST 1: /async-send (res.send with async stream) - PROBLEMATIC');
  console.log('-'.repeat(80));
  results.push(await testEndpoint('/async-send', true));
  console.log('');

  // Small delay between tests
  await new Promise(r => setTimeout(r, 100));

  // Test 2: Async stream with res.raw.writeHead() - WORKING
  console.log('-'.repeat(80));
  console.log('TEST 2: /async-raw (res.raw.writeHead with async stream) - WORKING');
  console.log('-'.repeat(80));
  results.push(await testEndpoint('/async-raw', true));
  console.log('');

  await new Promise(r => setTimeout(r, 100));

  // Test 3: Immediate stream with res.send() - CONTROL
  console.log('-'.repeat(80));
  console.log('TEST 3: /immediate-send (res.send with immediate stream) - CONTROL');
  console.log('-'.repeat(80));
  results.push(await testEndpoint('/immediate-send', true));
  console.log('');

  await new Promise(r => setTimeout(r, 100));

  // Test 4: Async stream with res.send() but delayed client close
  console.log('-'.repeat(80));
  console.log('TEST 4: /async-send with delayed close - TIMING WORKAROUND');
  console.log('-'.repeat(80));
  results.push(await testEndpoint('/async-send', false));
  console.log('');

  // Rapid fire tests to try to trigger race condition
  console.log('-'.repeat(80));
  console.log('TEST 5: Rapid requests to /async-send (trying to trigger race)');
  console.log('-'.repeat(80));
  const rapidAsyncSend = await testRapidRequests('/async-send', 20);
  console.log(`  Results: ${rapidAsyncSend.ok} OK, ${rapidAsyncSend.empty} EMPTY, ${rapidAsyncSend.errors} errors`);
  console.log('');

  console.log('-'.repeat(80));
  console.log('TEST 6: Rapid requests to /async-raw (control)');
  console.log('-'.repeat(80));
  const rapidAsyncRaw = await testRapidRequests('/async-raw', 20);
  console.log(`  Results: ${rapidAsyncRaw.ok} OK, ${rapidAsyncRaw.empty} EMPTY, ${rapidAsyncRaw.errors} errors`);
  console.log('');

  // Print summary
  console.log('='.repeat(80));
  console.log('RESULTS SUMMARY');
  console.log('='.repeat(80));
  console.log('');

  for (const result of results) {
    const status = result.error ? 'ERROR' :
                   result.bodyLength === 0 ? 'EMPTY (BUG!)' : 'OK';
    console.log(`${result.path}:`);
    console.log(`  Status: ${result.status || 'N/A'} | Body: ${result.bodyLength} bytes | Result: ${status}`);
    if (result.headersTime !== null) {
      console.log(`  Headers received at: ${result.headersTime}ms | Total time: ${result.totalTime}ms`);
    }
    if (result.error) {
      console.log(`  Error: ${result.error}`);
    }
    console.log('');
  }

  // Analysis
  console.log('='.repeat(80));
  console.log('ANALYSIS');
  console.log('='.repeat(80));
  console.log('');

  const asyncSendResult = results.find(r => r.path === '/async-send' && results.indexOf(r) === 0);
  const asyncRawResult = results.find(r => r.path === '/async-raw');
  const immediateSendResult = results.find(r => r.path === '/immediate-send');

  console.log('Key observations:');
  console.log('');
  console.log('1. With res.send(stream), headersSent is FALSE immediately after the call.');
  console.log('   Headers are sent lazily when the stream produces its first data chunk.');
  console.log('');
  console.log('2. With res.raw.writeHead(), headersSent is TRUE immediately.');
  console.log('   The HEADERS frame is sent to the client right away.');
  console.log('');
  console.log('3. In HTTP/2 bidirectional streaming, the client may send END_STREAM');
  console.log('   (closing its send side) before the server sends HEADERS.');
  console.log('');
  console.log('4. Some HTTP/2 clients (notably httpx Ruby library) may not correctly');
  console.log('   handle responses where HEADERS arrive after the client sends END_STREAM,');
  console.log('   OR there may be a race condition in how Fastify handles this case.');
  console.log('');

  if (asyncSendResult?.bodyLength === 0 && asyncRawResult?.bodyLength > 0) {
    console.log('*** BUG REPRODUCED: /async-send returned empty, /async-raw succeeded ***');
  } else {
    console.log('Note: The bug may not reproduce with Node.js http2 client, but it');
    console.log('DOES reproduce with the httpx Ruby client in production scenarios.');
    console.log('');
    console.log('The timing difference is still observable:');
    console.log(`  /async-send headers received at: ${asyncSendResult?.headersTime}ms`);
    console.log(`  /async-raw headers received at: ${asyncRawResult?.headersTime}ms`);
  }

  console.log('');
  console.log('Rapid request test results:');
  console.log(`  /async-send: ${rapidAsyncSend.ok}/${rapidAsyncSend.total} OK, ${rapidAsyncSend.empty} empty`);
  console.log(`  /async-raw:  ${rapidAsyncRaw.ok}/${rapidAsyncRaw.total} OK, ${rapidAsyncRaw.empty} empty`);

  if (rapidAsyncSend.empty > 0 && rapidAsyncRaw.empty === 0) {
    console.log('');
    console.log('*** RACE CONDITION DETECTED: /async-send had empty responses under load ***');
  }

  console.log('');
  console.log('='.repeat(80));
  console.log('RECOMMENDATION');
  console.log('='.repeat(80));
  console.log('');
  console.log('For HTTP/2 streaming responses, Fastify should send HEADERS immediately');
  console.log('when res.send(stream) is called, not wait for the stream to produce data.');
  console.log('');
  console.log('This is especially important for:');
  console.log('- Bidirectional streaming (gRPC-like patterns)');
  console.log('- Long-polling / SSE where initial data may be delayed');
  console.log('- Any async stream where data production is not immediate');
  console.log('');

  await server.close();
  console.log('Server closed.');
}

// Run the reproduction
runTests().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
