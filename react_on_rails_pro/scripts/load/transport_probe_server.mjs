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

  const readValue = (index, flag) => {
    const value = args.at(index + 1);
    if (value === undefined || value.startsWith('--')) {
      throw new Error(`${flag} requires a value`);
    }
    return value;
  };
  const readPositiveInteger = (index, flag) => {
    const value = readValue(index, flag);
    if (!/^[1-9]\d*$/.test(value)) {
      throw new Error(`${flag} must be a positive integer`);
    }
    return Number(value);
  };

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === '--scenarios') {
      options.scenarios = readValue(index, arg)
        .split(',')
        .map((scenario) => scenario.trim())
        .filter(Boolean);
      index += 1;
    } else if (arg === '--socket-path') {
      options.socketPath = readValue(index, arg);
      index += 1;
    } else if (arg === '--body-bytes') {
      options.bodyBytes = readPositiveInteger(index, arg);
      index += 1;
    } else if (arg === '--stream-bytes') {
      options.streamBytes = readPositiveInteger(index, arg);
      index += 1;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (options.scenarios.length === 0) {
    throw new Error('--scenarios must not be empty');
  }
  const unknownScenarios = options.scenarios.filter((scenario) => !VALID_SCENARIOS.has(scenario));
  if (unknownScenarios.length > 0) {
    throw new Error(`Unknown scenario(s): ${unknownScenarios.join(', ')}`);
  }
  if (options.scenarios.includes('native_uds') && !options.socketPath) {
    throw new Error('--socket-path is required when native_uds is in --scenarios');
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
  // Keep the stream open when body-limit overflow throws so writeReadError can
  // still send the 413 JSON response and then close the stream intentionally.
  for await (const chunk of stream.iterator({ destroyOnReturn: false })) {
    bytes += chunk.length;
    // The configured limit is inclusive: exactly maxBytes is accepted, and the
    // first byte beyond maxBytes returns 413.
    if (bytes > maxBytes) {
      const error = new Error(`request body exceeded --body-bytes limit (${maxBytes})`);
      error.statusCode = 413;
      throw error;
    }
  }
  return bytes;
};

const streamChunks = (bytesTotal) => {
  const chunks = [];
  const chunkSize = 4096;
  for (let remaining = bytesTotal; remaining > 0; remaining -= chunkSize) {
    chunks.push(Buffer.alloc(Math.min(chunkSize, remaining), 'x'));
  }
  return Readable.from(chunks);
};

const writeJson = (stream, status, payload, onFinish) => {
  if (stream.closed || stream.destroyed || stream.session?.closed || stream.session?.destroyed) {
    return false;
  }

  const body = Buffer.from(JSON.stringify(payload));
  try {
    stream.respond({
      ':status': status,
      'content-type': 'application/json',
      'content-length': body.length,
    });
    stream.end(body, onFinish);
    return true;
  } catch (error) {
    if (error.code !== 'ERR_HTTP2_INVALID_STREAM') {
      throw error;
    }
    return false;
  }
};

const closeStream = (stream) => {
  if (stream.closed || stream.destroyed) {
    return;
  }

  try {
    stream.close(http2.constants.NGHTTP2_CANCEL);
  } catch (error) {
    if (error.code !== 'ERR_HTTP2_INVALID_STREAM') {
      throw error;
    }
  }
};

const writeReadError = (stream, error) => {
  const onFinish = error.statusCode === 413 ? () => closeStream(stream) : undefined;
  writeJson(stream, error.statusCode || 500, { ok: false, error: error.message }, onFinish);
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
      .then((receivedBytes) => writeJson(stream, 200, { ok: true, receivedBytes }))
      .catch((error) => writeReadError(stream, error));
    return;
  }

  if (path === '/probe/stream') {
    readRequestBody(stream, bodyBytes)
      .then(() => {
        stream.respond({ ':status': 200, 'content-type': 'application/octet-stream' });
        const readable = streamChunks(streamBytes);
        stream.on('error', () => readable.destroy());
        readable.pipe(stream);
      })
      .catch((error) => writeReadError(stream, error));
    return;
  }

  writeJson(stream, 404, { ok: false, error: 'not found' });
};

