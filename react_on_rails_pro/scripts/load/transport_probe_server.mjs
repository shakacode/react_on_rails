#!/usr/bin/env node

import http2 from 'node:http2';
import fs from 'node:fs/promises';
import os from 'node:os';
import { Readable } from 'node:stream';

const VALID_SCENARIOS = new Set(['fastify_tcp', 'native_tcp', 'native_uds']);

const parseArgs = () => {
  const args = process.argv.slice(2);
  const options = {
    scenarios: ['fastify_tcp', 'native_tcp', 'native_uds'],
    bodyBytes: 4096,
    socketPath: '',
    streamBytes: 16_384,
  };

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === '--scenarios') {
      options.scenarios = args
        .at(index + 1)
        .split(',')
        .map((scenario) => scenario.trim())
        .filter(Boolean);
      index += 1;
    } else if (arg === '--socket-path') {
      options.socketPath = args.at(index + 1);
      index += 1;
    } else if (arg === '--body-bytes') {
      options.bodyBytes = Number(args.at(index + 1));
      index += 1;
    } else if (arg === '--stream-bytes') {
      options.streamBytes = Number(args.at(index + 1));
      index += 1;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!options.socketPath) {
    throw new Error('--socket-path is required');
  }
  if (options.scenarios.length === 0) {
    throw new Error('--scenarios must not be empty');
  }
  const unknownScenarios = options.scenarios.filter((scenario) => !VALID_SCENARIOS.has(scenario));
  if (unknownScenarios.length > 0) {
    throw new Error(`Unknown scenario(s): ${unknownScenarios.join(', ')}`);
  }
  if (!Number.isInteger(options.bodyBytes) || options.bodyBytes < 1) {
    throw new Error('--body-bytes must be a positive integer');
  }
  if (!Number.isInteger(options.streamBytes) || options.streamBytes < 1) {
    throw new Error('--stream-bytes must be a positive integer');
  }

  return options;
};

const readRequestBody = async (stream, maxBytes) => {
  let bytes = 0;
  const chunks = [];
  let exceededLimit = false;
  for await (const chunk of stream) {
    bytes += chunk.length;
    if (bytes > maxBytes) {
      exceededLimit = true;
    } else {
      chunks.push(chunk);
    }
  }
  if (exceededLimit) {
    const error = new Error(`request body exceeded --body-bytes limit (${maxBytes})`);
    error.statusCode = 413;
    throw error;
  }
  return Buffer.concat(chunks, bytes);
};

const streamChunks = (bytesTotal) => {
  const chunks = [];
  const chunkSize = 4096;
  for (let remaining = bytesTotal; remaining > 0; remaining -= chunkSize) {
    chunks.push(Buffer.alloc(Math.min(chunkSize, remaining), 'x'));
  }
  return Readable.from(chunks);
};

const writeJson = (stream, status, payload) => {
  const body = Buffer.from(JSON.stringify(payload));
  stream.respond({
    ':status': status,
    'content-type': 'application/json',
    'content-length': body.length,
  });
  stream.end(body);
};

const handleNativeStream = (stream, headers, { bodyBytes, streamBytes }) => {
  const path = headers[':path'];
  const method = headers[':method'];

  if (method === 'GET' && path === '/info') {
    writeJson(stream, 200, { ok: true, server: 'native' });
    return;
  }

  if (method !== 'POST') {
    writeJson(stream, 405, { ok: false, error: 'method not allowed' });
    return;
  }

  if (path === '/probe/unary') {
    readRequestBody(stream, bodyBytes)
      .then((body) => writeJson(stream, 200, { ok: true, receivedBytes: body.length }))
      .catch((error) => writeJson(stream, error.statusCode || 500, { ok: false, error: error.message }));
    return;
  }

  if (path === '/probe/stream') {
    readRequestBody(stream, bodyBytes)
      .then(() => {
        stream.respond({ ':status': 200, 'content-type': 'application/octet-stream' });
        streamChunks(streamBytes).pipe(stream);
      })
      .catch((error) => writeJson(stream, error.statusCode || 500, { ok: false, error: error.message }));
    return;
  }

  writeJson(stream, 404, { ok: false, error: 'not found' });
};

