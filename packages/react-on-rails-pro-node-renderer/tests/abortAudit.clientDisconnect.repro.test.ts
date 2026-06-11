/*
 * THROWAWAY REPRO for issue #3885 abort-path audit (report-only; not meant to be merged).
 *
 * Question under test: when an HTTP/2 client (i.e. the Rails gem) cancels a
 * streaming render request mid-stream, what does the node renderer actually do
 * with the in-flight render work?
 *
 * Observation strategy: the renderingRequest creates a Readable inside the VM
 * that keeps producing chunks on a timer and records every lifecycle event
 * (push, pause, resume, unpipe, error, close/destroy) into a VM-global log.
 * Because VM contexts are cached per bundle, a SECOND request to the same
 * bundle can read that log back out after the first client has disconnected.
 *
 * If the renderer propagated cancellation, the VM-side source stream would be
 * destroyed (close/destroy entries) and production would stop. If it doesn't,
 * pushes continue after the client cancel — i.e. the render work leaks.
 */

import fs from 'fs';
import path from 'path';
import http2 from 'http2';
import FormData from 'form-data';
import buildApp from '../src/worker';
import { createTestConfig } from './testingNodeRendererConfigs';
import packageJson from '../src/shared/packageJson';

const BUNDLE_TIMESTAMP = '66666-abort-audit';

const { config } = createTestConfig('abortAuditClientDisconnect');
const app = buildApp(config);

// Record whether Fastify-level abort hooks fire at all.
const hookEvents: { t: number; hook: string }[] = [];
app.addHook('onRequestAbort', (_req, done) => {
  hookEvents.push({ t: Date.now(), hook: 'onRequestAbort' });
  done();
});
app.addHook('onResponse', (_req, _reply, done) => {
  hookEvents.push({ t: Date.now(), hook: 'onResponse' });
  done();
});

beforeAll(async () => {
  await app.ready();
  await app.listen({ port: 0 });
});

afterAll(async () => {
  await app.close();
});

const createForm = (renderingRequest: string) => {
  const form = new FormData();
  form.append('gemVersion', packageJson.version);
  form.append('protocolVersion', packageJson.protocolVersion);
  form.append('password', 'myPassword1');
  form.append('renderingRequest', renderingRequest);

  const bundlePath = path.join(__dirname, 'fixtures', 'stream-test-bundle.js');
  form.append(`bundle_${BUNDLE_TIMESTAMP}`, fs.createReadStream(bundlePath), {
    contentType: 'text/javascript',
    filename: 'stream-test-bundle.js',
  });

  return form;
};

/** Length-prefixed chunk payload as expected by the streaming protocol. */
function buildLengthPrefixedChunkJs(): string {
  const meta = JSON.stringify({
    consoleReplayScript: '',
    hasErrors: false,
    isShellReady: true,
    payloadType: 'string',
  });
  // Build the chunk inside the VM so each chunk carries its tick number.
  return `
    function buildChunk(i) {
      var html = '<div>tick ' + i + '</div>';
      var len = Buffer.byteLength(html).toString(16);
      while (len.length < 8) { len = '0' + len; }
      return ${JSON.stringify(meta)} + '\\t' + len + '\\n' + html;
    }
  `;
}

/**
 * Streaming rendering request: produces a chunk every 150ms for up to 4s,
 * logging everything into globalThis.__abortAuditLog.
 */
const STREAMING_RENDERING_REQUEST = `(function() {
  globalThis.__abortAuditLog = [];
  var log = function(msg) { globalThis.__abortAuditLog.push({ t: Date.now(), msg: msg }); };
  ${buildLengthPrefixedChunkJs()}

  var stream = new Readable({ read: function() {} });
  ['pause', 'resume', 'unpipe', 'error', 'close', 'end'].forEach(function(eventName) {
    stream.on(eventName, function() { log('source stream event: ' + eventName); });
  });

  var i = 0;
  var interval = setInterval(function() {
    i += 1;
    if (stream.destroyed) {
      log('source stream destroyed; stopping producer at tick ' + i);
      clearInterval(interval);
      return;
    }
    log('pushed tick ' + i);
    stream.push(buildChunk(i));
    if (i >= 25) {
      log('producer finished naturally at tick ' + i);
      clearInterval(interval);
      stream.push(null);
    }
  }, 150);

  return stream;
})()`;

