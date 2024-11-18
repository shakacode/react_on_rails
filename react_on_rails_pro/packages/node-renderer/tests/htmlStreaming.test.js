import fs from 'fs';
import http2 from 'http2';
import path from 'path';
import FormData from 'form-data';
import buildApp from '../src/worker';
import config from './testingNodeRendererConfigs';
import { readRenderingRequest } from './helper';
import errorReporter from '../src/shared/errorReporter';

const app = buildApp(config);

beforeAll(async () => {
  await app.ready();
  await app.listen({ port: 0 });
});

afterAll(async () => {
  await app.close();
});

jest.spyOn(errorReporter, 'notify').mockImplementation(jest.fn());

const createForm = ({
  project = 'spec-dummy',
  commit = '220f7a3',
  useTestBundle = true,
  props = {},
  throwJsErrors = false,
} = {}) => {
  const form = new FormData();
  form.append('gemVersion', '4.0.0.rc.5');
  form.append('protocolVersion', '1.0.0');
  form.append('password', 'myPassword1');

  let renderingRequestCode = readRenderingRequest(
    project,
    commit,
    'asyncComponentsTreeForTestingRenderingRequest.js',
  );
  renderingRequestCode = renderingRequestCode.replace(
    'props: props,',
    `props: { ...props, ...{${Object.entries(props)
      .map(([key, value]) => `${key}: ${JSON.stringify(value)}`)
      .join(', ')}} },`,
  );
  if (throwJsErrors) {
    renderingRequestCode = renderingRequestCode.replace('throwJsErrors: false', 'throwJsErrors: true');
  }
  form.append('renderingRequest', renderingRequestCode);

  const bundlePath = useTestBundle
    ? '../../../spec/dummy/public/webpack/test/server-bundle.js'
    : `./fixtures/projects/${project}/${commit}/server-bundle-web-target.js`;
  form.append('bundle', fs.createReadStream(path.join(__dirname, bundlePath)), {
    contentType: 'text/javascript',
    filename: 'server-bundle.js',
  });

  return form;
};

const makeRequest = async (options = {}) => {
  const useTestBundle = options.useTestBundle ?? true;
  const startTime = Date.now();
  const form = createForm(options);
  const bundleHash = useTestBundle ? '77777' : '88888';
  const { address, port } = app.server.address();
  const client = http2.connect(`http://${address}:${port}`);
  const request = client.request({
    ':method': 'POST',
    ':path': `/bundles/${bundleHash}/render/454a82526211afdb215352755d36032c`,
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

    expect(timeToFirstByte).toBeLessThan(1000);
    expect(streamingTime).toBeGreaterThan(3500);
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
    'should stop rendering when an error happen in the shell and renders the error (throwJsErrors: %s)',
    async (throwJsErrors) => {
      const { status, chunks } = await makeRequest({
        props: { throwSyncError: true },
        useTestBundle: true,
        throwJsErrors,
      });
      expect(chunks).toHaveLength(1);
      expect(chunks[0]).toMatch(
        /<pre>Exception in rendering[\s\S.]*Sync error from AsyncComponentsTreeForTesting[\s\S.]*<\/pre>/,
      );
      expect(status).toBe(200);
    },
    10000,
  );

  it("shouldn't notify error reporter when throwJsErrors is false and shell error happens", async () => {
    await makeRequest({
      props: { throwSyncError: true },
      useTestBundle: true,
      // throwJsErrors is false by default
    });
    expect(errorReporter.notify).not.toHaveBeenCalled();
  }, 10000);

  it('should notify error reporter when throwJsErrors is true and shell error happens', async () => {
    await makeRequest({
      props: { throwSyncError: true },
      useTestBundle: true,
      throwJsErrors: true,
    });
    expect(errorReporter.notify).toHaveBeenCalledTimes(1);
    expect(errorReporter.notify).toHaveBeenCalledWith(
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
        useTestBundle: true,
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

      expect(jsonChunks[0].hasErrors).toBeFalsy();
      // All chunks after the first one should have errors
      expect(jsonChunks.slice(1).every((chunk) => chunk.hasErrors)).toBeTruthy();
    },
    10000,
  );

  it('should not notify error reporter when throwJsErrors is false and async error happens', async () => {
    await makeRequest({
      props: { throwAsyncError: true },
      useTestBundle: true,
      throwJsErrors: false,
    });
    expect(errorReporter.notify).not.toHaveBeenCalled();
  }, 10000);

  it('should notify error reporter when throwJsErrors is true and async error happens', async () => {
    await makeRequest({
      props: { throwAsyncError: true },
      useTestBundle: true,
      throwJsErrors: true,
    });
    expect(errorReporter.notify).toHaveBeenCalledTimes(1);
    expect(errorReporter.notify).toHaveBeenCalledWith(
      expect.stringMatching(/Error in a rendering stream[\s\S.]*Async error from AsyncHelloWorldHooks/),
    );
  }, 10000);
});
