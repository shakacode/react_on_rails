import fs from 'fs';
import path from 'path';
import http2 from 'http2';
import FormData from 'form-data';
import buildApp from '../src/worker';
import { readRenderingRequest } from './helper';
import packageJson from '../src/shared/packageJson';

export const SERVER_BUNDLE_TIMESTAMP = '77777-test';
// Ensure to match the rscBundleHash at `asyncComponentsTreeForTestingRenderingRequest.js` fixture
export const RSC_BUNDLE_TIMESTAMP = '88888-test';

type RequestOptions = {
  project: string;
  commit: string;
  props: Record<string, unknown>;
  throwJsErrors: boolean;
  componentName: string;
  renderRscPayload: boolean;
};

export const createForm = ({
  project = 'spec-dummy',
  commit = '',
  props = {},
  throwJsErrors = false,
  componentName = undefined,
}: Partial<RequestOptions> = {}) => {
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
  const componentNameString = componentName ? `'${componentName}'` : String(undefined);
  renderingRequestCode = renderingRequestCode.replace(
    /\(\s*\)\s*$/,
    `(${componentNameString}, ${JSON.stringify(props)})`,
  );
  if (throwJsErrors) {
    renderingRequestCode = renderingRequestCode.replace('throwJsErrors: false', 'throwJsErrors: true');
  }
  form.append('renderingRequest', renderingRequestCode);

  const testBundlesDirectory = path.join(__dirname, '../../../react_on_rails_pro/spec/dummy/ssr-generated');
  const testClientBundlesDirectory = path.join(__dirname, '../../../react_on_rails_pro/spec/dummy/public/webpack/test');
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
  const clientManifestPath = path.join(testClientBundlesDirectory, 'react-client-manifest.json');
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

const getAppUrl = (app: ReturnType<typeof buildApp>) => {
  const addresssInfo = app.server.address();
  if (!addresssInfo) {
    throw new Error('The app has no address, ensure to run the app before running tests');
  }

  if (typeof addresssInfo === 'string') {
    return addresssInfo;
  }

  return `http://localhost:${addresssInfo.port}`;
};

export const makeRequest = (app: ReturnType<typeof buildApp>, options: Partial<RequestOptions> = {}) => {
  const form = createForm(options);
  const client = http2.connect(getAppUrl(app));
  const usedBundleTimestamp = options.renderRscPayload ? RSC_BUNDLE_TIMESTAMP : SERVER_BUNDLE_TIMESTAMP;
  const request = client.request({
    ':method': 'POST',
    ':path': `/bundles/${usedBundleTimestamp}/render/454a82526211afdb215352755d36032c`,
    'content-type': `multipart/form-data; boundary=${form.getBoundary()}`,
  });
  request.setEncoding('utf8');

  const buffer: string[] = [];

  const statusPromise = new Promise<number | undefined>((resolve) => {
    request.on('response', (headers) => {
      resolve(headers[':status']);
    });
  });

  let resolveChunksPromise: ((chunks: string) => void) | undefined;
  let rejectChunksPromise: ((error: unknown) => void) | undefined;
  let resolveChunkPromiseTimeout: NodeJS.Timeout | undefined;

  const scheduleResolveChunkPromise = () => {
    if (resolveChunkPromiseTimeout) {
      clearTimeout(resolveChunkPromiseTimeout);
    }

    resolveChunkPromiseTimeout = setTimeout(() => {
      resolveChunksPromise?.(buffer.join(''));
      resolveChunksPromise = undefined;
      rejectChunksPromise = undefined;
      buffer.length = 0;
    }, 1000);
  };

  request.on('data', (data: Buffer) => {
    buffer.push(data.toString());
    if (resolveChunksPromise) {
      scheduleResolveChunkPromise();
    }
  });

  form.pipe(request);
  form.on('end', () => {
    request.end();
  });

  const rejectPendingChunkPromise = () => {
    if (rejectChunksPromise && buffer.length === 0) {
      rejectChunksPromise('Request already eneded');
    }
  };

  const finishedPromise = new Promise<void>((resolve, reject) => {
    request.on('end', () => {
      client.destroy();
      resolve();
      rejectPendingChunkPromise();
    });
    request.on('error', (err) => {
      client.destroy();
      reject(err instanceof Error ? err : new Error(String(err)));
      rejectPendingChunkPromise();
    });
  });

  const waitForNextChunk = () =>
    new Promise<string>((resolve, reject) => {
      if (client.closed && buffer.length === 0) {
        reject(new Error('Request already eneded'));
      }
      resolveChunksPromise = resolve;
      rejectChunksPromise = reject;
      if (buffer.length > 0) {
        scheduleResolveChunkPromise();
      }
    });

  const getBuffer = () => [...buffer];

  return {
    statusPromise,
    finishedPromise,
    waitForNextChunk,
    getBuffer,
  };
};