/** Second request: dump the log accumulated in the VM context. */
const READ_LOG_RENDERING_REQUEST = `(function() {
  return JSON.stringify(globalThis.__abortAuditLog || []);
})()`;

type LogEntry = { t: number; msg: string };

const postRendering = (
  renderingRequest: string,
  options: { cancelAfterFirstChunk?: boolean } = {},
): Promise<{ status: number | undefined; body: string; cancelledAt: number }> =>
  new Promise((resolve, reject) => {
    const form = createForm(renderingRequest);
    const { port } = app.server.address() as { port: number };
    const client = http2.connect(`http://localhost:${port}`);
    const request = client.request({
      ':method': 'POST',
      ':path': `/bundles/${BUNDLE_TIMESTAMP}/render/abort-audit`,
      'content-type': `multipart/form-data; boundary=${form.getBoundary()}`,
    });
    request.setEncoding('utf8');

    let status: number | undefined;
    let body = '';
    let cancelledAt = 0;
    let settled = false;

    const finish = () => {
      if (settled) return;
      settled = true;
      client.close();
      resolve({ status, body, cancelledAt });
    };

    request.on('response', (headers) => {
      status = headers[':status'];
    });

    request.on('data', (data: string) => {
      body += data;
      if (options.cancelAfterFirstChunk && !cancelledAt) {
        cancelledAt = Date.now();
        // Simulate the Rails client (or browser->Rails->renderer chain)
        // cancelling: send RST_STREAM with CANCEL and tear the session down.
        request.close(http2.constants.NGHTTP2_CANCEL);
        client.close();
        // Resolve shortly after; the stream is gone from the client side.
        setTimeout(finish, 50);
      }
    });

    form.pipe(request);
    form.on('end', () => request.end());

    request.on('end', finish);
    request.on('error', (err) => {
      // RST_STREAM from our own cancel surfaces as an error; that's expected.
      if (cancelledAt) {
        finish();
      } else {
        client.close();
        reject(err);
      }
    });
  });

const sleep = (ms: number) =>
  new Promise<void>((resolve) => {
    setTimeout(resolve, ms);
  });

describe('abort audit: HTTP/2 client cancels a streaming render mid-stream', () => {
  it('shows what the renderer does with in-flight stream work after client cancel', async () => {
    const { status, cancelledAt } = await postRendering(STREAMING_RENDERING_REQUEST, {
      cancelAfterFirstChunk: true,
    });
    expect(status).toBe(200);
    expect(cancelledAt).toBeGreaterThan(0);

    // Wait long enough for the producer to finish its 25 ticks if it leaked.
    await sleep(4500);

    const { status: logStatus, body: logBody } = await postRendering(READ_LOG_RENDERING_REQUEST);
    expect(logStatus).toBe(200);
    const vmLog = JSON.parse(logBody) as LogEntry[];
    expect(vmLog.length).toBeGreaterThan(0);

    const pushesAfterCancel = vmLog.filter((e) => e.t > cancelledAt && e.msg.startsWith('pushed tick'));
    const sourceDestroyed = vmLog.some(
      (e) => e.msg.includes('close') || e.msg.includes('destroyed; stopping producer'),
    );
    const finishedNaturally = vmLog.some((e) => e.msg.includes('producer finished naturally'));
    const abortHookFired = hookEvents.some((e) => e.hook === 'onRequestAbort');

    const base = vmLog[0]?.t ?? cancelledAt;
    process.stdout.write(
      ['--- abort audit (full-stack) timeline ---', `client cancelled at +${cancelledAt - base}ms`]
        .concat(vmLog.map((e) => `+${e.t - base}ms ${e.msg}`))
        .concat(hookEvents.map((e) => `+${e.t - base}ms fastify hook: ${e.hook}`))
        .concat([
          `pushes after client cancel: ${pushesAfterCancel.length}`,
          `VM source stream saw destroy/close: ${sourceDestroyed}`,
          `producer ran to natural completion: ${finishedNaturally}`,
          `fastify onRequestAbort fired: ${abortHookFired}`,
        ])
        .join('\n')
        .concat('\n'),
    );

    // Audit finding assertions (if these pass, the work LEAKS).
    expect(pushesAfterCancel.length).toBeGreaterThan(0);
    expect(finishedNaturally).toBe(true);
  }, 20000);
});
