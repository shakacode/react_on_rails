import fs from 'fs';
import http2 from 'http2';
import path from 'path';
import FormData from 'form-data';
import buildApp from '../src/worker';
import config from './testingNodeRendererConfigs';
import { readRenderingRequest } from './helper';
import * as errorReporter from '../src/shared/errorReporter';
import packageJson from '../src/shared/packageJson';

const app = buildApp(config);

beforeAll(async () => {
  await app.ready();
  await app.listen({ port: 0 });
});

afterAll(async () => {
  await app.close();
});

jest.spyOn(errorReporter, 'message').mockImplementation(jest.fn());

const SERVER_BUNDLE_TIMESTAMP = '77777-test';
// Ensure to match the rscBundleHash at `asyncComponentsTreeForTestingRenderingRequest.js` fixture
const RSC_BUNDLE_TIMESTAMP = '88888-test';

const createForm = ({ project = 'spec-dummy', commit = '', props = {}, throwJsErrors = false } = {}) => {
  const form = new FormData();
  form.append('gemVersion', packageJson.version);
  form.append('protocolVersion', packageJson.protocolVersion);
  form.append('password', 'myPassword1');
  form.append('dependencyBundleTimestamps[]', RSC_BUNDLE_TIMESTAMP);

  let renderingRequestCode = readRenderingRequest(
    project,
    commit,
    'asyncComponentsTreeForTestingRenderingRequest.js',
  );
  renderingRequestCode = renderingRequestCode.replace(/\(\s*\)\s*$/, `(undefined, ${JSON.stringify(props)})`);
  if (throwJsErrors) {
    renderingRequestCode = renderingRequestCode.replace('throwJsErrors: false', 'throwJsErrors: true');
  }
  form.append('renderingRequest', renderingRequestCode);

  const testBundlesDirectory = path.join(__dirname, '../../../spec/dummy/public/webpack/test');
  const bundlePath = path.join(testBundlesDirectory, 'server-bundle.js');
  form.append(`bundle_${SERVER_BUNDLE_TIMESTAMP}`, fs.createReadStream(bundlePath), {
    contentType: 'text/javascript',
    filename: 'server-bundle.js',
  });
  const rscBundlePath = path.join(testBundlesDirectory, 'rsc-bundle.js');
  form.append(`bundle_${RSC_BUNDLE_TIMESTAMP}`, fs.createReadStream(rscBundlePath), {
    contentType: 'text/javascript',
    filename: 'rsc-bundle.js',
  });
  const clientManifestPath = path.join(testBundlesDirectory, 'react-client-manifest.json');
  form.append('asset1', fs.createReadStream(clientManifestPath), {
    contentType: 'application/json',
    filename: 'react-client-manifest.json',
  });
  const reactServerClientManifestPath = path.join(testBundlesDirectory, 'react-server-client-manifest.json');
  form.append('asset2', fs.createReadStream(reactServerClientManifestPath), {
    contentType: 'application/json',
    filename: 'react-server-client-manifest.json',
  });

  return form;
};

const makeRequest = async (options = {}) => {
  const startTime = Date.now();
  const form = createForm(options);
  const { address, port } = app.server.address();
  const client = http2.connect(`http://${address}:${port}`);
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
  const decoder = new TextDecoder();

  request.on('response', (headers) => {
    status = headers[':status'];
  });

  request.on('data', (data) => {
    // Sometimes, multiple chunks are merged into one.
    // So, the server uses \n as a delimiter between chunks.
    const decodedData = typeof data === 'string' ? data : decoder.decode(data, { stream: false });
    const decodedChunksFromData = decodedData
      .split('\n')
      .map((chunk) => chunk.trim())
      .filter((chunk) => chunk.length > 0);
    chunks.push(...decodedChunksFromData);
    jsonChunks.push(
      ...decodedChunksFromData.map((chunk) => {
        try {
          return JSON.parse(chunk);
        } catch (e) {
          return { hasErrors: true, error: `JSON parsing failed: ${e.message}` };
        }
      }),
    );
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
