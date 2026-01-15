#!/usr/bin/env node
/**
 * Reproduction matching the exact incremental-render endpoint pattern
 *
 * Key difference: The endpoint receives STREAMING NDJSON - it doesn't wait
 * for the full body, but processes lines as they arrive. However, the response
 * stream is created AFTER the initial request line is parsed.
 *
 * The issue might be: client sends END_STREAM, but the server hasn't
 * started responding yet because it's still setting up.
 */

import Fastify from 'fastify';
import http2 from 'node:http2';
import { Readable, PassThrough } from 'node:stream';
import { once } from 'node:events';
import { createInterface } from 'node:readline';

const PORT = 3462;

async function startServer() {
  const fastify = Fastify({
    http2: true,
    logger: false,
  });

  // Disable automatic body parsing - we'll handle the stream manually
  fastify.removeAllContentTypeParsers();
  fastify.addContentTypeParser('*', (req, payload, done) => {
    done(null, payload); // Pass through the raw stream
  });

  /**
   * Pattern matching node-renderer's incremental-render endpoint:
   * 1. Read first NDJSON line from request stream
   * 2. Start processing (rendering)
   * 3. Create response stream
   * 4. Continue reading update chunks from request
   * 5. Write to response as rendering produces output
   */
  fastify.post('/incremental-render', async (req, res) => {
    const startTime = Date.now();
    console.log(`[SERVER] Request received at ${Date.now() - startTime}ms`);

    const requestStream = req.raw;
    const rl = createInterface({ input: requestStream });

    // Read first line (initial request)
    const firstLinePromise = new Promise((resolve) => {
      rl.once('line', (line) => {
        resolve(line);
      });
    });

    const firstLine = await firstLinePromise;
    console.log(`[SERVER] First NDJSON line received at ${Date.now() - startTime}ms`);

    let initialRequest;
    try {
      initialRequest = JSON.parse(firstLine);
    } catch (e) {
      res.status(400).send({ error: 'Invalid JSON' });
      return;
    }

    // Simulate rendering setup (small delay)
    await new Promise(r => setTimeout(r, 5));
    console.log(`[SERVER] Rendering setup complete at ${Date.now() - startTime}ms`);

    // Create response stream that will produce output asynchronously
    const responseStream = new PassThrough();

    // Start "rendering" - this simulates async SSR output
    setTimeout(() => {
      console.log(`[SERVER] Rendering producing output at ${Date.now() - startTime}ms`);
      responseStream.write('{"html":"<div>Initial SSR</div>"}\n');
    }, 20);

    // End after more delay
    setTimeout(() => {
      console.log(`[SERVER] Rendering complete at ${Date.now() - startTime}ms`);
      responseStream.end();
    }, 50);

    // THE PROBLEMATIC PATTERN: res.send(stream)
    res.header('content-type', 'application/x-ndjson');
    res.status(200);

    console.log(`[SERVER] Calling res.send(stream) at ${Date.now() - startTime}ms`);
    console.log(`[SERVER] req.raw.readableEnded: ${requestStream.readableEnded}`);

    const result = res.send(responseStream);

    console.log(`[SERVER] After res.send() - headersSent: ${res.raw.headersSent} at ${Date.now() - startTime}ms`);

    // Continue processing update chunks (but don't block on them)
    rl.on('line', (line) => {
      console.log(`[SERVER] Update chunk received at ${Date.now() - startTime}ms`);
    });

    return result;
  });

  /**
   * Same pattern but with the fix: res.raw.writeHead()
   */
  fastify.post('/incremental-render-fixed', async (req, res) => {
    const startTime = Date.now();
    console.log(`[SERVER] Request received at ${Date.now() - startTime}ms`);

    const requestStream = req.raw;
    const rl = createInterface({ input: requestStream });

    const firstLinePromise = new Promise((resolve) => {
      rl.once('line', (line) => {
        resolve(line);
      });
    });

    const firstLine = await firstLinePromise;
    console.log(`[SERVER] First NDJSON line received at ${Date.now() - startTime}ms`);

    let initialRequest;
    try {
      initialRequest = JSON.parse(firstLine);
    } catch (e) {
      res.status(400).send({ error: 'Invalid JSON' });
      return;
    }

    await new Promise(r => setTimeout(r, 5));
    console.log(`[SERVER] Rendering setup complete at ${Date.now() - startTime}ms`);

    // THE FIX: Use res.raw.writeHead() to send headers immediately
    console.log(`[SERVER] Calling writeHead() at ${Date.now() - startTime}ms`);
    res.raw.writeHead(200, { 'content-type': 'application/x-ndjson' });
    console.log(`[SERVER] After writeHead() - headersSent: ${res.raw.headersSent} at ${Date.now() - startTime}ms`);

    // Write rendering output
    setTimeout(() => {
      console.log(`[SERVER] Rendering producing output at ${Date.now() - startTime}ms`);
      res.raw.write('{"html":"<div>Initial SSR</div>"}\n');
    }, 20);

    setTimeout(() => {
      console.log(`[SERVER] Rendering complete at ${Date.now() - startTime}ms`);
      res.raw.end();
    }, 50);

    rl.on('line', (line) => {
      console.log(`[SERVER] Update chunk received at ${Date.now() - startTime}ms`);
    });
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

    // Send initial request NDJSON
    const initialRequest = JSON.stringify({
      gemVersion: '16.2.0',
      protocolVersion: '2.0.0',
      password: 'test',
      renderingRequest: 'ReactOnRails.render()',
    }) + '\n';

    // Send update chunk
    const updateChunk = JSON.stringify({
      bundleTimestamp: 'test',
      updateChunk: 'asyncProps.set("key", "value")',
    }) + '\n';

    console.log(`[CLIENT] Sending initial request at ${Date.now() - startTime}ms`);
    req.write(initialRequest);

    console.log(`[CLIENT] Sending update chunk at ${Date.now() - startTime}ms`);
    req.write(updateChunk);

    // Close IMMEDIATELY - send END_STREAM
    console.log(`[CLIENT] Sending END_STREAM at ${Date.now() - startTime}ms`);
    req.end();
  });
}

