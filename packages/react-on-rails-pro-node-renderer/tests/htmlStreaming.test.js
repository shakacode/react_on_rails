import http2 from 'http2';
import buildApp from '../src/worker';
import { createTestConfig } from './testingNodeRendererConfigs';
import * as errorReporter from '../src/shared/errorReporter';
import { createForm, SERVER_BUNDLE_TIMESTAMP } from './httpRequestUtils';

const { config } = createTestConfig('htmlStreaming');
const app = buildApp(config);

beforeAll(async () => {
  await app.ready();
  await app.listen({ port: 0 });
});

afterAll(async () => {
  await app.close();
});

jest.spyOn(errorReporter, 'message').mockImplementation(jest.fn());

const makeRequest = async (options = {}) => {
  const startTime = Date.now();
  const form = createForm(options);
  const { port } = app.server.address();
  const client = http2.connect(`http://localhost:${port}`);
  const request = client.request({
    ':method': 'POST',
    ':path': `/bundles/${SERVER_BUNDLE_TIMESTAMP}/render/454a82526211afdb215352755d36032c`,
    'content-type': `multipart/form-data; boundary=${form.getBoundary()}`,
  });
  request.setEncoding('utf8');

  const chunks = [];
  const jsonChunks = [];
  let firstByteTime;
  let status;

  // Length-prefixed parser state: accumulates raw bytes and extracts
  // complete chunks in the format: <metadata JSON>\t<hex length>\n<raw content>
  let parserBuf = Buffer.alloc(0);
  let parserState = 'header'; // 'header' or 'content'
  let parserContentLen = 0;
  let parserMetadata = null;

  const parseChunks = () => {
    // eslint-disable-next-line no-constant-condition
    while (true) {
      if (parserState === 'header') {
        const idx = parserBuf.indexOf(0x0a); // \n
        if (idx < 0) break;

        const header = parserBuf.subarray(0, idx);
        parserBuf = parserBuf.subarray(idx + 1);
        const tabIdx = header.indexOf(0x09); // \t

        if (tabIdx >= 0) {
          // Length-prefixed format
          const metaJson = header.subarray(0, tabIdx).toString('utf8');
          const lenHex = header.subarray(tabIdx + 1).toString('utf8');
          parserMetadata = JSON.parse(metaJson);
          parserContentLen = parseInt(lenHex, 16);
          parserState = 'content';
        } else {
          // Legacy NDJSON format fallback
          const line = header.toString('utf8').trim();
          if (line.length > 0) {
            try {
              const parsed = JSON.parse(line);
              chunks.push(parsed.html || '');
              jsonChunks.push(parsed);
            } catch (e) {
              chunks.push(line);
              jsonChunks.push({ hasErrors: true, error: `JSON parsing failed: ${e.message}` });
            }
          }
        }
      } else {
        // parserState === 'content'
        if (parserBuf.length < parserContentLen) break;

        const content = parserBuf.subarray(0, parserContentLen).toString('utf8');
        parserBuf = parserBuf.subarray(parserContentLen);
        const parsed = { html: content, ...parserMetadata };
        chunks.push(content);
        jsonChunks.push(parsed);
        parserMetadata = null;
        parserState = 'header';
      }
    }
  };

  request.on('response', (headers) => {
    status = headers[':status'];
  });

  request.on('data', (data) => {
    const buf = typeof data === 'string' ? Buffer.from(data, 'utf8') : data;
    parserBuf = Buffer.concat([parserBuf, buf]);
    parseChunks();
    if (!firstByteTime) {
      firstByteTime = Date.now();
    }
  });

  form.pipe(request);
  form.on('end', () => {
    request.end();
  });

  await new Promise((resolve, reject) => {
    request.on('end', () => {
      client.close();
      resolve();
    });
    request.on('error', (err) => {
      client.close();
      reject(err);
    });
  });

  const endTime = Date.now();
  const fullBody = chunks.join('');
  const timeToFirstByte = firstByteTime - startTime;
  const streamingTime = endTime - firstByteTime;

  return { status, chunks, fullBody, timeToFirstByte, streamingTime, jsonChunks };
};

