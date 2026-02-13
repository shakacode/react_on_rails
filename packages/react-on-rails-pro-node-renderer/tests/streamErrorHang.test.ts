/**
 * E2E test reproducing issue #2402: streaming HTTP response hangs forever
 * when the rendering stream errors.
 *
 * This test follows the same pattern as htmlStreaming.test.js (full HTTP/2
 * round-trip through Fastify), but uses a minimal bundle that returns a
 * Readable stream which errors — no React components needed.
 *
 * @see https://github.com/shakacode/react_on_rails/issues/2402
 */

import fs from 'fs';
import path from 'path';
import http2 from 'http2';
import FormData from 'form-data';
import buildApp from '../src/worker';
import { createTestConfig } from './testingNodeRendererConfigs';
import * as errorReporter from '../src/shared/errorReporter';
import packageJson from '../src/shared/packageJson';

const BUNDLE_TIMESTAMP = '55555-stream-error';

const { config } = createTestConfig('streamErrorHang');
const app = buildApp(config);

beforeAll(async () => {
  await app.ready();
  await app.listen({ port: 0 });
});

afterAll(async () => {
  await app.close();
});

jest.spyOn(errorReporter, 'message').mockImplementation(jest.fn());

// ---------------------------------------------------------------------------
// Helpers (kept minimal — only the parts that differ from httpRequestUtils)
// ---------------------------------------------------------------------------

/** Builds a multipart form with our stream-test bundle and a custom rendering request. */
const createForm = (renderingRequest: string) => {
  const form = new FormData();
  // Same auth/version fields as httpRequestUtils.createForm
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

/**
 * Same request flow as htmlStreaming.test.js's makeRequest, but adds a
 * timeout so the test can detect a hung response instead of hanging itself.
 */
const makeRequest = (renderingRequest: string, timeoutMs = 3000) =>
  new Promise<{ status: number | undefined; chunks: string[]; timedOut: boolean }>((resolve) => {
    const form = createForm(renderingRequest);
    const { port } = app.server.address() as { port: number };
    const client = http2.connect(`http://localhost:${port}`);
    const request = client.request({
      ':method': 'POST',
      ':path': `/bundles/${BUNDLE_TIMESTAMP}/render/stream-error-test`,
      'content-type': `multipart/form-data; boundary=${form.getBoundary()}`,
    });
    request.setEncoding('utf8');

    const chunks: string[] = [];
    let status: number | undefined;
    let settled = false;

    request.on('response', (headers) => {
      status = headers[':status'];
    });

    // Same newline-delimited chunk parsing as htmlStreaming.test.js
    request.on('data', (data: string) => {
      const decoded = data
        .split('\n')
        .map((c) => c.trim())
        .filter((c) => c.length > 0);
      chunks.push(...decoded);
    });

    form.pipe(request);
    form.on('end', () => request.end());

    const finish = (timedOut: boolean) => {
      if (settled) return;
      settled = true;
      client.destroy();
      resolve({ status, chunks, timedOut });
    };

    const timeout = setTimeout(() => finish(true), timeoutMs);

    request.on('end', () => {
      clearTimeout(timeout);
      finish(false);
    });
    request.on('error', () => {
      clearTimeout(timeout);
      finish(false);
    });
  });

// ---------------------------------------------------------------------------
// Rendering requests — plain JS that returns a Readable (no React needed).
// The bundle exposes `Readable` globally via `global.Readable = require('stream').Readable`.
// ---------------------------------------------------------------------------

const RENDERING_REQUEST = {
  /** Pushes one chunk, then errors. Stream should close but doesn't (the bug). */
  errorMidStream: `(function() {
    var stream = new Readable({ read() {} });
    setTimeout(function() {
      stream.push('{"html":"<div>partial</div>","consoleReplayScript":"","hasErrors":false,"isShellReady":true}\\n');
    }, 10);
    setTimeout(function() {
      stream.destroy(new Error('mid-stream rendering error'));
    }, 200);
    return stream;
  })()`,

  /** Errors immediately, before any data is sent. */
  errorBeforeData: `(function() {
    var stream = new Readable({ read() {} });
    setTimeout(function() {
      stream.destroy(new Error('immediate rendering error'));
    }, 10);
    return stream;
  })()`,

  /** Control: pushes data and ends normally. */
  happyPath: `(function() {
    var stream = new Readable({ read() {} });
    setTimeout(function() {
      stream.push('{"html":"<div>ok</div>","consoleReplayScript":"","hasErrors":false,"isShellReady":true}\\n');
      stream.push(null);
    }, 10);
    return stream;
  })()`,
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('streaming error hang - E2E (issue #2402)', () => {
  it('HTTP response completes when rendering stream errors mid-stream', async () => {
    const { status, chunks, timedOut } = await makeRequest(RENDERING_REQUEST.errorMidStream);

    // The partial chunk IS received before the error
    expect(status).toBe(200);
    expect(chunks.length).toBeGreaterThanOrEqual(1);
    expect(chunks[0]).toContain('partial');

    // The response completes instead of hanging
    expect(timedOut).toBe(false);

    // The error IS reported to errorReporter (handleStreamError's onError fires)
    expect(errorReporter.message).toHaveBeenCalledWith(
      expect.stringContaining('mid-stream rendering error'),
    );
  }, 10000);

  it('HTTP response completes when rendering stream errors before any data', async () => {
    const { timedOut } = await makeRequest(RENDERING_REQUEST.errorBeforeData);

    // The response completes instead of hanging
    expect(timedOut).toBe(false);

    expect(errorReporter.message).toHaveBeenCalledWith(
      expect.stringContaining('immediate rendering error'),
    );
  }, 10000);

  it('control: HTTP response completes normally when stream ends properly', async () => {
    const { status, chunks, timedOut } = await makeRequest(RENDERING_REQUEST.happyPath);

    expect(timedOut).toBe(false);
    expect(status).toBe(200);
    expect(chunks).toHaveLength(1);
    expect(chunks[0]).toContain('ok');
  }, 10000);
});