const assertSocketPathAvailable = async (socketPath) => {
  try {
    await fs.lstat(socketPath);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return;
    }
    throw error;
  }
  throw new Error(`socket path already exists: ${socketPath}`);
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
  const { default: fastify } = await import('fastify').catch((error) => {
    if (error.code === 'ERR_MODULE_NOT_FOUND') {
      throw new Error('fastify package not found -- run: pnpm install (from the repository root)');
    }
    throw error;
  });
  const app = fastify({ http2: true, logger: false, bodyLimit: bodyBytes });
  app.addContentTypeParser('application/octet-stream', { parseAs: 'buffer' }, (_request, body, done) => {
    done(null, body);
  });

  app.get('/info', async () => ({ ok: true, server: 'fastify' }));
  app.post('/probe/unary', async (request) => ({
    ok: true,
    receivedBytes: Buffer.isBuffer(request.body) ? request.body.length : 0,
  }));
  // Fastify applies bodyLimit before this handler; the stream probe discards the request body.
  app.post('/probe/stream', async (_request, reply) => {
    reply.type('application/octet-stream');
    return reply.send(streamChunks(streamBytes));
  });

  await app.listen({ host, port });
  return app;
};

const listeningPort = (address, serverName) => {
  if (!address || typeof address === 'string' || typeof address.port !== 'number') {
    throw new Error(`${serverName} did not report a numeric listening port`);
  }

  return address.port;
};

const closeServer = async ({ server, type }) => {
  if (typeof server?.close !== 'function') {
    return;
  }

  if (type === 'native') {
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

  const cleanupStartedServers = async () => {
    await Promise.allSettled(servers.map(closeServer));
    await cleanupSocket();
  };

  try {
    if (scenarios.includes('fastify_tcp')) {
      const fastifyServer = await listenFastify({ bodyBytes, host, port: 0, streamBytes });
      servers.push({ server: fastifyServer, type: 'fastify' });
      const port = listeningPort(fastifyServer.addresses()[0], 'fastify_tcp');
      endpoints.push({
        name: 'fastify_tcp',
        kind: 'tcp',
        origin: `http://${host}:${port}`,
      });
    }

    if (scenarios.includes('native_tcp')) {
      const nativeTcpServer = await listenNative({ bodyBytes, host, port: 0, streamBytes });
      servers.push({ server: nativeTcpServer, type: 'native' });
      endpoints.push({
        name: 'native_tcp',
        kind: 'tcp',
        origin: `http://${host}:${nativeTcpServer.address().port}`,
      });
    }

    if (scenarios.includes('native_uds')) {
      const nativeUdsServer = await listenNative({ bodyBytes, socketPath, streamBytes });
      nativeUdsSocketCreated = true;
      servers.push({ server: nativeUdsServer, type: 'native' });
      endpoints.push({
        name: 'native_uds',
        kind: 'uds',
        socketPath,
        scheme: 'http',
        authority: 'localhost',
      });
    }
  } catch (error) {
    await cleanupStartedServers();
    throw error;
  }

  const ready = {
    nodeVersion: process.version,
    platform: `${os.platform()} ${os.release()} ${os.arch()}`,
    endpoints,
  };

  process.stdout.write(`${JSON.stringify(ready)}\n`);

  const shutdown = async () => {
    await cleanupStartedServers();
    process.exit(0);
  };

  let shuttingDown = false;
  const guardedShutdown = () => {
    if (shuttingDown) {
      return;
    }
    shuttingDown = true;
    void shutdown().catch((error) => {
      process.stderr.write(`transport_probe_server shutdown: ${error.stack || error.message}\n`);
      process.exit(1);
    });
  };

  process.once('SIGTERM', guardedShutdown);
  process.once('SIGINT', guardedShutdown);
};

main().catch((error) => {
  process.stderr.write(`transport_probe_server: ${error.stack || error.message}\n`);
  process.exit(1);
});
