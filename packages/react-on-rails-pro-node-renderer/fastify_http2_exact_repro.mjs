#!/usr/bin/env node
/**
 * Exact reproduction of node-renderer's incremental-render pattern
 *
 * The key difference from simple tests: the server processes the request body
 * BEFORE starting the response stream. This creates a different timing scenario
 * where END_STREAM from the client might arrive during response setup.
 */

import Fastify from 'fastify';
import http2 from 'node:http2';
import { Readable } from 'node:stream';

const PORT = 3461;

async function startServer() {
  const fastify = Fastify({
    http2: true,
    logger: false,
  });

  // Add content-type parser for NDJSON (like node-renderer does)
  fastify.addContentTypeParser('application/x-ndjson', { parseAs: 'string' }, (req, body, done) => {
    done(null, body);
  });
  fastify.addContentTypeParser('*', { parseAs: 'buffer' }, (req, body, done) => {
    done(null, body);
  });

  /**
   * Pattern 1: Read full request body, THEN send streaming response
   * This matches the node-renderer's incremental-render endpoint
   */
  fastify.post('/read-then-stream', async (req, res) => {
    const startTime = Date.now();
    console.log(`[SERVER] Request received`);

    // Fastify has already parsed the body by the time we get here
    // This means END_STREAM has already been received from the client
    const body = req.body;
    console.log(`[SERVER] Request body received (${typeof body === 'string' ? body.length : JSON.stringify(body).length} bytes) at ${Date.now() - startTime}ms`);

    // Small delay to simulate processing (parsing NDJSON, setting up VM, etc.)
    await new Promise(r => setTimeout(r, 10));
    console.log(`[SERVER] Processing complete at ${Date.now() - startTime}ms`);

    // Now create response stream
    const responseStream = new Readable({
      read() {
        // Simulate async data production
        setTimeout(() => {
          this.push('{"html":"<div>SSR Content</div>"}\n');
          this.push(null);
        }, 50);
      }
    });

    // Using res.send(stream) - THE PROBLEMATIC PATTERN
    res.header('content-type', 'application/x-ndjson');
    res.status(200);

    console.log(`[SERVER] Calling res.send(stream) at ${Date.now() - startTime}ms`);
    const result = res.send(responseStream);
    console.log(`[SERVER] After res.send() - headersSent: ${res.raw.headersSent} at ${Date.now() - startTime}ms`);

    return result;
  });

  /**
   * Pattern 2: Same but with res.raw.writeHead() - THE FIX
   */
  fastify.post('/read-then-stream-fixed', async (req, res) => {
    const startTime = Date.now();
    console.log(`[SERVER] Request received`);

    // Fastify has already parsed the body
    const body = req.body;
    console.log(`[SERVER] Request body received at ${Date.now() - startTime}ms`);

    // Small delay to simulate processing
    await new Promise(r => setTimeout(r, 10));
    console.log(`[SERVER] Processing complete at ${Date.now() - startTime}ms`);

    // Now create response stream
    const responseStream = new Readable({
      read() {
        setTimeout(() => {
          this.push('{"html":"<div>SSR Content</div>"}\n');
          this.push(null);
        }, 50);
      }
    });

    // Using res.raw.writeHead() - THE FIX
    console.log(`[SERVER] Calling writeHead() at ${Date.now() - startTime}ms`);
    res.raw.writeHead(200, { 'content-type': 'application/x-ndjson' });
    console.log(`[SERVER] After writeHead() - headersSent: ${res.raw.headersSent} at ${Date.now() - startTime}ms`);

    for await (const chunk of responseStream) {
      res.raw.write(chunk);
    }
    res.raw.end();
  });

  /**
   * Pattern 3: Process request body line by line (like NDJSON streaming)
   * Then respond with a stream
   */
  fastify.post('/ndjson-stream', async (req, res) => {
    const startTime = Date.now();
    console.log(`[SERVER] Request received`);

    // Parse NDJSON from body
    const body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    const lines = body.split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
    console.log(`[SERVER] Parsed ${lines.length} NDJSON lines at ${Date.now() - startTime}ms`);

    // Simulate async rendering
    await new Promise(r => setTimeout(r, 10));

    // Create response stream
    const responseStream = new Readable({
      read() {
        setTimeout(() => {
          this.push('{"html":"<div>Rendered</div>"}\n');
          this.push(null);
        }, 50);
      }
    });

    res.header('content-type', 'application/x-ndjson');
    res.status(200);

    console.log(`[SERVER] Calling res.send(stream) at ${Date.now() - startTime}ms`);
    const result = res.send(responseStream);
    console.log(`[SERVER] After res.send() - headersSent: ${res.raw.headersSent} at ${Date.now() - startTime}ms`);

    return result;
  });

  await fastify.listen({ port: PORT });
  return fastify;
}

