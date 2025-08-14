import http from 'http';
import fs from 'fs';
import path from 'path';
import worker, { disableHttp2 } from '../src/worker';
import packageJson from '../src/shared/packageJson';
import * as incremental from '../src/worker/handleIncrementalRenderRequest';
import { createVmBundle, BUNDLE_TIMESTAMP } from './helper';
import type { ResponseResult } from '../src/shared/utils';

// Disable HTTP/2 for testing like other tests do
disableHttp2();

describe('incremental render NDJSON endpoint', () => {
  const TEST_NAME = 'incrementalRender';
  const BUNDLE_PATH = path.join(__dirname, 'tmp', TEST_NAME);
  if (!fs.existsSync(BUNDLE_PATH)) {
    fs.mkdirSync(BUNDLE_PATH, { recursive: true });
  }
  const app = worker({
    bundlePath: BUNDLE_PATH,
    password: 'myPassword1',
    // Keep HTTP logs quiet for tests
    logHttpLevel: 'silent' as const,
  });

  beforeAll(async () => {
    await app.ready();
    await app.listen({ port: 0 });
  });

  afterAll(async () => {
    await app.close();
  });

  test('calls handleIncrementalRenderRequest immediately after first chunk and processes each subsequent chunk immediately', async () => {
    // Create a bundle for this test
    await createVmBundle(TEST_NAME);

    const sinkAddCalls: unknown[] = [];
    const sinkEnd = jest.fn();
    const sinkAbort = jest.fn();

    const sink: incremental.IncrementalRenderSink = {
      add: (chunk) => {
        sinkAddCalls.push(chunk);
      },
      end: sinkEnd,
      abort: sinkAbort,
    };

    const mockResponse: ResponseResult = {
      status: 200,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      data: 'mock response',
    };

    const mockResult: incremental.IncrementalRenderResult = {
      response: mockResponse,
      sink,
    };

    const resultPromise = Promise.resolve(mockResult);
    const handleSpy = jest
      .spyOn(incremental, 'handleIncrementalRenderRequest')
      .mockImplementation(() => resultPromise);

    const addr = app.server.address();
    const host = typeof addr === 'object' && addr ? addr.address : '127.0.0.1';
    const port = typeof addr === 'object' && addr ? addr.port : 0;

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = http.request({
      hostname: host,
      port,
      path: `/bundles/${SERVER_BUNDLE_TIMESTAMP}/incremental-render/abc123`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-ndjson',
      },
    });
    req.setNoDelay(true);

    // Set up promise to handle the response
    const responsePromise = new Promise<void>((resolve, reject) => {
      req.on('response', (res) => {
        res.on('data', () => {
          // Consume response data to prevent hanging
        });
        res.on('end', () => {
          resolve();
        });
        res.on('error', (e) => {
          reject(e);
        });
      });
      req.on('error', (e) => {
        reject(e);
      });
    });

    // Write first object (headers, auth, and initial renderingRequest)
    const initialObj = {
      gemVersion: packageJson.version,
      protocolVersion: packageJson.protocolVersion,
      password: 'myPassword1',
      renderingRequest: 'ReactOnRails.dummy',
      dependencyBundleTimestamps: [SERVER_BUNDLE_TIMESTAMP],
    };
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait a brief moment for the server to process the first object
    await new Promise<void>((resolveTimeout) => {
      setTimeout(resolveTimeout, 50);
    });

    // Verify handleIncrementalRenderRequest was called immediately after first chunk
    expect(handleSpy).toHaveBeenCalledTimes(1);
    expect(sinkAddCalls).toHaveLength(0); // No subsequent chunks processed yet

    // Send subsequent props chunks one by one and verify immediate processing
    const chunksToSend = [{ a: 1 }, { b: 2 }, { c: 3 }];

    for (let i = 0; i < chunksToSend.length; i += 1) {
      const chunk = chunksToSend[i];
      const expectedCallsBeforeWrite = i;

      // Verify state before writing this chunk
      expect(sinkAddCalls).toHaveLength(expectedCallsBeforeWrite);

      // Write the chunk
      req.write(`${JSON.stringify(chunk)}\n`);

      // Wait a brief moment for processing
      // eslint-disable-next-line no-await-in-loop
      await new Promise<void>((resolveWait) => {
        setTimeout(resolveWait, 20);
      });

      // Verify the chunk was processed immediately
      expect(sinkAddCalls).toHaveLength(expectedCallsBeforeWrite + 1);
      expect(sinkAddCalls[expectedCallsBeforeWrite]).toEqual(chunk);
    }

    req.end();

    // Wait for the request to complete
    await responsePromise;

    // Wait for the sink.end to be called
    await new Promise<void>((resolve) => {
      setTimeout(resolve, 10);
    });

    // Final verification: all chunks were processed in the correct order
    expect(handleSpy).toHaveBeenCalledTimes(1);
    expect(sinkAddCalls).toEqual([{ a: 1 }, { b: 2 }, { c: 3 }]);

    // Verify stream lifecycle methods were called correctly
    expect(sinkEnd).toHaveBeenCalledTimes(1);
    expect(sinkAbort).not.toHaveBeenCalled();
  });

  test('returns 410 error when bundle is missing', async () => {
    const addr = app.server.address();
    const host = typeof addr === 'object' && addr ? addr.address : '127.0.0.1';
    const port = typeof addr === 'object' && addr ? addr.port : 0;

    const MISSING_BUNDLE_TIMESTAMP = 'non-existent-bundle-123';

    // Create the HTTP request with a non-existent bundle
    const req = http.request({
      hostname: host,
      port,
      path: `/bundles/${MISSING_BUNDLE_TIMESTAMP}/incremental-render/abc123`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-ndjson',
      },
    });
    req.setNoDelay(true);

    // Set up promise to capture the response
    const responsePromise = new Promise<{ statusCode: number; data: string }>((resolve, reject) => {
      req.on('response', (res) => {
        let data = '';
        res.on('data', (chunk: string) => {
          data += chunk;
        });
        res.on('end', () => {
          resolve({ statusCode: res.statusCode || 0, data });
        });
        res.on('error', (e) => {
          reject(e);
        });
      });
      req.on('error', (e) => {
        reject(e);
      });
    });

    // Write first object with auth data
    const initialObj = {
      gemVersion: packageJson.version,
      protocolVersion: packageJson.protocolVersion,
      password: 'myPassword1',
      renderingRequest: 'ReactOnRails.dummy',
      dependencyBundleTimestamps: [MISSING_BUNDLE_TIMESTAMP],
    };
    req.write(`${JSON.stringify(initialObj)}\n`);
    req.end();

    // Wait for the response
    const response = await responsePromise;

    // Verify that we get a 410 error
    expect(response.statusCode).toBe(410);
    expect(response.data).toContain('No bundle uploaded');
  });

  test('returns 400 error when first chunk contains malformed JSON', async () => {
    // Create a bundle for this test
    await createVmBundle(TEST_NAME);

    const addr = app.server.address();
    const host = typeof addr === 'object' && addr ? addr.address : '127.0.0.1';
    const port = typeof addr === 'object' && addr ? addr.port : 0;

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = http.request({
      hostname: host,
      port,
      path: `/bundles/${SERVER_BUNDLE_TIMESTAMP}/incremental-render/abc123`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-ndjson',
      },
    });
    req.setNoDelay(true);

    // Set up promise to capture the response
    const responsePromise = new Promise<{ statusCode: number; data: string }>((resolve, reject) => {
      req.on('response', (res) => {
        let data = '';
        res.on('data', (chunk: string) => {
          data += chunk;
        });
        res.on('end', () => {
          resolve({ statusCode: res.statusCode || 0, data });
        });
        res.on('error', (e) => {
          reject(e);
        });
      });
      req.on('error', (e) => {
        reject(e);
      });
    });

    // Write malformed JSON as first chunk (missing closing brace)
    const malformedJson = `{"gemVersion": "1.0.0", "protocolVersion": "2.0.0", "password": "myPassword1", "renderingRequest": "ReactOnRails.dummy", "dependencyBundleTimestamps": ["${SERVER_BUNDLE_TIMESTAMP}"]\n`;
    req.write(malformedJson);
    req.end();

    // Wait for the response
    const response = await responsePromise;

    // Verify that we get a 400 error due to malformed JSON
    expect(response.statusCode).toBe(400);
    expect(response.data).toContain('Invalid JSON chunk');
  });

  test('continues processing when update chunk contains malformed JSON', async () => {
    // Create a bundle for this test
    await createVmBundle(TEST_NAME);

    const sinkAddCalls: unknown[] = [];
    const sinkEnd = jest.fn();
    const sinkAbort = jest.fn();

    const sink: incremental.IncrementalRenderSink = {
      add: (chunk) => {
        sinkAddCalls.push(chunk);
      },
      end: sinkEnd,
      abort: sinkAbort,
    };

    const mockResponse: ResponseResult = {
      status: 200,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      data: 'mock response',
    };

    const mockResult: incremental.IncrementalRenderResult = {
      response: mockResponse,
      sink,
    };

    const resultPromise = Promise.resolve(mockResult);
    const handleSpy = jest
      .spyOn(incremental, 'handleIncrementalRenderRequest')
      .mockImplementation(() => resultPromise);

    const addr = app.server.address();
    const host = typeof addr === 'object' && addr ? addr.address : '127.0.0.1';
    const port = typeof addr === 'object' && addr ? addr.port : 0;

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = http.request({
      hostname: host,
      port,
      path: `/bundles/${SERVER_BUNDLE_TIMESTAMP}/incremental-render/abc123`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-ndjson',
      },
    });
    req.setNoDelay(true);

    // Set up promise to handle the response
    const responsePromise = new Promise<void>((resolve, reject) => {
      req.on('response', (res) => {
        res.on('data', () => {
          // Consume response data to prevent hanging
        });
        res.on('end', () => {
          resolve();
        });
        res.on('error', (e) => {
          reject(e);
        });
      });
      req.on('error', (e) => {
        reject(e);
      });
    });

    // Write first object (valid JSON)
    const initialObj = {
      gemVersion: packageJson.version,
      protocolVersion: packageJson.protocolVersion,
      password: 'myPassword1',
      renderingRequest: 'ReactOnRails.dummy',
      dependencyBundleTimestamps: [SERVER_BUNDLE_TIMESTAMP],
    };
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait a brief moment for the server to process the first object
    await new Promise<void>((resolveTimeout) => {
      setTimeout(resolveTimeout, 50);
    });

    // Verify handleIncrementalRenderRequest was called
    expect(handleSpy).toHaveBeenCalledTimes(1);

    // Send a valid update chunk
    req.write(`${JSON.stringify({ a: 1 })}\n`);

    // Wait for processing
    await new Promise<void>((resolveWait) => {
      setTimeout(resolveWait, 20);
    });

    // Verify the valid chunk was processed
    expect(sinkAddCalls).toHaveLength(1);
    expect(sinkAddCalls[0]).toEqual({ a: 1 });

    // Send a malformed JSON chunk
    req.write('{"b": 2, "c": 3\n'); // Missing closing brace

    // Send another valid chunk after the malformed one
    req.write(`${JSON.stringify({ d: 4 })}\n`);
    req.end();

    // Wait for the request to complete
    await responsePromise;

    // Wait for the sink.end to be called
    await new Promise<void>((resolve) => {
      setTimeout(resolve, 10);
    });

    // Verify that processing continued after the malformed chunk
    // The malformed chunk should be skipped, but valid chunks should be processed
    expect(sinkAddCalls).toEqual([{ a: 1 }, { d: 4 }]);
    
    // Verify that the stream completed successfully
    expect(sinkEnd).toHaveBeenCalledTimes(1);
    expect(sinkAbort).not.toHaveBeenCalled();
  });

  test('handles empty lines gracefully in the stream', async () => {
    // Create a bundle for this test
    await createVmBundle(TEST_NAME);

    const sinkAddCalls: unknown[] = [];
    const sinkEnd = jest.fn();
    const sinkAbort = jest.fn();

    const sink: incremental.IncrementalRenderSink = {
      add: (chunk) => {
        sinkAddCalls.push(chunk);
      },
      end: sinkEnd,
      abort: sinkAbort,
    };

    const mockResponse: ResponseResult = {
      status: 200,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      data: 'mock response',
    };

    const mockResult: incremental.IncrementalRenderResult = {
      response: mockResponse,
      sink,
    };

    const resultPromise = Promise.resolve(mockResult);
    const handleSpy = jest
      .spyOn(incremental, 'handleIncrementalRenderRequest')
      .mockImplementation(() => resultPromise);

    const addr = app.server.address();
    const host = typeof addr === 'object' && addr ? addr.address : '127.0.0.1';
    const port = typeof addr === 'object' && addr ? addr.port : 0;

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = http.request({
      hostname: host,
      port,
      path: `/bundles/${SERVER_BUNDLE_TIMESTAMP}/incremental-render/abc123`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-ndjson',
      },
    });
    req.setNoDelay(true);

    // Set up promise to handle the response
    const responsePromise = new Promise<void>((resolve, reject) => {
      req.on('response', (res) => {
        res.on('data', () => {
          // Consume response data to prevent hanging
        });
        res.on('end', () => {
          resolve();
        });
        res.on('error', (e) => {
          reject(e);
        });
      });
      req.on('error', (e) => {
        reject(e);
      });
    });

    // Write first object
    const initialObj = {
      gemVersion: packageJson.version,
      protocolVersion: packageJson.protocolVersion,
      password: 'myPassword1',
      renderingRequest: 'ReactOnRails.dummy',
      dependencyBundleTimestamps: [SERVER_BUNDLE_TIMESTAMP],
    };
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait for processing
    await new Promise<void>((resolveTimeout) => {
      setTimeout(resolveTimeout, 50);
    });

    // Send chunks with empty lines mixed in
    req.write('\n'); // Empty line
    req.write(`${JSON.stringify({ a: 1 })}\n`);
    req.write('\n'); // Empty line
    req.write(`${JSON.stringify({ b: 2 })}\n`);
    req.write('\n'); // Empty line
    req.write(`${JSON.stringify({ c: 3 })}\n`);
    req.end();

    // Wait for the request to complete
    await responsePromise;

    // Wait for the sink.end to be called
    await new Promise<void>((resolve) => {
      setTimeout(resolve, 10);
    });

    // Verify that only valid JSON objects were processed
    expect(handleSpy).toHaveBeenCalledTimes(1);
    expect(sinkAddCalls).toEqual([{ a: 1 }, { b: 2 }, { c: 3 }]);
    expect(sinkEnd).toHaveBeenCalledTimes(1);
  });

  test('throws error when first chunk processing fails (e.g., authentication)', async () => {
    // Create a bundle for this test
    await createVmBundle(TEST_NAME);

    const addr = app.server.address();
    const host = typeof addr === 'object' && addr ? addr.address : '127.0.0.1';
    const port = typeof addr === 'object' && addr ? addr.port : 0;

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = http.request({
      hostname: host,
      port,
      path: `/bundles/${SERVER_BUNDLE_TIMESTAMP}/incremental-render/abc123`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-ndjson',
      },
    });
    req.setNoDelay(true);

    // Set up promise to capture the response
    const responsePromise = new Promise<{ statusCode: number; data: string }>((resolve, reject) => {
      req.on('response', (res) => {
        let data = '';
        res.on('data', (chunk: string) => {
          data += chunk;
        });
        res.on('end', () => {
          resolve({ statusCode: res.statusCode || 0, data });
        });
        res.on('error', (e) => {
          reject(e);
        });
      });
      req.on('error', (e) => {
        reject(e);
      });
    });

    // Write first object with invalid password (will cause authentication failure)
    const initialObj = {
      gemVersion: packageJson.version,
      protocolVersion: packageJson.protocolVersion,
      password: 'wrongPassword', // Invalid password
      renderingRequest: 'ReactOnRails.dummy',
      dependencyBundleTimestamps: [SERVER_BUNDLE_TIMESTAMP],
    };
    req.write(`${JSON.stringify(initialObj)}\n`);
    req.end();

    // Wait for the response
    const response = await responsePromise;

    // Verify that we get an authentication error (should be 400 or 401)
    expect(response.statusCode).toBeGreaterThanOrEqual(400);
    expect(response.statusCode).toBeLessThan(500);
    
    // The response should contain an authentication error message
    const responseText = response.data.toLowerCase();
    expect(
      responseText.includes('password') || 
      responseText.includes('auth') || 
      responseText.includes('unauthorized')
    ).toBe(true);
  });
});
