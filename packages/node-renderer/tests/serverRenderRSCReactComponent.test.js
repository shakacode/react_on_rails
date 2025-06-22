import path from 'path';
import { Readable } from 'stream';
import { buildVM, getVMContext, resetVM } from '../src/worker/vm';
import { getConfig } from '../src/shared/configBuilder';

const SimpleWorkingComponent = () => 'hello';

const ComponentWithSyncError = () => {
  throw new Error('Sync error');
};

const ComponentWithAsyncError = async () => {
  await new Promise((resolve) => {
    setTimeout(resolve, 0);
  });
  throw new Error('Async error');
};

describe('serverRenderRSCReactComponent', () => {
  beforeEach(async () => {
    const config = getConfig();
    config.supportModules = true;
    config.maxVMPoolSize = 2; // Set a small pool size for testing
    config.stubTimers = false;
  });

  afterEach(async () => {
    resetVM();
  });

  // The serverRenderRSCReactComponent function should only be called when the bundle is compiled with the `react-server` condition.
  // Therefore, we cannot call it directly in the test files. Instead, we run the RSC bundle through the VM and call the method from there.
  const getReactOnRailsRSCObject = async () => {
    const testBundlesDirectory = path.join(__dirname, '../../../spec/dummy/public/webpack/test');
    const rscBundlePath = path.join(testBundlesDirectory, 'rsc-bundle.js');
    await buildVM(rscBundlePath);
    const vmContext = getVMContext(rscBundlePath);
    const { ReactOnRails, React } = vmContext.context;

    function SuspensedComponentWithAsyncError() {
      return React.createElement('div', null, [
        React.createElement('div', null, 'Hello'),
        React.createElement(
          React.Suspense,
          {
            fallback: React.createElement('div', null, 'Loading Async Component...'),
          },
          React.createElement(ComponentWithAsyncError),
        ),
      ]);
    }

    ReactOnRails.register({
      SimpleWorkingComponent,
      ComponentWithSyncError,
      ComponentWithAsyncError,
      SuspensedComponentWithAsyncError,
    });

    return ReactOnRails;
  };

  const renderComponent = async (componentName, throwJsErrors = false) => {
    const ReactOnRails = await getReactOnRailsRSCObject();
    return ReactOnRails.serverRenderRSCReactComponent({
      name: componentName,
      props: {},
      throwJsErrors,
      railsContext: {
        serverSide: true,
        reactClientManifestFileName: 'react-client-manifest.json',
        reactServerClientManifestFileName: 'react-server-client-manifest.json',
        componentSpecificMetadata: { renderRequestId: '123' },
        renderingReturnsPromises: true,
      },
    });
  };

  it('ReactOnRails should be defined and have serverRenderRSCReactComponent method', async () => {
    const result = await getReactOnRailsRSCObject();
    expect(result).toBeDefined();
    expect(typeof result.serverRenderRSCReactComponent).toBe('function');
  });

  // Add these helper functions at the top of the describe block
  const getStreamContent = async (stream) => {
    let content = '';
    stream.on('data', (chunk) => {
      content += chunk.toString();
    });

    await new Promise((resolve) => {
      stream.on('end', resolve);
    });

    return content;
  };

  const expectStreamContent = async (stream, expectedContents, options = {}) => {
    const { throwJsErrors, expectedError } = options;
    expect(stream).toBeDefined();
    expect(stream).toBeInstanceOf(Readable);

    const onError = throwJsErrors ? jest.fn() : null;
    if (onError) {
      stream.on('error', onError);
    }

    const content = await getStreamContent(stream);

    if (expectedError) {
      expect(onError).toHaveBeenCalled();
      expect(onError).toHaveBeenCalledWith(new Error(expectedError));
    }

    expectedContents.forEach((text) => {
      expect(content).toContain(text);
    });
  };

  it('should returns stream with content when the component renders successfully', async () => {
    const result = await renderComponent('SimpleWorkingComponent');
    await expectStreamContent(result, ['hello']);
  });

  it('should returns stream with error when the component throws a sync error', async () => {
    const result = await renderComponent('ComponentWithSyncError');
    await expectStreamContent(result, ['Sync error']);
  });

  it('should emit an error when the component throws a sync error and throwJsErrors is true', async () => {
    const result = await renderComponent('ComponentWithSyncError', true);
    await expectStreamContent(result, ['Sync error'], {
      throwJsErrors: true,
      expectedError: 'Sync error',
    });
  });

  it('should emit an error when the component throws an async error and throwJsErrors is true', async () => {
    const result = await renderComponent('ComponentWithAsyncError', true);
    await expectStreamContent(result, ['Async error'], { throwJsErrors: true, expectedError: 'Async error' });
  });

  it('should render a suspense component with an async error', async () => {
    const result = await renderComponent('SuspensedComponentWithAsyncError');
    await expectStreamContent(result, ['Loading Async Component...', 'Hello', 'Async error']);
  });

  it('emits an error when the suspense component throws an async error and throwJsErrors is true', async () => {
    const result = await renderComponent('SuspensedComponentWithAsyncError', true);
    await expectStreamContent(result, ['Loading Async Component...', 'Hello', 'Async error'], {
      throwJsErrors: true,
      expectedError: 'Async error',
    });
  });
});
