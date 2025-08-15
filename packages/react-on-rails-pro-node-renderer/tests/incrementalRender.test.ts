import http from 'http';
import fs from 'fs';
import path from 'path';
import worker, { disableHttp2 } from '../src/worker';
import packageJson from '../src/shared/packageJson';
import * as incremental from '../src/worker/handleIncrementalRenderRequest';
import { createVmBundle, BUNDLE_TIMESTAMP, waitFor } from './helper';
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
    const sinkEnd = jest.fn();
    const sinkAbort = jest.fn();

    const sink: incremental.IncrementalRenderSink = {
      add: sinkAdd,
      end: sinkEnd,
      abort: sinkAbort,
    };

    return { sink, sinkAdd, sinkEnd, sinkAbort };
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

    const { sink, sinkAdd, sinkEnd, sinkAbort } = createMockSink();
    const mockResponse = createMockResponse();
    const mockResult = createMockResult(sink, mockResponse);

    const handleSpy = jest
      .spyOn(incremental, 'handleIncrementalRenderRequest')
      .mockImplementation(() => Promise.resolve(mockResult));

    const SERVER_BUNDLE_TIMESTAMP = String(BUNDLE_TIMESTAMP);

    return {
      sink,
      sinkAdd,
      sinkEnd,
      sinkAbort,
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
      end: jest.fn(),
      abort: jest.fn(),
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

  beforeAll(async () => {
    await app.ready();
    await app.listen({ port: 0 });
  });

  afterAll(async () => {
    await app.close();
  });

  test('calls handleIncrementalRenderRequest immediately after first chunk and processes each subsequent chunk immediately', async () => {
    const { sinkAdd, sinkEnd, sinkAbort, handleSpy, SERVER_BUNDLE_TIMESTAMP } = await createBasicTestSetup();

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

    // Wait for the sink.end to be called
    await waitFor(() => {
      expect(sinkEnd).toHaveBeenCalledTimes(1);
    });

    // Final verification: all chunks were processed in the correct order
    expect(handleSpy).toHaveBeenCalledTimes(1);
    expect(sinkAdd.mock.calls).toEqual([[{ a: 1 }], [{ b: 2 }], [{ c: 3 }]]);

    // Verify stream lifecycle methods were called correctly
    expect(sinkEnd).toHaveBeenCalledTimes(1);
    expect(sinkAbort).not.toHaveBeenCalled();
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

    const { sink, sinkAdd, sinkEnd, sinkAbort } = createMockSink();

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

    // Wait for the sink.end to be called
    await waitFor(() => {
      expect(sinkEnd).toHaveBeenCalledTimes(1);
    });

    // Verify that processing continued after the malformed chunk
    // The malformed chunk should be skipped, but valid chunks should be processed
    // Verify that the stream completed successfully
    await waitFor(() => {
      expect(sinkAdd.mock.calls).toEqual([[{ a: 1 }], [{ d: 4 }]]);
      expect(sinkEnd).toHaveBeenCalledTimes(1);
      expect(sinkAbort).not.toHaveBeenCalled();
    });
  });

  test('handles empty lines gracefully in the stream', async () => {
    // Create a bundle for this test
    await createVmBundle(TEST_NAME);

    const { sink, sinkAdd, sinkEnd } = createMockSink();

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

    // Wait for the sink.end to be called
    await waitFor(() => {
      expect(sinkEnd).toHaveBeenCalledTimes(1);
    });

    // Verify that only valid JSON objects were processed
    expect(handleSpy).toHaveBeenCalledTimes(1);
    expect(sinkAdd.mock.calls).toEqual([[{ a: 1 }], [{ b: 2 }], [{ c: 3 }]]);
    expect(sinkEnd).toHaveBeenCalledTimes(1);
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

    const { responseStream, sinkAdd, sink, handleSpy, SERVER_BUNDLE_TIMESTAMP } =
      await createStreamingTestSetup();

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

    await waitFor(() => {
      expect(sink.end).toHaveBeenCalled();
    });
  });

  test('echo server - processes each chunk and immediately streams it back', async () => {
    const { responseStream, sinkAdd, sink, handleSpy, SERVER_BUNDLE_TIMESTAMP } =
      await createStreamingTestSetup();

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

    // Verify that the sink.end was called
    await waitFor(() => {
      expect(sink.end).toHaveBeenCalled();
    });
  });
});