const assertSocketPathAvailable = async (socketPath) => {
  try {
    await fs.lstat(socketPath);
    throw new Error(`socket path already exists: ${socketPath}`);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return;
    }
    throw error;
  }
};

const listenNative = async ({ bodyBytes, host, port, socketPath, streamBytes }) => {
  if (socketPath) {
    await assertSocketPathAvailable(socketPath);
  }

  const server = http2.createServer();
  server.on('stream', (stream, headers) => handleNativeStream(stream, headers, { bodyBytes, streamBytes }));

  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(socketPath || { host, port }, resolve);
  });

  return server;
};

const listenFastify = async ({ bodyBytes, host, port, streamBytes }) => {
  const { default: fastify } = await import('fastify');
  const app = fastify({ http2: true, logger: false, bodyLimit: bodyBytes });
  app.addContentTypeParser('application/octet-stream', { parseAs: 'buffer' }, (_request, body, done) => {
    done(null, body);
  });

  app.get('/info', async () => ({ ok: true, server: 'fastify' }));
  app.post('/probe/unary', async (request) => ({
    ok: true,
    receivedBytes: Buffer.isBuffer(request.body) ? request.body.length : 0,
  }));
  app.post('/probe/stream', async (_request, reply) => {
    reply.type('application/octet-stream');
    return reply.send(streamChunks(streamBytes));
  });

  await app.listen({ host, port });
  return app;
};

const closeServer = async (server) => {
  if (typeof server.close !== 'function') {
    return;
  }

  if (typeof server.address === 'function') {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
    return;
  }

  await server.close();
};

const main = async () => {
  const { bodyBytes, scenarios, socketPath, streamBytes } = parseArgs();
  const host = '127.0.0.1';
  const servers = [];
  const endpoints = [];
  let nativeUdsSocketCreated = false;

  if (scenarios.includes('fastify_tcp')) {
    const fastifyServer = await listenFastify({ bodyBytes, host, port: 0, streamBytes });
    servers.push(fastifyServer);
    endpoints.push({
      name: 'fastify_tcp',
      kind: 'tcp',
      origin: `http://${host}:${fastifyServer.server.address().port}`,
    });
  }

  if (scenarios.includes('native_tcp')) {
    const nativeTcpServer = await listenNative({ bodyBytes, host, port: 0, streamBytes });
    servers.push(nativeTcpServer);
    endpoints.push({
      name: 'native_tcp',
      kind: 'tcp',
      origin: `http://${host}:${nativeTcpServer.address().port}`,
    });
  }

  if (scenarios.includes('native_uds')) {
    const nativeUdsServer = await listenNative({ bodyBytes, socketPath, streamBytes });
    nativeUdsSocketCreated = true;
    servers.push(nativeUdsServer);
    endpoints.push({
      name: 'native_uds',
      kind: 'uds',
      socketPath,
      scheme: 'http',
      authority: 'localhost',
    });
  }

  const ready = {
    nodeVersion: process.version,
    platform: `${os.platform()} ${os.release()} ${os.arch()}`,
    endpoints,
  };

  process.stdout.write(`${JSON.stringify(ready)}\n`);

  const cleanupSocket = async () => {
    if (!nativeUdsSocketCreated) {
      return;
    }

    try {
      const stat = await fs.lstat(socketPath);
      if (stat.isSocket()) {
        await fs.rm(socketPath, { force: true });
      }
    } catch (error) {
      if (error.code !== 'ENOENT') {
        throw error;
      }
    }
  };

  const shutdown = async () => {
    await Promise.allSettled(servers.map(closeServer));
    await cleanupSocket();
    process.exit(0);
  };

  process.once('SIGTERM', shutdown);
  process.once('SIGINT', shutdown);
};

main().catch((error) => {
  process.stderr.write(`transport_probe_server: ${error.stack || error.message}\n`);
  process.exit(1);
});
