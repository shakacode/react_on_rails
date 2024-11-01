import fs from 'fs';
import path from 'path';
// import FormData from "form-data";
// import fetch from 'node-fetch';
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

const createForm = async ({
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
  const bundleContent = await fs.readFileSync(path.join(__dirname, bundlePath));
  const bundleBlob = new Blob([bundleContent], { type: 'text/javascript' });
  form.append('bundle', bundleBlob, 'server-bundle.js');

  return form;
};

const makeRequest = async (options = {}) => {
  const useTestBundle = options.useTestBundle ?? true;
  const startTime = Date.now();
  const form = await createForm(options);
  const bundleHash = useTestBundle ? '77777' : '88888';
  const response = await fetch(
    `http://localhost:${app.server.address().port}/bundles/${bundleHash}/render/454a82526211afdb215352755d36032c`,
    {
      method: 'POST',
      body: form,
    },
  );

  const chunks = [];
  const jsonChunks = [];
  const reader = response.body.getReader();
  let done;
  let value;
  let firstByteTime;
  const decoder = new TextDecoder();

  while (!done) {
    // eslint-disable-next-line no-await-in-loop
    ({ done, value } = await reader.read());
    if (value) {
      // Sometimes, multiple chunks are merged together.
      // So, the server use \n as a delimiter between chunks.
      const decodedValue = decoder.decode(value, { stream: false });
      const decodedValuesIfMultipleMerged = decodedValue
        .split('\n')
        .map((chunk) => chunk.trim())
        .filter((chunk) => chunk.length > 0);
      chunks.push(...decodedValuesIfMultipleMerged);
      jsonChunks.push(...decodedValuesIfMultipleMerged.map((chunk) => JSON.parse(chunk)));
      if (!firstByteTime) {
        firstByteTime = Date.now();
      }
    }
  }

  const endTime = Date.now();
  const fullBody = chunks.join('');
  const timeToFirstByte = firstByteTime - startTime;
  const streamingTime = endTime - firstByteTime;

  return { response, chunks, fullBody, timeToFirstByte, streamingTime, jsonChunks };
};

describe('html streaming', () => {
  it("should send each html chunk immediately when it's ready", async () => {
    const { response, timeToFirstByte, streamingTime, chunks } = await makeRequest();
    expect(response.status).toBe(200);
    expect(chunks.length).toBeGreaterThanOrEqual(5);

    expect(timeToFirstByte).toBeLessThan(1000);
    expect(streamingTime).toBeGreaterThan(3500);
  }, 10000);

  it('should returns the component shell only in the first chunk', async () => {
    const { response, chunks } = await makeRequest();
    expect(response.status).toBe(200);

    const firstChunk = chunks[0];

    expect(firstChunk).toContain('<p>Header for AsyncComponentsTreeForTesting</p>');
    expect(firstChunk).toContain('<p>Footer for AsyncComponentsTreeForTesting</p>');
    expect(firstChunk).toContain('Loading HelloWorldHooks...');
    expect(firstChunk).toContain('Loading branch1...');
    expect(firstChunk).toContain('Loading branch2...');
  }, 10000);

  it('should stream chunks one by one', async () => {
    const { response, chunks } = await makeRequest();
    expect(response.status).toBe(200);

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
      const { response, chunks } = await makeRequest({
        props: { throwSyncError: true },
        useTestBundle: true,
        throwJsErrors,
      });
      expect(chunks).toHaveLength(1);
      expect(chunks[0]).toMatch(
        /<pre>Exception in rendering[\s\S.]*Sync error from AsyncComponentsTreeForTesting[\s\S.]*<\/pre>/,
      );
      expect(response.status).toBe(200);
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
      const { response, chunks, fullBody, jsonChunks } = await makeRequest({
        props: { throwAsyncError: true },
        useTestBundle: true,
        throwJsErrors,
      });
      expect(chunks.length).toBeGreaterThan(5);
      expect(response.status).toBe(200);

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
