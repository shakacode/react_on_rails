import http2 from 'http2';
import buildApp from '../src/worker';
import { createTestConfig } from './testingNodeRendererConfigs';
import * as errorReporter from '../src/shared/errorReporter';
import {
  createRenderingRequest,
  createUploadAssetsForm,
  getAppUrl,
  getNextChunk,
  RSC_BUNDLE_TIMESTAMP,
  SERVER_BUNDLE_TIMESTAMP,
} from './httpRequestUtils';
import packageJson from '../src/shared/packageJson';

const { config } = createTestConfig('incrementalHtmlStreaming');
const app = buildApp(config);

beforeAll(async () => {
  await app.ready();
  await app.listen({ port: 0 });
});

afterAll(async () => {
  await app.close();
});

jest.spyOn(errorReporter, 'message').mockImplementation(jest.fn());

const createHttpRequest = (bundleTimestamp: string = SERVER_BUNDLE_TIMESTAMP, pathSuffix = 'abc123') => {
  const appUrl = getAppUrl(app);
  const client = http2.connect(appUrl);
  const request = client.request({
    ':method': 'POST',
    ':path': `/bundles/${bundleTimestamp}/incremental-render/${pathSuffix}`,
    'content-type': 'application/x-ndjson',
  });
  request.setEncoding('utf8');
  return {
    request,
    close: () => {
      client.close();
    },
  };
};

const createInitialObject = (bundleTimestamp: string = RSC_BUNDLE_TIMESTAMP, password = 'myPassword1') => ({
  gemVersion: packageJson.version,
  protocolVersion: packageJson.protocolVersion,
  password,
  renderingRequest: createRenderingRequest({ componentName: 'AsyncPropsComponent' }),
  onRequestClosedUpdateChunk: {
    bundleTimestamp: RSC_BUNDLE_TIMESTAMP,
    updateChunk: `
    (function(){
      var asyncPropsManager = sharedExecutionContext.get("asyncPropsManager");
      asyncPropsManager.endStream();
    })()
    `,
  },
  dependencyBundleTimestamps: [bundleTimestamp],
});

const makeRequest = async (options = {}) => {
  const form = createUploadAssetsForm(options);
  const appUrl = getAppUrl(app);
  const client = http2.connect(appUrl);
  const request = client.request({
    ':method': 'POST',
    ':path': `/upload-assets`,
    'content-type': `multipart/form-data; boundary=${form.getBoundary()}`,
  });
  request.setEncoding('utf8');

  let status: number | undefined;
  let body = '';

  request.on('response', (headers) => {
    status = headers[':status'];
  });

  request.on('data', (data: Buffer) => {
    body += data.toString();
  });

  form.pipe(request);
  form.on('end', () => {
    request.end();
  });

  await new Promise<void>((resolve, reject) => {
    request.on('end', () => {
      client.close();
      resolve();
    });
    request.on('error', (err) => {
      client.close();
      reject(err instanceof Error ? err : new Error(String(err)));
    });
  });

  return {
    status,
    body,
  };
};

const waitForStatus = (request: http2.ClientHttp2Stream) =>
  new Promise<number | undefined>((resolve) => {
    request.on('response', (headers) => {
      resolve(headers[':status']);
    });
  });

it('uploads the bundles', async () => {
  const { status, body } = await makeRequest();
  expect(body).toBe('');
  expect(status).toBe(200);
});

it('incremental render html', async () => {
  const { status, body } = await makeRequest();
  expect(body).toBe('');
  expect(status).toBe(200);

  const { request, close } = createHttpRequest();
  const initialRequestObject = createInitialObject();
  request.write(`${JSON.stringify(initialRequestObject)}\n`);

  await expect(waitForStatus(request)).resolves.toBe(200);
  await expect(getNextChunk(request)).resolves.toContain('AsyncPropsComponent is a renderFunction');

  const updateChunk = {
    bundleTimestamp: RSC_BUNDLE_TIMESTAMP,
    updateChunk: `
    (function(){
    var asyncPropsManager = sharedExecutionContext.get("asyncPropsManager");
    asyncPropsManager.setProp("books", ["Tale of two towns", "Pro Git"]);
    })()
    `,
  };
  request.write(`${JSON.stringify(updateChunk)}\n`);
  await expect(getNextChunk(request)).resolves.toContain('Tale of two towns');

  const updateChunk2 = {
    bundleTimestamp: RSC_BUNDLE_TIMESTAMP,
    updateChunk: `
    (function(){
    var asyncPropsManager = sharedExecutionContext.get("asyncPropsManager");
    asyncPropsManager.setProp("researches", ["AI effect on productivity", "Pro Git"]);
    })()
    `,
  };
  request.write(`${JSON.stringify(updateChunk2)}\n`);
  request.end();
  await expect(getNextChunk(request)).resolves.toContain('AI effect on productivity');

  await expect(getNextChunk(request)).rejects.toThrow('Stream Closed');
  close();
});

it('raises an error if a specific async prop is not sent', async () => {
  const { status, body } = await makeRequest();
  expect(body).toBe('');
  expect(status).toBe(200);

  const { request, close } = createHttpRequest();
  const initialRequestObject = createInitialObject();
  request.write(`${JSON.stringify(initialRequestObject)}\n`);

  await expect(waitForStatus(request)).resolves.toBe(200);
  await expect(getNextChunk(request)).resolves.toContain('AsyncPropsComponent is a renderFunction');

  request.end();
  await expect(getNextChunk(request)).resolves.toContain(
    'The async prop \\"researches\\" is not received. Esnure to send the async prop from ruby side',
  );

  await expect(getNextChunk(request)).rejects.toThrow('Stream Closed');
  close();
});

describe('concurrent incremental HTML streaming', () => {
  it('handles multiple parallel requests without race conditions', async () => {
    await makeRequest();

    const numRequests = 5;
    const requests = [];

    // Start all requests
    for (let i = 0; i < numRequests; i += 1) {
      const { request, close } = createHttpRequest(RSC_BUNDLE_TIMESTAMP, `concurrent-test-${i}`);
      request.write(`${JSON.stringify(createInitialObject())}\n`);
      requests.push({ request, close, id: i });
    }

    // Wait for all to connect and get initial chunks
    await Promise.all(requests.map(({ request }) => waitForStatus(request)));
    await Promise.all(requests.map(({ request }) => getNextChunk(request)));

    // Send update chunks to ALL requests before waiting for any responses
    // If sequential: second request wouldn't process until first completes
    // If concurrent: all process simultaneously
    requests.forEach(({ request, id }) => {
      request.write(
        `${JSON.stringify({
          bundleTimestamp: RSC_BUNDLE_TIMESTAMP,
          updateChunk: `
          (function(){
            var asyncPropsManager = sharedExecutionContext.get("asyncPropsManager");
            asyncPropsManager.setProp("books", ["Request-${id}-Book"]);
            asyncPropsManager.setProp("researches", ["Request-${id}-Research"]);
          })()
          `,
        })}\n`,
      );
      request.end();
    });

    // Now wait for all responses - they should all succeed
    const results = await Promise.all(
      requests.map(async ({ request, close, id }) => {
        const chunk = await getNextChunk(request);
        close();
        return { id, chunk };
      }),
    );

    results.forEach(({ id, chunk }) => {
      expect(chunk).toContain(`Request-${id}-Book`);
      expect(chunk).toContain(`Request-${id}-Research`);
    });
  });
});