describe('html streaming', () => {
  it("should send each html chunk immediately when it's ready", async () => {
    const { status, timeToFirstByte, streamingTime, chunks } = await makeRequest();
    expect(status).toBe(200);
    expect(chunks.length).toBeGreaterThanOrEqual(5);

    expect(timeToFirstByte).toBeLessThan(2000);
    expect(streamingTime).toBeGreaterThan(3 * timeToFirstByte);
  }, 10000);

  it('should returns the component shell only in the first chunk', async () => {
    const { status, chunks } = await makeRequest();
    expect(status).toBe(200);

    const firstChunk = chunks[0];

    expect(firstChunk).toContain('<p>Header for AsyncComponentsTreeForTesting</p>');
    expect(firstChunk).toContain('<p>Footer for AsyncComponentsTreeForTesting</p>');
    expect(firstChunk).toContain('Loading HelloWorldHooks...');
    expect(firstChunk).toContain('Loading branch1...');
    expect(firstChunk).toContain('Loading branch2...');
  }, 10000);

  it('should stream chunks one by one', async () => {
    const { status, chunks } = await makeRequest();
    expect(status).toBe(200);

    const secondChunk = chunks[1];
    expect(secondChunk).not.toContain('<p>Header for AsyncComponentsTreeForTesting</p>');
    expect(secondChunk).not.toContain('<p>Footer for AsyncComponentsTreeForTesting</p>');
    expect(secondChunk).not.toContain('Loading branch1...');
    expect(secondChunk).not.toContain('Loading branch2...');
    expect(secondChunk).not.toContain('branch1 (level 0)');
  }, 10000);

  it('should contains all components', async () => {
    const { fullBody } = await makeRequest();

    expect(fullBody).toContain('branch1 (level 4)');
    expect(fullBody).toContain('branch1 (level 3)');
    expect(fullBody).toContain('branch1 (level 2)');
    expect(fullBody).toContain('branch1 (level 1)');
    expect(fullBody).toContain('branch1 (level 0)');
    expect(fullBody).toContain('branch2 (level 1)');
    expect(fullBody).toContain('branch2 (level 0)');
  }, 10000);

  it.each([true, false])(
    'sever components are not rendered when a sync error happens, but the error is not considered at the shell (throwJsErrors: %s)',
    async (throwJsErrors) => {
      const { status, jsonChunks } = await makeRequest({
        props: { throwSyncError: true },
        throwJsErrors,
      });
      expect(jsonChunks.length).toBeGreaterThanOrEqual(1);
      expect(jsonChunks.length).toBeLessThanOrEqual(4);

      const chunksWithError = jsonChunks.filter((chunk) => chunk.hasErrors);
      expect(chunksWithError).toHaveLength(1);
      expect(chunksWithError[0].renderingError.message).toMatch(
        /Sync error from AsyncComponentsTreeForTesting/,
      );
      expect(chunksWithError[0].html).toMatch(/Sync error from AsyncComponentsTreeForTesting/);
      expect(chunksWithError[0].isShellReady).toBeTruthy();
      expect(status).toBe(200);
    },
    10000,
  );

  it("shouldn't notify error reporter when throwJsErrors is false and shell error happens", async () => {
    await makeRequest({
      props: { throwSyncError: true },
      // throwJsErrors is false by default
    });
    expect(errorReporter.message).not.toHaveBeenCalled();
  }, 10000);

  it('should notify error reporter when throwJsErrors is true and shell error happens', async () => {
    await makeRequest({
      props: { throwSyncError: true },
      throwJsErrors: true,
    });
    // Reporter is called twice: once for the error occured at RSC vm and the other while rendering the errornous rsc payload
    expect(errorReporter.message).toHaveBeenCalledTimes(2);
    expect(errorReporter.message).toHaveBeenCalledWith(
      expect.stringMatching(
        /Error in a rendering stream[\s\S.]*Sync error from AsyncComponentsTreeForTesting/,
      ),
    );
  }, 10000);

  it.each([true, false])(
    'should keep rendering other suspense boundaries if error happen in one of them (throwJsErrors: %s)',
    async (throwJsErrors) => {
      const { status, chunks, fullBody, jsonChunks } = await makeRequest({
        props: { throwAsyncError: true },
        throwJsErrors,
      });
      expect(chunks.length).toBeGreaterThan(5);
      expect(status).toBe(200);

      expect(chunks[0]).toContain('<p>Header for AsyncComponentsTreeForTesting</p>');
      expect(fullBody).toContain('branch1 (level 4)');
      expect(fullBody).toContain('branch1 (level 3)');
      expect(fullBody).toContain('branch1 (level 2)');
      expect(fullBody).toContain('branch1 (level 1)');
      expect(fullBody).toContain('branch1 (level 0)');
      expect(fullBody).toContain('branch2 (level 1)');
      expect(fullBody).toContain('branch2 (level 0)');

      expect(jsonChunks[0].isShellReady).toBeTruthy();
      expect(jsonChunks[0].hasErrors).toBeTruthy();
      expect(jsonChunks[0].renderingError).toMatchObject({
        message: 'Async error from AsyncHelloWorldHooks',
        stack: expect.stringMatching(
          /Error: Async error from AsyncHelloWorldHooks\s*at AsyncHelloWorldHooks/,
        ),
      });
      expect(jsonChunks.slice(1).some((chunk) => chunk.hasErrors)).toBeFalsy();
      expect(jsonChunks.slice(1).some((chunk) => chunk.renderingError)).toBeFalsy();
    },
    10000,
  );

  it('should not notify error reporter when throwJsErrors is false and async error happens', async () => {
    await makeRequest({
      props: { throwAsyncError: true },
      throwJsErrors: false,
    });
    expect(errorReporter.message).not.toHaveBeenCalled();
  }, 10000);

  it('should notify error reporter when throwJsErrors is true and async error happens', async () => {
    await makeRequest({
      props: { throwAsyncError: true },
      throwJsErrors: true,
    });
    // Reporter is called twice: once for the error occured at RSC vm and the other while rendering the errornous rsc payload
    expect(errorReporter.message).toHaveBeenCalledTimes(2);
    expect(errorReporter.message).toHaveBeenCalledWith(
      expect.stringMatching(/Error in a rendering stream[\s\S.]*Async error from AsyncHelloWorldHooks/),
    );
  }, 10000);
});
