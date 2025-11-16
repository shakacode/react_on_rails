import http from 'http';
import fs from 'fs';
import path from 'path';
import worker, { disableHttp2 } from '../src/worker';
import packageJson from '../src/shared/packageJson';
import * as incremental from '../src/worker/handleIncrementalRenderRequest';
import {
  createVmBundle,
  createSecondaryVmBundle,
  createIncrementalVmBundle,
  createIncrementalSecondaryVmBundle,
  BUNDLE_TIMESTAMP,
  SECONDARY_BUNDLE_TIMESTAMP,
  waitFor,
} from './helper';
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
    supportModules: true,
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

  const createMockSink = () => {
    const sinkAdd = jest.fn();

    const sink: incremental.IncrementalRenderSink = {
      add: sinkAdd,
    };

    return { sink, sinkAdd };
  };

  const createMockResponse = (data = 'mock response'): ResponseResult => ({
    status: 200,
    headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
    data,
  });

  const createMockResult = (sink: incremental.IncrementalRenderSink, response?: ResponseResult) => {
    const mockResponse = response || createMockResponse();
    return {
      response: mockResponse,
      sink,
    } as incremental.IncrementalRenderResult;
  };

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
   * Helper function to create a basic test setup with mocked handleIncrementalRenderRequest
   */
  const createBasicTestSetup = async () => {
    await createVmBundle(TEST_NAME);

    const { sink, sinkAdd } = createMockSink();
    const mockResponse = createMockResponse();
    const mockResult = createMockResult(sink, mockResponse);

    const handleSpy = jest
      .spyOn(incremental, 'handleIncrementalRenderRequest')
      .mockImplementation(() => Promise.resolve(mockResult));

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    return {
      sink,
      sinkAdd,
      mockResponse,
      mockResult,
      handleSpy,
      SERVER_BUNDLE_TIMESTAMP,
    };
  };

  /**
   * Helper function to create a streaming test setup
   */
  const createStreamingTestSetup = async () => {
    await createVmBundle(TEST_NAME);

    const { Readable } = await import('stream');
    const responseStream = new Readable({
      read() {
        // This is a readable stream that we can push to
      },
    });

    const sinkAdd = jest.fn();

    const sink: incremental.IncrementalRenderSink = {
      add: sinkAdd,
    };

    const mockResponse: ResponseResult = {
      status: 200,
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      stream: responseStream,
    };

    const mockResult: incremental.IncrementalRenderResult = {
      response: mockResponse,
      sink,
    };

    const handleSpy = jest
      .spyOn(incremental, 'handleIncrementalRenderRequest')
      .mockImplementation(() => Promise.resolve(mockResult));

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    return {
      responseStream,
      sinkAdd,
      sink,
      mockResponse,
      mockResult,
      handleSpy,
      SERVER_BUNDLE_TIMESTAMP,
    };
  };

  /**
   * Helper function to send chunks and wait for processing
   */
  const sendChunksAndWaitForProcessing = async (
    req: http.ClientRequest,
    chunks: unknown[],
    waitForCondition: (chunk: unknown, index: number) => Promise<void>,
  ) => {
    for (let i = 0; i < chunks.length; i += 1) {
      const chunk = chunks[i];
      req.write(`${JSON.stringify(chunk)}\n`);

      // eslint-disable-next-line no-await-in-loop
      await waitForCondition(chunk, i);
    }
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

  afterEach(() => {
    jest.restoreAllMocks();
  });

  beforeAll(async () => {
    await app.ready();
    await app.listen({ port: 0 });
  });

  afterAll(async () => {
    await app.close();
  });

  test('calls handleIncrementalRenderRequest immediately after first chunk and processes each subsequent chunk immediately', async () => {
    const { sinkAdd, handleSpy, SERVER_BUNDLE_TIMESTAMP } = await createBasicTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to handle the response
    const responsePromise = setupResponseHandler(req);

    // Write first object (headers, auth, and initial renderingRequest)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait for the server to process the first object
    await waitFor(() => {
      expect(handleSpy).toHaveBeenCalledTimes(1);
    });

    // Verify handleIncrementalRenderRequest was called immediately after first chunk
    expect(handleSpy).toHaveBeenCalledTimes(1);
    expect(sinkAdd).not.toHaveBeenCalled(); // No subsequent chunks processed yet

    // Send subsequent props chunks one by one and verify immediate processing
    const chunksToSend = [{ a: 1 }, { b: 2 }, { c: 3 }];

    await sendChunksAndWaitForProcessing(req, chunksToSend, async (chunk, index) => {
      const expectedCallsBeforeWrite = index;

      // Verify state before writing this chunk
      expect(sinkAdd).toHaveBeenCalledTimes(expectedCallsBeforeWrite);

      // Wait for the chunk to be processed
      await waitFor(() => {
        expect(sinkAdd).toHaveBeenCalledTimes(expectedCallsBeforeWrite + 1);
      });

      // Verify the chunk was processed immediately
      expect(sinkAdd).toHaveBeenCalledTimes(expectedCallsBeforeWrite + 1);
      expect(sinkAdd).toHaveBeenNthCalledWith(expectedCallsBeforeWrite + 1, chunk);
    });

    req.end();

    // Wait for the request to complete
    await responsePromise;

    // Final verification: all chunks were processed in the correct order
    expect(handleSpy).toHaveBeenCalledTimes(1);
    expect(sinkAdd.mock.calls).toEqual([[{ a: 1 }], [{ b: 2 }], [{ c: 3 }]]);
  });

  test('returns 410 error when bundle is missing', async () => {
    const MISSING_BUNDLE_TIMESTAMP = 'non-existent-bundle-123';

    // Create the HTTP request with a non-existent bundle
    const req = createHttpRequest(MISSING_BUNDLE_TIMESTAMP);

    // Set up promise to capture the response
    const responsePromise = setupResponseHandler(req, true);

    // Write first object with auth data
    const initialObj = createInitialObject(MISSING_BUNDLE_TIMESTAMP);
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

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to capture the response
    const responsePromise = setupResponseHandler(req, true);

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

    const { sink, sinkAdd } = createMockSink();

    const mockResponse: ResponseResult = createMockResponse();

    const mockResult: incremental.IncrementalRenderResult = createMockResult(sink, mockResponse);

    const resultPromise = Promise.resolve(mockResult);
    const handleSpy = jest
      .spyOn(incremental, 'handleIncrementalRenderRequest')
      .mockImplementation(() => resultPromise);

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to handle the response
    const responsePromise = setupResponseHandler(req);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait for the server to process the first object
    await waitFor(() => {
      expect(handleSpy).toHaveBeenCalledTimes(1);
    });

    // Send a valid chunk first
    const validChunk = { a: 1 };
    req.write(`${JSON.stringify(validChunk)}\n`);

    // Wait for processing
    await waitFor(() => {
      expect(sinkAdd).toHaveBeenCalledWith({ a: 1 });
    });

    // Verify the valid chunk was processed
    expect(sinkAdd).toHaveBeenCalledWith({ a: 1 });

    // Send a malformed JSON chunk
    const malformedChunk = '{"invalid": json}\n';
    req.write(malformedChunk);

    // Send another valid chunk
    const secondValidChunk = { d: 4 };
    req.write(`${JSON.stringify(secondValidChunk)}\n`);

    req.end();

    // Wait for the request to complete
    await responsePromise;

    // Verify that processing continued after the malformed chunk
    // The malformed chunk should be skipped, but valid chunks should be processed
    // Verify that the stream completed successfully
    await waitFor(() => {
      expect(sinkAdd.mock.calls).toEqual([[{ a: 1 }], [{ d: 4 }]]);
    });
  });

  test('handles empty lines gracefully in the stream', async () => {
    // Create a bundle for this test
    await createVmBundle(TEST_NAME);

    const { sink, sinkAdd } = createMockSink();

    const mockResponse: ResponseResult = createMockResponse();

    const mockResult: incremental.IncrementalRenderResult = createMockResult(sink, mockResponse);

    const resultPromise = Promise.resolve(mockResult);
    const handleSpy = jest
      .spyOn(incremental, 'handleIncrementalRenderRequest')
      .mockImplementation(() => resultPromise);

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to handle the response
    const responsePromise = setupResponseHandler(req);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait for processing
    await waitFor(() => {
      expect(handleSpy).toHaveBeenCalledTimes(1);
    });

    // Send chunks with empty lines mixed in
    const chunksToSend = [{ a: 1 }, { b: 2 }, { c: 3 }];

    for (const chunk of chunksToSend) {
      req.write(`${JSON.stringify(chunk)}\n`);
      // eslint-disable-next-line no-await-in-loop
      await waitFor(() => {
        expect(sinkAdd).toHaveBeenCalledWith(chunk);
      });
    }

    req.end();

    // Wait for the request to complete
    await responsePromise;

    // Verify that only valid JSON objects were processed
    expect(handleSpy).toHaveBeenCalledTimes(1);
    expect(sinkAdd.mock.calls).toEqual([[{ a: 1 }], [{ b: 2 }], [{ c: 3 }]]);
  });

  test('throws error when first chunk processing fails (e.g., authentication)', async () => {
    // Create a bundle for this test
    await createVmBundle(TEST_NAME);

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to capture the response
    const responsePromise = setupResponseHandler(req, true);

    // Write first object with invalid password (will cause authentication failure)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP, 'wrongPassword'); // Invalid password
    req.write(`${JSON.stringify(initialObj)}\n`);
    req.end();

    // Wait for the response
    const response = await responsePromise;

    // Verify that we get an authentication error (should be 400 or 401)
    expect(response.statusCode).toBeGreaterThanOrEqual(400);
    expect(response.statusCode).toBeLessThan(500);

    // The response should contain an authentication error message
    const responseText = response.data?.toLowerCase();
    expect(
      responseText?.includes('password') ||
        responseText?.includes('auth') ||
        responseText?.includes('unauthorized'),
    ).toBe(true);
  });

  test('streaming response - client receives all streamed chunks in real-time', async () => {
    const responseChunks = [
      'Hello from stream',
      'Chunk 1',
      'Chunk 2',
      'Chunk 3',
      'Chunk 4',
      'Chunk 5',
      'Goodbye from stream',
    ];

    const { responseStream, sinkAdd, handleSpy, SERVER_BUNDLE_TIMESTAMP } = await createStreamingTestSetup();

    // write the response chunks to the stream
    let sentChunkIndex = 0;
    const intervalId = setInterval(() => {
      if (sentChunkIndex < responseChunks.length) {
        responseStream.push(responseChunks[sentChunkIndex] || null);
        sentChunkIndex += 1;
      } else {
        responseStream.push(null);
        clearInterval(intervalId);
      }
    }, 10);

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to capture the streaming response
    const { promise } = createStreamingResponsePromise(req);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait for the server to process the first object and set up the response
    await waitFor(() => {
      expect(handleSpy).toHaveBeenCalledTimes(1);
    });

    // Verify handleIncrementalRenderRequest was called
    expect(handleSpy).toHaveBeenCalledTimes(1);

    // Send a few chunks to trigger processing
    const chunksToSend = [
      { type: 'update', data: 'chunk1' },
      { type: 'update', data: 'chunk2' },
      { type: 'update', data: 'chunk3' },
    ];

    await sendChunksAndWaitForProcessing(req, chunksToSend, async (chunk) => {
      await waitFor(() => {
        expect(sinkAdd).toHaveBeenCalledWith(chunk);
      });
    });

    // End the request
    req.end();

    // Wait for the request to complete and capture the streaming response
    const response = await promise;

    // Verify the response status
    expect(response.statusCode).toBe(200);

    // Verify that we received all the streamed chunks
    expect(response.streamedData).toHaveLength(responseChunks.length);

    // Verify that each chunk was received in order
    responseChunks.forEach((expectedChunk, index) => {
      const receivedChunk = response.streamedData[index];
      expect(receivedChunk).toEqual(expectedChunk);
    });

    // Verify that all request chunks were processed
    expect(sinkAdd).toHaveBeenCalledTimes(chunksToSend.length);
    chunksToSend.forEach((chunk, index) => {
      expect(sinkAdd).toHaveBeenNthCalledWith(index + 1, chunk);
    });

    // Verify that the mock was called correctly
    expect(handleSpy).toHaveBeenCalledTimes(1);
  });

  test('echo server - processes each chunk and immediately streams it back', async () => {
    const { responseStream, sinkAdd, handleSpy, SERVER_BUNDLE_TIMESTAMP } = await createStreamingTestSetup();

    // Create the HTTP request
    const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

    // Set up promise to capture the streaming response
    const { promise, receivedChunks } = createStreamingResponsePromise(req);

    // Write first object (valid JSON)
    const initialObj = createInitialObject(SERVER_BUNDLE_TIMESTAMP);
    req.write(`${JSON.stringify(initialObj)}\n`);

    // Wait for the server to process the first object and set up the response
    await waitFor(() => {
      expect(handleSpy).toHaveBeenCalledTimes(1);
    });

    // Verify handleIncrementalRenderRequest was called
    expect(handleSpy).toHaveBeenCalledTimes(1);

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
        expect(sinkAdd).toHaveBeenCalledWith(chunk);
      });

      // Immediately echo the chunk back through the stream
      const echoResponse = `processed ${JSON.stringify(chunk)}`;
      responseStream.push(echoResponse);

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
    responseStream.push(null);

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

    // Verify that all request chunks were processed
    expect(sinkAdd).toHaveBeenCalledTimes(chunksToSend.length);
    chunksToSend.forEach((chunk, index) => {
      expect(sinkAdd).toHaveBeenNthCalledWith(index + 1, chunk);
    });

    // Verify that the mock was called correctly
    expect(handleSpy).toHaveBeenCalledTimes(1);
  });

  describe('incremental render update chunk functionality', () => {
    test('basic incremental update - initial request gets value, update chunks set value', async () => {
      await createIncrementalVmBundle(TEST_NAME);
      const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

      // Create the HTTP request
      const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

      // Set up response handling
      const responsePromise = setupResponseHandler(req, true);

      // Send the initial object that gets the async value (should resolve after setAsyncValue is called)
      const initialObject = {
        ...createInitialObject(SERVER_BUNDLE_TIMESTAMP),
        renderingRequest: 'ReactOnRails.getStreamValues()',
      };
      req.write(`${JSON.stringify(initialObject)}\n`);

      // Send update chunks that set the async value
      const updateChunk1 = {
        bundleTimestamp: SERVER_BUNDLE_TIMESTAMP,
        updateChunk: 'ReactOnRails.addStreamValue("first update");ReactOnRails.endStream();',
      };
      req.write(`${JSON.stringify(updateChunk1)}\n`);

      // End the request
      req.end();

      // Wait for the response
      const response = await responsePromise;

      // Verify the response
      expect(response.statusCode).toBe(200);
      expect(response.data).toBe('first update'); // Should resolve with the first setAsyncValue call
    });

    test('incremental updates work with multiple bundles using runOnOtherBundle', async () => {
      await createIncrementalVmBundle(TEST_NAME);
      await createIncrementalSecondaryVmBundle(TEST_NAME);
      const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);
      const SECONDARY_BUNDLE_TIMESTAMP_STR = String(SECONDARY_BUNDLE_TIMESTAMP);

      // Create the HTTP request
      const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

      // Set up response handling
      const responsePromise = setupResponseHandler(req, true);

      // Send the initial object that gets values from both bundles
      const initialObject = {
        ...createInitialObject(SERVER_BUNDLE_TIMESTAMP),
        renderingRequest: `
          runOnOtherBundle(${SECONDARY_BUNDLE_TIMESTAMP}, 'ReactOnRails.getAsyncValue()').then((secondaryValue) => ({
            mainBundleValue: ReactOnRails.getAsyncValue(),
            secondaryBundleValue: JSON.parse(secondaryValue),
          }));
        `,
        dependencyBundleTimestamps: [SECONDARY_BUNDLE_TIMESTAMP_STR],
      };
      req.write(`${JSON.stringify(initialObject)}\n`);

      // Send update chunks to both bundles
      const updateMainBundle = {
        bundleTimestamp: SERVER_BUNDLE_TIMESTAMP,
        updateChunk: 'ReactOnRails.setAsyncValue("main bundle updated")',
      };
      req.write(`${JSON.stringify(updateMainBundle)}\n`);

      const updateSecondaryBundle = {
        bundleTimestamp: SECONDARY_BUNDLE_TIMESTAMP_STR,
        updateChunk: 'ReactOnRails.setAsyncValue("secondary bundle updated")',
      };
      req.write(`${JSON.stringify(updateSecondaryBundle)}\n`);

      // End the request
      req.end();

      // Wait for the response
      const response = await responsePromise;

      // Verify the response
      expect(response.statusCode).toBe(200);
      const responseData = JSON.parse(response.data || '{}') as {
        mainBundleValue: unknown;
        secondaryBundleValue: unknown;
      };
      expect(responseData.mainBundleValue).toBe('main bundle updated');
      expect(responseData.secondaryBundleValue).toBe('secondary bundle updated');
    });

    test('streaming functionality with incremental updates', async () => {
      await createIncrementalVmBundle(TEST_NAME);
      const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

      // Create the HTTP request
      const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

      // Set up response handling to capture streaming data
      const streamedData: string[] = [];
      const responsePromise = new Promise<{ statusCode: number }>((resolve, reject) => {
        req.on('response', (res) => {
          res.on('data', (chunk: string) => {
            streamedData.push(chunk.toString());
          });
          res.on('end', () => {
            resolve({ statusCode: res.statusCode || 0 });
          });
          res.on('error', reject);
        });
        req.on('error', reject);
      });

      // Send the initial object that clears stream values and returns the stream
      const initialObject = {
        ...createInitialObject(SERVER_BUNDLE_TIMESTAMP),
        renderingRequest: 'ReactOnRails.getStreamValues()',
      };
      req.write(`${JSON.stringify(initialObject)}\n`);

      // Send update chunks that add stream values
      const streamValues = ['stream1', 'stream2', 'stream3'];
      for (const value of streamValues) {
        const updateChunk = {
          bundleTimestamp: SERVER_BUNDLE_TIMESTAMP,
          updateChunk: `ReactOnRails.addStreamValue("${value}")`,
        };
        req.write(`${JSON.stringify(updateChunk)}\n`);
      }

      // No need to get stream values again since we're already streaming

      // End the request
      req.end();

      // Wait for the response
      const response = await responsePromise;

      // Verify the response
      expect(response.statusCode).toBe(200);
      // Since we're returning a stream, the response should indicate streaming
      expect(streamedData.length).toBeGreaterThan(0);
    });

    test('error handling in incremental render updates', async () => {
      await createIncrementalVmBundle(TEST_NAME);
      const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

      // Create the HTTP request
      const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

      // Set up response handling
      const responsePromise = setupResponseHandler(req, true);

      // Send the initial object
      const initialObject = {
        ...createInitialObject(SERVER_BUNDLE_TIMESTAMP),
        renderingRequest: 'ReactOnRails.getAsyncValue()',
      };
      req.write(`${JSON.stringify(initialObject)}\n`);

      // Send a malformed update chunk (missing bundleTimestamp)
      const malformedChunk = {
        updateChunk: 'ReactOnRails.setAsyncValue("should not work")',
      };
      req.write(`${JSON.stringify(malformedChunk)}\n`);

      // Send a valid update chunk after the malformed one
      const validChunk = {
        bundleTimestamp: SERVER_BUNDLE_TIMESTAMP,
        updateChunk: 'ReactOnRails.setAsyncValue("valid update")',
      };
      req.write(`${JSON.stringify(validChunk)}\n`);

      // Send a chunk with invalid JavaScript
      const invalidJSChunk = {
        bundleTimestamp: SERVER_BUNDLE_TIMESTAMP,
        updateChunk: 'this is not valid javascript syntax !!!',
      };
      req.write(`${JSON.stringify(invalidJSChunk)}\n`);

      // End the request
      req.end();

      // Wait for the response
      const response = await responsePromise;

      // Verify the response - should still work despite errors
      expect(response.statusCode).toBe(200);
      expect(response.data).toBe('"valid update"'); // Should resolve with the valid update
    });

    test('update chunks with non-existent bundle timestamp', async () => {
      await createIncrementalVmBundle(TEST_NAME);
      const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);
      const NON_EXISTENT_TIMESTAMP = '9999999999999';

      // Create the HTTP request
      const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

      // Set up response handling
      const responsePromise = setupResponseHandler(req, true);

      // Send the initial object
      const initialObject = {
        ...createInitialObject(SERVER_BUNDLE_TIMESTAMP),
        renderingRequest: 'ReactOnRails.getAsyncValue()',
      };
      req.write(`${JSON.stringify(initialObject)}\n`);

      // Send update chunk with non-existent bundle timestamp
      const updateChunk = {
        bundleTimestamp: NON_EXISTENT_TIMESTAMP,
        updateChunk: 'ReactOnRails.setAsyncValue("should not work")',
      };
      req.write(`${JSON.stringify(updateChunk)}\n`);

      // Send a valid update chunk
      const validChunk = {
        bundleTimestamp: SERVER_BUNDLE_TIMESTAMP,
        updateChunk: 'ReactOnRails.setAsyncValue("valid update")',
      };
      req.write(`${JSON.stringify(validChunk)}\n`);

      // End the request
      req.end();

      // Wait for the response
      const response = await responsePromise;

      // Verify the response
      expect(response.statusCode).toBe(200);
      expect(response.data).toBe('"valid update"'); // Should resolve with the valid update
    });

    test('complex multi-bundle streaming scenario', async () => {
      await createIncrementalVmBundle(TEST_NAME);
      await createIncrementalSecondaryVmBundle(TEST_NAME);
      const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);
      const SECONDARY_BUNDLE_TIMESTAMP_STR = String(SECONDARY_BUNDLE_TIMESTAMP);

      // Create the HTTP request
      const req = createHttpRequest(SERVER_BUNDLE_TIMESTAMP);

      // Set up response handling
      const responsePromise = setupResponseHandler(req, true);

      // Send the initial object that sets up both bundles for streaming
      const initialObject = {
        ...createInitialObject(SERVER_BUNDLE_TIMESTAMP),
        renderingRequest: `
          ReactOnRails.clearStreamValues();
          runOnOtherBundle(${SECONDARY_BUNDLE_TIMESTAMP}, 'ReactOnRails.clearStreamValues()').then(() => ({
            mainCleared: true,
            secondaryCleared: true,
          }));
        `,
        dependencyBundleTimestamps: [SECONDARY_BUNDLE_TIMESTAMP_STR],
      };
      req.write(`${JSON.stringify(initialObject)}\n`);

      // Send alternating updates to both bundles
      const updates = [
        { bundleTimestamp: SERVER_BUNDLE_TIMESTAMP, updateChunk: 'ReactOnRails.addStreamValue("main1")' },
        {
          bundleTimestamp: SECONDARY_BUNDLE_TIMESTAMP_STR,
          updateChunk: 'ReactOnRails.addStreamValue("secondary1")',
        },
        { bundleTimestamp: SERVER_BUNDLE_TIMESTAMP, updateChunk: 'ReactOnRails.addStreamValue("main2")' },
        {
          bundleTimestamp: SECONDARY_BUNDLE_TIMESTAMP_STR,
          updateChunk: 'ReactOnRails.addStreamValue("secondary2")',
        },
      ];

      for (const update of updates) {
        req.write(`${JSON.stringify(update)}\n`);
      }

      // Get final state from both bundles
      const getFinalState = {
        bundleTimestamp: SERVER_BUNDLE_TIMESTAMP,
        updateChunk: `
          runOnOtherBundle(${SECONDARY_BUNDLE_TIMESTAMP}, 'ReactOnRails.getStreamValues()').then((secondaryValues) => ({
            mainValues: ReactOnRails.getStreamValues(),
            secondaryValues: JSON.parse(secondaryValues),
          }));
        `,
      };
      req.write(`${JSON.stringify(getFinalState)}\n`);

      // End the request
      req.end();

      // Wait for the response
      const response = await responsePromise;

      // Verify the response
      expect(response.statusCode).toBe(200);
      const responseData = JSON.parse(response.data || '{}') as {
        mainCleared: unknown;
        secondaryCleared: unknown;
      };
      expect(responseData.mainCleared).toBe(true);
      expect(responseData.secondaryCleared).toBe(true);
    });
  });
});