async function main() {
  console.log('='.repeat(70));
  console.log('Incremental Render Pattern Reproduction');
  console.log('='.repeat(70));
  console.log('');
  console.log('Simulating the exact node-renderer incremental-render pattern:');
  console.log('- Process NDJSON lines from request stream');
  console.log('- Create response stream after parsing initial request');
  console.log('- Client sends END_STREAM quickly');
  console.log('');

  const server = await startServer();
  console.log(`Server started on port ${PORT}`);
  console.log('');

  // Test 1: res.send(stream)
  console.log('-'.repeat(70));
  console.log('TEST 1: /incremental-render (res.send with stream)');
  console.log('-'.repeat(70));
  const result1 = await testEndpoint('/incremental-render');
  console.log(`Result: status=${result1.status}, body=${result1.bodyLength} bytes`);
  console.log(`Body: "${result1.body || '(EMPTY)'}"`);
  console.log('');

  await new Promise(r => setTimeout(r, 200));

  // Test 2: res.raw.writeHead()
  console.log('-'.repeat(70));
  console.log('TEST 2: /incremental-render-fixed (writeHead)');
  console.log('-'.repeat(70));
  const result2 = await testEndpoint('/incremental-render-fixed');
  console.log(`Result: status=${result2.status}, body=${result2.bodyLength} bytes`);
  console.log(`Body: "${result2.body || '(EMPTY)'}"`);
  console.log('');

  // Summary
  console.log('='.repeat(70));
  console.log('SUMMARY');
  console.log('='.repeat(70));
  console.log('');
  console.log(`res.send(stream):    ${result1.bodyLength === 0 ? 'EMPTY (BUG!)' : `${result1.bodyLength} bytes`}`);
  console.log(`res.raw.writeHead(): ${result2.bodyLength === 0 ? 'EMPTY (BUG!)' : `${result2.bodyLength} bytes`}`);

  if (result1.bodyLength === 0 && result2.bodyLength > 0) {
    console.log('');
    console.log('*** BUG REPRODUCED ***');
  }

  await server.close();
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