async function testEndpoint(path, requestBody) {
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
      console.log(`[CLIENT] HEADERS received at ${Date.now() - startTime}ms - status: ${headers[':status']}`);
    });

    req.on('data', (chunk) => {
      responseData += chunk.toString();
      console.log(`[CLIENT] DATA received at ${Date.now() - startTime}ms: ${chunk.length} bytes`);
    });

    req.on('end', () => {
      console.log(`[CLIENT] Stream ended at ${Date.now() - startTime}ms`);
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

    // Send request body and close IMMEDIATELY
    console.log(`[CLIENT] Sending request body at ${Date.now() - startTime}ms`);
    req.write(requestBody);
    console.log(`[CLIENT] Sending END_STREAM at ${Date.now() - startTime}ms`);
    req.end();
  });
}

async function main() {
  console.log('='.repeat(70));
  console.log('Exact Node-Renderer Pattern Reproduction');
  console.log('='.repeat(70));
  console.log('');
  console.log('Testing the exact pattern used in node-renderer:');
  console.log('1. Read full request body');
  console.log('2. Process/parse request');
  console.log('3. Send streaming response');
  console.log('');

  const server = await startServer();
  console.log(`Server started on port ${PORT}`);
  console.log('');

  // NDJSON request body (like node-renderer receives)
  const requestBody = JSON.stringify({
    gemVersion: '16.2.0',
    protocolVersion: '2.0.0',
    password: 'test',
    renderingRequest: 'ReactOnRails.render()',
  }) + '\n';

  // Test 1: res.send(stream) after reading request body
  console.log('-'.repeat(70));
  console.log('TEST 1: /read-then-stream (res.send after reading body)');
  console.log('-'.repeat(70));
  const result1 = await testEndpoint('/read-then-stream', requestBody);
  console.log(`Result: status=${result1.status}, body=${result1.bodyLength} bytes`);
  console.log(`Body: ${result1.body || '(EMPTY)'}`);
  console.log('');

  await new Promise(r => setTimeout(r, 200));

  // Test 2: res.raw.writeHead() after reading request body
  console.log('-'.repeat(70));
  console.log('TEST 2: /read-then-stream-fixed (writeHead after reading body)');
  console.log('-'.repeat(70));
  const result2 = await testEndpoint('/read-then-stream-fixed', requestBody);
  console.log(`Result: status=${result2.status}, body=${result2.bodyLength} bytes`);
  console.log(`Body: ${result2.body || '(EMPTY)'}`);
  console.log('');

  await new Promise(r => setTimeout(r, 200));

  // Test 3: NDJSON parsing then stream
  console.log('-'.repeat(70));
  console.log('TEST 3: /ndjson-stream (parse NDJSON then stream)');
  console.log('-'.repeat(70));
  const result3 = await testEndpoint('/ndjson-stream', requestBody);
  console.log(`Result: status=${result3.status}, body=${result3.bodyLength} bytes`);
  console.log(`Body: ${result3.body || '(EMPTY)'}`);
  console.log('');

  // Summary
  console.log('='.repeat(70));
  console.log('SUMMARY');
  console.log('='.repeat(70));
  console.log('');
  console.log(`/read-then-stream:       ${result1.bodyLength === 0 ? 'EMPTY (BUG!)' : `${result1.bodyLength} bytes (OK)`}`);
  console.log(`/read-then-stream-fixed: ${result2.bodyLength === 0 ? 'EMPTY (BUG!)' : `${result2.bodyLength} bytes (OK)`}`);
  console.log(`/ndjson-stream:          ${result3.bodyLength === 0 ? 'EMPTY (BUG!)' : `${result3.bodyLength} bytes (OK)`}`);
  console.log('');

  if (result1.bodyLength === 0 || result3.bodyLength === 0) {
    console.log('*** BUG REPRODUCED: Empty response when using res.send(stream) ***');
    console.log('');
    console.log('The key factor is: reading the request body BEFORE sending the response.');
    console.log('When the server reads req.raw, it waits for END_STREAM from the client.');
    console.log('By the time res.send(stream) is called, END_STREAM has already arrived.');
    console.log('This creates the race condition that causes empty responses.');
  }

  await server.close();
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
