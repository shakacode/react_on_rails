import fs from 'fs';
import path from 'path';
// import FormData from "form-data";
// import fetch from 'node-fetch';
import buildApp from '../src/worker';
import config from './testingNodeRendererConfigs';
import { readRenderingRequest } from './helper';

const app = buildApp(config);

beforeAll(async () => {
  await app.ready();
  await app.listen({ port: 0 });
});

afterAll(async () => {
  await app.close();
});

const createForm = async () => {
  const form = new FormData();
  form.append('gemVersion', '4.0.0.rc.5');
  form.append('protocolVersion', '1.0.0');
  form.append('password', 'myPassword1');

  const project = 'spec-dummy';
  const commit = '220f7a3';
  const renderingRequestCode = readRenderingRequest(
    project,
    commit,
    'asyncComponentsTreeForTestingRenderingRequest.js',
  );
  form.append('renderingRequest', renderingRequestCode);

  const bundleContent = await fs.readFileSync(
    path.join(__dirname, './fixtures/projects/spec-dummy/220f7a3/server-bundle-web-target.js'),
  );
  const bundleBlob = new Blob([bundleContent], { type: 'text/javascript' });
  form.append('bundle', bundleBlob, 'server-bundle.js');

  return form;
};

const makeRequest = async () => {
  const startTime = Date.now();
  const form = await createForm();
  const response = await fetch(
    `http://localhost:${app.server.address().port}/bundles/708d3326f1377c183808bb3f4914a598/render/454a82526211afdb215352755d36032c`,
    {
      method: 'POST',
      body: form,
    },
  );

  const chunks = [];
  const reader = response.body.getReader();
  let done;
  let value;
  let firstByteTime;
  const decoder = new TextDecoder();

  while (!done) {
    // eslint-disable-next-line no-await-in-loop
    ({ done, value } = await reader.read());
    if (value) {
      chunks.push(decoder.decode(value, { stream: true }));
      if (!firstByteTime) {
        firstByteTime = Date.now();
      }
    }
  }

  const endTime = Date.now();
  const fullBody = chunks.join('');
  const timeToFirstByte = firstByteTime - startTime;
  const streamingTime = endTime - firstByteTime;

  return { response, chunks, fullBody, timeToFirstByte, streamingTime };
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
});
