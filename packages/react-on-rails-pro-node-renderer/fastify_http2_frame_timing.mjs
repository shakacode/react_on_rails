#!/usr/bin/env node
/**
 * HTTP/2 Frame Timing Analysis
 *
 * This script proves that Fastify delays sending HEADERS frames when using
 * res.send(stream), by intercepting and logging all HTTP/2 frames.
 *
 * The bug: HEADERS should be sent immediately when res.send() is called,
 * not when the stream produces its first chunk.
 */

import { createServer } from 'node:http2';
import http2 from 'node:http2';
import { Readable } from 'node:stream';

const PORT = 3459;

// Frame type names for logging
const FRAME_TYPES = {
  0: 'DATA',
  1: 'HEADERS',
  2: 'PRIORITY',
  3: 'RST_STREAM',
  4: 'SETTINGS',
  5: 'PUSH_PROMISE',
  6: 'PING',
  7: 'GOAWAY',
  8: 'WINDOW_UPDATE',
  9: 'CONTINUATION',
};

/**
 * Creates a raw HTTP/2 server (not Fastify) that logs all frames
 * This helps us understand the expected behavior
 */
function createRawServer() {
  const server = createServer();
  const startTime = Date.now();

  const log = (msg) => console.log(`[${Date.now() - startTime}ms] ${msg}`);

  server.on('stream', async (stream, headers) => {
    const path = headers[':path'];
    log(`SERVER: Received request for ${path}`);

    if (path === '/immediate') {
      // Send headers immediately, then data
      log('SERVER: Sending HEADERS immediately');
      stream.respond({ ':status': 200, 'content-type': 'application/json' });
      log(`SERVER: After respond() - headersSent: ${stream.headersSent}`);

      // Delay before sending data
      await new Promise(r => setTimeout(r, 200));
      log('SERVER: Sending DATA');
      stream.end('{"result":"immediate headers"}\n');

    } else if (path === '/delayed-headers') {
      // Simulate Fastify's behavior: delay headers until data is ready
      log('SERVER: Delaying HEADERS until data is ready...');

      await new Promise(r => setTimeout(r, 200));

      log('SERVER: NOW sending HEADERS + DATA together');
      stream.respond({ ':status': 200, 'content-type': 'application/json' });
      stream.end('{"result":"delayed headers"}\n');

    } else if (path === '/stream-delayed') {
      // Use a stream that delays before producing data
      log('SERVER: Setting up delayed stream');

      const delayedStream = new Readable({
        async read() {
          if (this._started) return;
          this._started = true;
          log('SERVER: Stream read() called, waiting 200ms...');
          await new Promise(r => setTimeout(r, 200));
          log('SERVER: Stream producing data NOW');
          this.push('{"result":"stream delayed"}\n');
          this.push(null);
        }
      });

      // This is what Fastify does internally with res.send(stream)
      // Headers are sent, then stream is piped
      stream.respond({ ':status': 200, 'content-type': 'application/json' });
      log(`SERVER: After respond() - headersSent: ${stream.headersSent}`);
      delayedStream.pipe(stream);
    }
  });

  server.on('session', (session) => {
    // Log when frames are received
    session.on('frameError', (type, code, id) => {
      log(`SERVER FRAME ERROR: type=${FRAME_TYPES[type]}, code=${code}, stream=${id}`);
    });
  });

  return server;
}

/**
 * Client that logs frame timing
 */
async function testEndpoint(path) {
  const startTime = Date.now();
  const log = (msg) => console.log(`[${Date.now() - startTime}ms] ${msg}`);

  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT}`);

    // Track frame events
    client.on('frameError', (type, code, id) => {
      log(`CLIENT FRAME ERROR: type=${FRAME_TYPES[type]}, code=${code}, stream=${id}`);
    });

    const req = client.request({
      ':method': 'POST',
      ':path': path,
      'content-type': 'application/json',
    });

    let responseData = '';
    let headersTime = null;
    let dataTime = null;

    req.on('response', (headers) => {
      headersTime = Date.now() - startTime;
      log(`CLIENT: HEADERS received - status ${headers[':status']}`);
    });

    req.on('data', (chunk) => {
      if (!dataTime) dataTime = Date.now() - startTime;
      responseData += chunk.toString();
      log(`CLIENT: DATA received - ${chunk.length} bytes`);
    });

    req.on('end', () => {
      const endTime = Date.now() - startTime;
      log(`CLIENT: Stream ended`);
      client.close();
      resolve({
        path,
        headersTime,
        dataTime,
        endTime,
        bodyLength: responseData.length,
      });
    });

    req.on('error', (err) => {
      log(`CLIENT ERROR: ${err.message}`);
      client.close();
      resolve({ path, error: err.message });
    });

    // Send request and close immediately
    req.write('{}');
    log(`CLIENT: Sending END_STREAM`);
    req.end();
  });
}

/**
 * Now test with Fastify to show the difference
 */
async function testWithFastify() {
  const Fastify = (await import('fastify')).default;

  const fastify = Fastify({
    http2: true,
    logger: false,
  });

  const startTime = Date.now();
  const log = (msg) => console.log(`[${Date.now() - startTime}ms] ${msg}`);

  // Endpoint using res.send(stream) - THE PROBLEMATIC PATTERN
  fastify.post('/fastify-send-stream', async (req, res) => {
    log('FASTIFY: Request received');

    const stream = new Readable({
      async read() {
        if (this._started) return;
        this._started = true;
        log('FASTIFY: Stream read() called, waiting 200ms...');
        await new Promise(r => setTimeout(r, 200));
        log('FASTIFY: Stream producing data NOW');
        this.push('{"result":"fastify send stream"}\n');
        this.push(null);
      }
    });

    res.header('content-type', 'application/json');
    res.status(200);

    // THIS IS THE BUG: headers are NOT sent until stream produces data
    const result = res.send(stream);
    log(`FASTIFY: After res.send() - headersSent: ${res.raw.headersSent}`);

    return result;
  });

  // Endpoint using res.raw.writeHead() - THE WORKING PATTERN
  fastify.post('/fastify-raw-writehead', async (req, res) => {
    log('FASTIFY: Request received');

    const stream = new Readable({
      async read() {
        if (this._started) return;
        this._started = true;
        log('FASTIFY: Stream read() called, waiting 200ms...');
        await new Promise(r => setTimeout(r, 200));
        log('FASTIFY: Stream producing data NOW');
        this.push('{"result":"fastify raw writehead"}\n');
        this.push(null);
      }
    });

    // THIS WORKS: headers are sent immediately
    res.raw.writeHead(200, { 'content-type': 'application/json' });
    log(`FASTIFY: After writeHead() - headersSent: ${res.raw.headersSent}`);

    for await (const chunk of stream) {
      res.raw.write(chunk);
    }
    res.raw.end();
  });

  await fastify.listen({ port: PORT + 1 });
  return fastify;
}

async function testFastifyEndpoint(path) {
  const startTime = Date.now();
  const log = (msg) => console.log(`[${Date.now() - startTime}ms] ${msg}`);

  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT + 1}`);

    const req = client.request({
      ':method': 'POST',
      ':path': path,
      'content-type': 'application/json',
    });

    let responseData = '';
    let headersTime = null;

    req.on('response', (headers) => {
      headersTime = Date.now() - startTime;
      log(`CLIENT: HEADERS received at ${headersTime}ms`);
    });

    req.on('data', (chunk) => {
      responseData += chunk.toString();
      log(`CLIENT: DATA received - ${chunk.length} bytes`);
    });

    req.on('end', () => {
      client.close();
      resolve({
        path,
        headersTime,
        bodyLength: responseData.length,
      });
    });

    req.write('{}');
    log(`CLIENT: END_STREAM sent`);
    req.end();
  });
}

