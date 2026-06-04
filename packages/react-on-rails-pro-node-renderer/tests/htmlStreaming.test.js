import http2 from 'http2';
import buildApp from '../src/worker';
import { createTestConfig } from './testingNodeRendererConfigs';
import * as errorReporter from '../src/shared/errorReporter';
import { createForm, SERVER_BUNDLE_TIMESTAMP } from './httpRequestUtils';
import { LengthPrefixedStreamParser } from './parseLengthPrefixedStream';

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

const SHELL_HEADER = '<p>Header for AsyncComponentsTreeForTesting</p>';
const SHELL_FOOTER = '<p>Footer for AsyncComponentsTreeForTesting</p>';

const findShellChunkIndex = (chunks) => {
  const shellChunkIndex = chunks.findIndex((chunk) => chunk.includes(SHELL_HEADER));
  expect(shellChunkIndex).toBeGreaterThanOrEqual(0);
  return shellChunkIndex;
};

const findShellChunk = (chunks) => chunks[findShellChunkIndex(chunks)];

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

  const parser = new LengthPrefixedStreamParser();
  let firstByteTime;
  let status;

  request.on('response', (headers) => {
    status = headers[':status'];
  });

  request.on('data', (data) => {
    parser.feed(data);
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
  const { htmlChunks: chunks, parsedChunks: jsonChunks } = parser;
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

  it('should stream the component shell with suspense fallbacks', async () => {
    const { status, chunks } = await makeRequest();
    expect(status).toBe(200);

    // React 19 can flush an initial Suspense marker before the shell HTML.
    const shellChunk = findShellChunk(chunks);

    expect(shellChunk).toContain(SHELL_HEADER);
    expect(shellChunk).toContain(SHELL_FOOTER);
    expect(shellChunk).toContain('Loading HelloWorldHooks...');
    expect(shellChunk).toContain('Loading branch1...');
    expect(shellChunk).toContain('Loading branch2...');
  }, 10000);

  it('should stream chunks one by one', async () => {
    const { status, chunks } = await makeRequest();
    expect(status).toBe(200);

    // Strip <script> tags from the chunk before checking for rendered HTML.
    // RSC Flight payload <script> tags contain the serialized React tree which
    // includes fallback text as data (e.g., "Loading branch1..." inside a JSON
    // string). We only want to assert that the fallback is not rendered as HTML.
    // Note: the `i` flag and per-tag matching keep CodeQL's bad-tag-filter and
    // incomplete-multi-character-sanitization rules happy; this is test-only
    // string scrubbing for assertions, not security sanitization.
    // lgtm[js/incomplete-multi-character-sanitization]
    // lgtm[js/bad-tag-filter]
    const shellChunkIndex = findShellChunkIndex(chunks);
    expect(chunks.length).toBeGreaterThan(shellChunkIndex + 1);

    let nextChunkHtml = chunks[shellChunkIndex + 1];
    let prev;
    do {
      prev = nextChunkHtml;
      nextChunkHtml = nextChunkHtml.replace(/<script\b[^>]*>[\s\S]*?<\/script\s*>/gi, '');
    } while (prev !== nextChunkHtml);
    expect(nextChunkHtml).not.toContain(SHELL_HEADER);
    expect(nextChunkHtml).not.toContain(SHELL_FOOTER);
    expect(nextChunkHtml).not.toContain('Loading branch1...');
    expect(nextChunkHtml).not.toContain('Loading branch2...');
    expect(nextChunkHtml).not.toContain('branch1 (level 0)');
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

      expect(findShellChunk(chunks)).toContain(SHELL_HEADER);
      expect(fullBody).toContain('branch1 (level 4)');
      expect(fullBody).toContain('branch1 (level 3)');
      expect(fullBody).toContain('branch1 (level 2)');
      expect(fullBody).toContain('branch1 (level 1)');
      expect(fullBody).toContain('branch1 (level 0)');
      expect(fullBody).toContain('branch2 (level 1)');
      expect(fullBody).toContain('branch2 (level 0)');

      const chunksWithError = jsonChunks.filter((chunk) => chunk.hasErrors);
      expect(chunksWithError).toHaveLength(1);
      expect(chunksWithError[0].isShellReady).toBeTruthy();
      expect(chunksWithError[0].renderingError).toMatchObject({
        message: 'Async error from AsyncHelloWorldHooks',
        stack: expect.stringMatching(
          /Error: Async error from AsyncHelloWorldHooks\s*at AsyncHelloWorldHooks/,
        ),
      });
      expect(jsonChunks.filter((chunk) => chunk.renderingError)).toHaveLength(1);
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
