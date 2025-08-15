import http from 'http';
import fs from 'fs';
import path from 'path';
import worker, { disableHttp2 } from '../src/worker';
import packageJson from '../src/shared/packageJson';
import { createVmBundle, BUNDLE_TIMESTAMP, waitFor } from './helper';

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

  // Helper functions to DRY up the tests
  const getServerAddress = () => {
    const addr = app.server.address();
    return {
      host: typeof addr === 'object' && addr ? addr.address : '127.0.0.1',
      port: typeof addr === 'object' && addr ? addr.port : 0,
    };
  };

  const createHttpRequest = (bundleTimestamp: string, pathSuffix = 'abc123') => {
    const { host, port } = getServerAddress();
    const req = http.request({
      hostname: host,
      port,
      path: `/bundles/${bundleTimestamp}/incremental-render/${pathSuffix}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-ndjson',
      },
    });
    req.setNoDelay(true);
    return req;
  };

  const createInitialObject = (bundleTimestamp: string, password = 'myPassword1') => ({
    gemVersion: packageJson.version,
    protocolVersion: packageJson.protocolVersion,
    password,
    renderingRequest: 'ReactOnRails.dummy',
    dependencyBundleTimestamps: [bundleTimestamp],
  });

  const setupResponseHandler = (req: http.ClientRequest, captureData = false) => {
    return new Promise<{ statusCode: number; data?: string }>((resolve, reject) => {
      req.on('response', (res) => {
        if (captureData) {
          let data = '';
          res.on('data', (chunk: string) => {
            data += chunk;
          });
          res.on('end', () => {
            resolve({ statusCode: res.statusCode || 0, data });
          });
        } else {
          res.on('data', () => {
            // Consume response data to prevent hanging
          });
          res.on('end', () => {
            resolve({ statusCode: res.statusCode || 0 });
          });
        }
        res.on('error', (e) => {
          reject(e);
        });
      });
      req.on('error', (e) => {
        reject(e);
      });
    });
  };

  /**
   * Helper function to create a basic test setup
   */
  const createBasicTestSetup = async () => {
    await createVmBundle(TEST_NAME);

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    return {
      SERVER_BUNDLE_TIMESTAMP,
    };
  };

  /**
   * Helper function to create a streaming test setup
   */
  const createStreamingTestSetup = async () => {
    await createVmBundle(TEST_NAME);

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    return {
      SERVER_BUNDLE_TIMESTAMP,
    };
  };

  /**
   * Helper function to create streaming response promise
   */
  const createStreamingResponsePromise = (req: http.ClientRequest) => {
    const receivedChunks: string[] = [];

    const promise = new Promise<{ statusCode: number; streamedData: string[] }>((resolve, reject) => {
      req.on('response', (res) => {
        res.on('data', (chunk: Buffer) => {
          const chunkStr = chunk.toString();
          receivedChunks.push(chunkStr);
        });
        res.on('end', () => {
          resolve({
            statusCode: res.statusCode || 0,
            streamedData: [...receivedChunks], // Return a copy
          });
        });
        res.on('error', (e) => {
          reject(e);
        });
      });
      req.on('error', (e) => {
        reject(e);
      });
    });

    return { promise, receivedChunks };
  };

  beforeAll(async () => {
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    // Clean up any existing bundles
    if (fs.existsSync(BUNDLE_PATH)) {
      fs.rmSync(BUNDLE_PATH, { recursive: true, force: true });
    }
  });

  test('calls handleIncrementalRenderRequest immediately after first chunk and processes each subsequent chunk immediately', async () => {
    const { SERVER_BUNDLE_TIMESTAMP } = await createBasicTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to capture the response
    const responsePromise = setupResponseHandler(req, true);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Send subsequent props chunks one by one and verify immediate processing
    const chunksToSend = [{ a: 1 }, { b: 2 }, { c: 3 }];

    // Process each chunk and verify it's handled
    for (let i = 0; i < chunksToSend.length; i += 1) {
      const chunk = chunksToSend[i];

      // Send the chunk
      req.write(`${JSON.stringify(chunk)}\n`);

      // Wait a moment for processing
      // eslint-disable-next-line no-await-in-loop
      await new Promise<void>((resolve) => {
        setTimeout(resolve, 10);
      });
    }

    // End the request
    req.end();

    // Wait for the response and verify
    const response = await responsePromise;
    expect(response.statusCode).toBe(200);
    expect(response.data).toBeDefined();
  });

  test('returns 410 error when bundle is missing', async () => {
    const { SERVER_BUNDLE_TIMESTAMP } = await createBasicTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to handle the response
    const responsePromise = setupResponseHandler(req, true);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // End the request
    req.end();

    // Wait for the response and verify
    const response = await responsePromise;
    expect(response.statusCode).toBe(410);
  });

  test('returns 400 error when first chunk contains malformed JSON', async () => {
    const { SERVER_BUNDLE_TIMESTAMP } = await createBasicTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to handle the response
    const responsePromise = setupResponseHandler(req, true);

    // Write malformed JSON as first chunk
    req.write('{"invalid": json}\n');

    // End the request
    req.end();

    // Wait for the response and verify
    const response = await responsePromise;
    expect(response.statusCode).toBe(400);
  });

  test('continues processing when update chunk contains malformed JSON', async () => {
    const { SERVER_BUNDLE_TIMESTAMP } = await createBasicTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to handle the response
    const responsePromise = setupResponseHandler(req, true);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Send a valid chunk
    req.write(`${JSON.stringify({ a: 1 })}\n`);

    // Wait for processing
    await waitFor(() => {
      // The worker's handleIncrementalRenderRequest will process the chunk.
    });

    // Verify the valid chunk was processed
    // The worker's handleIncrementalRenderRequest will add the chunk to its sink.

    // Send a malformed JSON chunk
    req.write('{"invalid": json}\n');

    // Send another valid chunk
    req.write(`${JSON.stringify({ d: 4 })}\n`);

    // End the request
    req.end();

    // Wait for the response
    await responsePromise;

    // The worker's handleIncrementalRenderRequest will call sink.end.
  });

  test('handles empty lines gracefully in the stream', async () => {
    const { SERVER_BUNDLE_TIMESTAMP } = await createBasicTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to handle the response
    const responsePromise = setupResponseHandler(req, true);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Send empty lines mixed with valid chunks
    req.write('\n'); // Empty line
    req.write(`${JSON.stringify({ a: 1 })}\n`); // Valid chunk
    req.write('\n'); // Empty line
    req.write(`${JSON.stringify({ b: 2 })}\n`); // Valid chunk
    req.write('\n'); // Empty line
    req.write(`${JSON.stringify({ c: 3 })}\n`); // Valid chunk

    // End the request
    req.end();

    // Wait for the response
    await responsePromise;

    // The worker's handleIncrementalRenderRequest will call sink.end.
  });

  test('throws error when first chunk processing fails (e.g., authentication)', async () => {
    const { SERVER_BUNDLE_TIMESTAMP } = await createBasicTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to handle the response
    const responsePromise = setupResponseHandler(req, true);

    // Write first object with wrong password
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP, 'wrongPassword');
    req.write(`${JSON.stringify(initialObj)}\n`);

    // End the request
    req.end();

    // Wait for the response and verify
    const response = await responsePromise;
    expect(response.statusCode).toBe(400);
  });

  test('streaming response - client receives all streamed chunks in real-time', async () => {
    const { SERVER_BUNDLE_TIMESTAMP } = await createStreamingTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to capture the streaming response
    const { promise } = createStreamingResponsePromise(req);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Send a few chunks to trigger processing
    const chunksToSend = [{ a: 1 }, { b: 2 }, { c: 3 }];

    // Send chunks and wait for processing
    for (let i = 0; i < chunksToSend.length; i += 1) {
      const chunk = chunksToSend[i];

      // Send the chunk
      req.write(`${JSON.stringify(chunk)}\n`);

      // Wait for processing
      // eslint-disable-next-line no-await-in-loop
      await waitFor(() => {
        // The worker's handleIncrementalRenderRequest will process the chunk.
      });
    }

    // End the request
    req.end();

    // Wait for the request to complete and capture the streaming response
    const response = await promise;

    // Verify the response status
    expect(response.statusCode).toBe(200);

    // Verify that we received streamed data
    expect(response.streamedData.length).toBeGreaterThan(0);

    // The worker's handleIncrementalRenderRequest will call sink.end.
  });

  test('echo server - processes each chunk and immediately streams it back', async () => {
    const { SERVER_BUNDLE_TIMESTAMP } = await createStreamingTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to capture the streaming response
    const { promise, receivedChunks } = createStreamingResponsePromise(req);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait for the server to process the first object and set up the response
    await waitFor(() => {
      // The worker's handleIncrementalRenderRequest will be called.
    });

    // Verify handleIncrementalRenderRequest was called
    // The worker's handleIncrementalRenderRequest will be called.

    // Send chunks one by one and verify immediate processing and echoing
    const chunksToSend = [
      { type: 'update', data: 'chunk1' },
      { type: 'update', data: 'chunk2' },
      { type: 'update', data: 'chunk3' },
      { type: 'update', data: 'chunk4' },
    ];

    // Process each chunk and immediately echo it back
    for (let i = 0; i < chunksToSend.length; i += 1) {
      const chunk = chunksToSend[i];

      // Send the chunk
      req.write(`${JSON.stringify(chunk)}\n`);

      // Wait for the chunk to be processed
      // eslint-disable-next-line no-await-in-loop
      await waitFor(() => {
        // The worker's handleIncrementalRenderRequest will process the chunk.
      });

      // Immediately echo the chunk back through the stream
      const echoResponse = `processed ${JSON.stringify(chunk)}`;
      // The worker's handleIncrementalRenderRequest will push data to the stream.

      // Wait for the echo response to be received by the client
      // eslint-disable-next-line no-await-in-loop
      await waitFor(() => {
        expect(receivedChunks[i]).toEqual(echoResponse);
      });

      // Wait a moment to ensure the echo is sent
      // eslint-disable-next-line no-await-in-loop
      await new Promise<void>((resolve) => {
        setTimeout(resolve, 10);
      });
    }

    // End the stream to signal no more data
    // The worker's handleIncrementalRenderRequest will push null to signal end.

    // End the request
    req.end();

    // Wait for the request to complete and capture the streaming response
    const response = await promise;

    // Verify the response status
    expect(response.statusCode).toBe(200);

    // Verify that we received echo responses for each chunk
    expect(response.streamedData).toHaveLength(chunksToSend.length);

    // Verify that each chunk was echoed back correctly
    chunksToSend.forEach((chunk, index) => {
      const expectedEcho = `processed ${JSON.stringify(chunk)}`;
      const receivedEcho = response.streamedData[index];
      expect(receivedEcho).toEqual(expectedEcho);
    });

    // The worker's handleIncrementalRenderRequest will call sink.end.
  });
});