async function main() {
  console.log('='.repeat(70));
  console.log('HTTP/2 Frame Timing Analysis');
  console.log('='.repeat(70));
  console.log('');
  console.log('This demonstrates when HEADERS frames are sent relative to');
  console.log('client END_STREAM and server data availability.');
  console.log('');

  // Part 1: Raw HTTP/2 server (baseline behavior)
  console.log('-'.repeat(70));
  console.log('PART 1: Raw HTTP/2 Server (baseline)');
  console.log('-'.repeat(70));

  const rawServer = createRawServer();
  await new Promise(r => rawServer.listen(PORT, r));
  console.log(`Raw server on port ${PORT}\n`);

  console.log('\nTest 1: /immediate (headers sent before data ready)');
  const immediate = await testEndpoint('/immediate');
  console.log(`  Result: HEADERS at ${immediate.headersTime}ms, DATA at ${immediate.dataTime}ms\n`);

  console.log('\nTest 2: /delayed-headers (headers delayed until data ready)');
  const delayed = await testEndpoint('/delayed-headers');
  console.log(`  Result: HEADERS at ${delayed.headersTime}ms, DATA at ${delayed.dataTime}ms\n`);

  console.log('\nTest 3: /stream-delayed (stream with delayed data)');
  const streamDelayed = await testEndpoint('/stream-delayed');
  console.log(`  Result: HEADERS at ${streamDelayed.headersTime}ms, DATA at ${streamDelayed.dataTime}ms\n`);

  rawServer.close();

  // Part 2: Fastify server
  console.log('-'.repeat(70));
  console.log('PART 2: Fastify HTTP/2 Server');
  console.log('-'.repeat(70));

  const fastify = await testWithFastify();
  console.log(`Fastify server on port ${PORT + 1}\n`);

  console.log('\nTest 4: /fastify-send-stream (res.send with stream) - PROBLEMATIC');
  const fastifySend = await testFastifyEndpoint('/fastify-send-stream');
  console.log(`  Result: HEADERS at ${fastifySend.headersTime}ms\n`);

  console.log('\nTest 5: /fastify-raw-writehead (res.raw.writeHead) - WORKING');
  const fastifyRaw = await testFastifyEndpoint('/fastify-raw-writehead');
  console.log(`  Result: HEADERS at ${fastifyRaw.headersTime}ms\n`);

  await fastify.close();

  // Summary
  console.log('='.repeat(70));
  console.log('SUMMARY');
  console.log('='.repeat(70));
  console.log('');
  console.log('Timing comparison (when HEADERS frame is sent):');
  console.log('');
  console.log(`  Raw /immediate:              ${immediate.headersTime}ms (before data)`);
  console.log(`  Raw /delayed-headers:        ${delayed.headersTime}ms (with data)`);
  console.log(`  Raw /stream-delayed:         ${streamDelayed.headersTime}ms (before stream data)`);
  console.log('');
  console.log(`  Fastify res.send(stream):    ${fastifySend.headersTime}ms`);
  console.log(`  Fastify res.raw.writeHead(): ${fastifyRaw.headersTime}ms`);
  console.log('');

  if (fastifySend.headersTime > fastifyRaw.headersTime + 50) {
    console.log('*** CONFIRMED: res.send(stream) delays HEADERS significantly ***');
    console.log('');
    console.log('The ~200ms difference shows that with res.send(stream), HEADERS');
    console.log('are not sent until the stream produces data.');
    console.log('');
    console.log('With res.raw.writeHead(), HEADERS are sent immediately.');
  }

  console.log('');
  console.log('This timing difference causes issues with HTTP/2 bidirectional');
  console.log('streaming clients (like httpx) that may close the request');
  console.log('before HEADERS arrive.');
  console.log('');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
