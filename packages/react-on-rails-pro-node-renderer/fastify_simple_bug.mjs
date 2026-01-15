#!/usr/bin/env node
/**
 * Simplest reproduction of Fastify HTTP/2 streaming bug
 */

import Fastify from 'fastify';
import http2 from 'node:http2';
import { PassThrough } from 'node:stream';

const PORT = 3464;

const fastify = Fastify({ http2: true });

// THE BUG: void + res.send(stream)
fastify.post('/bug', async (req, res) => {
  console.log('[SERVER] /bug handler start');
  const stream = new PassThrough();

  console.log('[SERVER] /bug sending response');
  // Fire-and-forget response (like node-renderer does)
  await (async () => {
    res.send(stream);
    await new Promise((resolve) => {
      setTimeout(() => {
        console.log('[SERVER] /bug writing to stream');
        stream.write('{"data":"hello"}\n');
        stream.end();
        console.log('[SERVER] /bug handler end');
        resolve();
      }, 50);
    });
  })();

  console.log('[SERVER] /bug handler end');
  // Handler returns immediately - Fastify closes response before data is written
});

// THE FIX: await + res.raw.writeHead()
fastify.post('/fix', async (req, res) => {
  const stream = new PassThrough();

  res.raw.writeHead(200, { 'content-type': 'application/json' });

  setTimeout(() => {
    stream.write('{"data":"hello"}\n');
    stream.end();
  }, 50);

  for await (const chunk of stream) {
    res.raw.write(chunk);
  }
  res.raw.end();
});

async function test(path) {
  return new Promise((resolve) => {
    const client = http2.connect(`http://localhost:${PORT}`);
    const req = client.request({ ':method': 'POST', ':path': path });

    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
    });
    req.on('end', () => {
      client.close();
      resolve(data);
    });

    req.end();
  });
}

await fastify.listen({ port: PORT });

console.log('/bug result:', JSON.stringify(await test('/bug')) || '(EMPTY)');
console.log('/fix result:', JSON.stringify(await test('/fix')) || '(EMPTY)');

await fastify.close();
