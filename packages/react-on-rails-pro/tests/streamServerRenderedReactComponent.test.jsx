/**
 * @jest-environment node
 */

import * as React from 'react';
import * as PropTypes from 'prop-types';
import streamServerRenderedReactComponent from '../src/streamServerRenderedReactComponent.ts';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';
import ReactOnRails from '../src/ReactOnRails.node.ts';

const AsyncContent = async ({ throwAsyncError }) => {
  await new Promise((resolve) => {
    setTimeout(resolve, 50);
  });
  if (throwAsyncError) {
    throw new Error('Async Error');
  }
  return <div>Async Content</div>;
};

AsyncContent.propTypes = {
  throwAsyncError: PropTypes.bool,
};

const TestComponentForStreaming = ({ throwSyncError, throwAsyncError }) => {
  if (throwSyncError) {
    throw new Error('Sync Error');
  }

  return (
    <div>
      <h1>Header In The Shell</h1>
      <React.Suspense fallback={<div>Loading...</div>}>
        <AsyncContent throwAsyncError={throwAsyncError} />
      </React.Suspense>
    </div>
  );
};

TestComponentForStreaming.propTypes = {
  throwSyncError: PropTypes.bool,
  throwAsyncError: PropTypes.bool,
};

describe('streamServerRenderedReactComponent', () => {
  const testingRailsContext = {
    serverSideRSCPayloadParameters: {},
    reactClientManifestFileName: 'clientManifest.json',
    reactServerClientManifestFileName: 'serverClientManifest.json',
    componentSpecificMetadata: {
      renderRequestId: '123',
    },
  };

  beforeEach(() => {
    ComponentRegistry.components().clear();
  });

  const expectStreamChunk = (chunk) => {
    expect(typeof chunk).toBe('string');
    const jsonChunk = JSON.parse(chunk);
    expect(typeof jsonChunk.html).toBe('string');
    expect(typeof jsonChunk.consoleReplayScript).toBe('string');
    expect(typeof jsonChunk.hasErrors).toBe('boolean');
    expect(typeof jsonChunk.isShellReady).toBe('boolean');
    return jsonChunk;
  };

  const setupStreamTest = ({
    throwSyncError = false,
    throwJsErrors = false,
    throwAsyncError = false,
    componentType = 'reactComponent',
  } = {}) => {
    switch (componentType) {
      case 'reactComponent':
        ReactOnRails.register({ TestComponentForStreaming });
        break;
      case 'renderFunction':
        ReactOnRails.register({
          TestComponentForStreaming: (props, _railsContext) => () => <TestComponentForStreaming {...props} />,
        });
        break;
      case 'asyncRenderFunction':
        ReactOnRails.register({
          TestComponentForStreaming: (props, _railsContext) => () =>
            Promise.resolve(<TestComponentForStreaming {...props} />),
        });
        break;
      case 'erroneousRenderFunction':
        ReactOnRails.register({
          TestComponentForStreaming: (_props, _railsContext) => {
            // The error happen inside the render function itself not inside the returned React component
            throw new Error('Sync Error from render function');
          },
        });
        break;
      case 'erroneousAsyncRenderFunction':
        ReactOnRails.register({
          TestComponentForStreaming: (_props, _railsContext) =>
            // The error happen inside the render function itself not inside the returned React component
            Promise.reject(new Error('Async Error from render function')),
        });
        break;
      default:
        throw new Error(`Unknown component type: ${componentType}`);
    }
    const renderResult = streamServerRenderedReactComponent({
      name: 'TestComponentForStreaming',
      domNodeId: 'myDomId',
      trace: false,
      props: { throwSyncError, throwAsyncError },
      throwJsErrors,
      railsContext: testingRailsContext,
    });

    const chunks = [];
    renderResult.on('data', (chunk) => {
      const decodedText = new TextDecoder().decode(chunk);
      chunks.push(expectStreamChunk(decodedText));
    });

    return { renderResult, chunks };
  };

  it('streamServerRenderedReactComponent streams the rendered component', async () => {
    const { renderResult, chunks } = setupStreamTest();
    await new Promise((resolve) => {
      renderResult.once('end', resolve);
    });

    expect(chunks).toHaveLength(2);
    expect(chunks[0].html).toContain('Header In The Shell');
    expect(chunks[0].consoleReplayScript).toBe('');
    expect(chunks[0].hasErrors).toBe(false);
    expect(chunks[0].isShellReady).toBe(true);
    expect(chunks[1].html).toContain('Async Content');
    expect(chunks[1].consoleReplayScript).toBe('');
    expect(chunks[1].hasErrors).toBe(false);
    expect(chunks[1].isShellReady).toBe(true);
  });

  it('emits an error if there is an error in the shell and throwJsErrors is true', async () => {
    const { renderResult, chunks } = setupStreamTest({ throwSyncError: true, throwJsErrors: true });
    const onError = jest.fn();
    renderResult.on('error', onError);
    await new Promise((resolve) => {
      renderResult.once('end', resolve);
    });

    expect(onError).toHaveBeenCalled();
    expect(chunks).toHaveLength(1);
    expect(chunks[0].html).toMatch(/<pre>Exception in rendering[.\s\S]*Sync Error[.\s\S]*<\/pre>/);
    expect(chunks[0].consoleReplayScript).toBe('');
    expect(chunks[0].hasErrors).toBe(true);
    expect(chunks[0].isShellReady).toBe(false);
  });

  it("doesn't emit an error if there is an error in the shell and throwJsErrors is false", async () => {
    const { renderResult, chunks } = setupStreamTest({ throwSyncError: true, throwJsErrors: false });
    const onError = jest.fn();
    renderResult.on('error', onError);
    await new Promise((resolve) => {
      renderResult.once('end', resolve);
    });

    expect(onError).not.toHaveBeenCalled();
    expect(chunks).toHaveLength(1);
    expect(chunks[0].html).toMatch(/<pre>Exception in rendering[.\s\S]*Sync Error[.\s\S]*<\/pre>/);
    expect(chunks[0].consoleReplayScript).toBe('');
    expect(chunks[0].hasErrors).toBe(true);
    expect(chunks[0].isShellReady).toBe(false);
  });

  it('emits an error if there is an error in the async content and throwJsErrors is true', async () => {
    const { renderResult, chunks } = setupStreamTest({ throwAsyncError: true, throwJsErrors: true });
    const onError = jest.fn();
    renderResult.on('error', onError);
    await new Promise((resolve) => {
      renderResult.once('end', resolve);
    });

    expect(onError).toHaveBeenCalled();
    expect(chunks).toHaveLength(2);
    expect(chunks[0].html).toContain('Header In The Shell');
    expect(chunks[0].consoleReplayScript).toBe('');
    expect(chunks[0].isShellReady).toBe(true);
    // Script that fallbacks the render to client side
    expect(chunks[1].html).toMatch(/the server rendering errored:\\n\\nAsync Error/);
    expect(chunks[1].consoleReplayScript).toBe('');
    expect(chunks[1].isShellReady).toBe(true);

    // One of the chunks should have a hasErrors property of true
    expect(chunks[0].hasErrors || chunks[1].hasErrors).toBe(true);
    expect(chunks[0].hasErrors && chunks[1].hasErrors).toBe(false);
  }, 10000);

  it("doesn't emit an error if there is an error in the async content and throwJsErrors is false", async () => {
    const { renderResult, chunks } = setupStreamTest({ throwAsyncError: true, throwJsErrors: false });
    const onError = jest.fn();
    renderResult.on('error', onError);
    await new Promise((resolve) => {
      renderResult.once('end', resolve);
    });

    expect(onError).not.toHaveBeenCalled();
    expect(chunks.length).toBeGreaterThanOrEqual(2);
    expect(chunks[0].html).toContain('Header In The Shell');
    expect(chunks[0].consoleReplayScript).toBe('');
    expect(chunks[0].isShellReady).toBe(true);
    // Script that fallbacks the render to client side
    expect(chunks[1].html).toMatch(/the server rendering errored:\\n\\nAsync Error/);
    expect(chunks[1].consoleReplayScript).toBe('');
    expect(chunks[1].isShellReady).toBe(true);

    // One of the chunks should have a hasErrors property of true
    expect(chunks[0].hasErrors || chunks[1].hasErrors).toBe(true);
    expect(chunks[0].hasErrors && chunks[1].hasErrors).toBe(false);
  });

  it.each(['asyncRenderFunction', 'renderFunction'])(
    'streams a component from a %s that resolves to a React component',
    async (componentType) => {
      const { renderResult, chunks } = setupStreamTest({ componentType });
      await new Promise((resolve) => {
        renderResult.once('end', resolve);
      });

      expect(chunks).toHaveLength(2);
      expect(chunks[0].html).toContain('Header In The Shell');
      expect(chunks[0].consoleReplayScript).toBe('');
      expect(chunks[0].hasErrors).toBe(false);
      expect(chunks[0].isShellReady).toBe(true);
      expect(chunks[1].html).toContain('Async Content');
      expect(chunks[1].consoleReplayScript).toBe('');
      expect(chunks[1].hasErrors).toBe(false);
      expect(chunks[1].isShellReady).toBe(true);
    },
  );

  it.each(['asyncRenderFunction', 'renderFunction'])(
    'handles sync errors in the %s',
    async (componentType) => {
      const { renderResult, chunks } = setupStreamTest({ componentType, throwSyncError: true });
      await new Promise((resolve) => {
        renderResult.once('end', resolve);
      });

      expect(chunks).toHaveLength(1);
      expect(chunks[0].html).toMatch(/<pre>Exception in rendering[.\s\S]*Sync Error[.\s\S]*<\/pre>/);
      expect(chunks[0].consoleReplayScript).toBe('');
      expect(chunks[0].hasErrors).toBe(true);
      expect(chunks[0].isShellReady).toBe(false);
    },
  );

  it.each(['asyncRenderFunction', 'renderFunction'])(
    'handles async errors in the %s',
    async (componentType) => {
      const { renderResult, chunks } = setupStreamTest({ componentType, throwAsyncError: true });
      await new Promise((resolve) => {
        renderResult.once('end', resolve);
      });

      expect(chunks.length).toBeGreaterThanOrEqual(2);
      expect(chunks[0].html).toContain('Header In The Shell');
      expect(chunks[0].consoleReplayScript).toBe('');
      expect(chunks[0].isShellReady).toBe(true);
      expect(chunks[1].html).toMatch(/the server rendering errored:\\n\\nAsync Error/);
      expect(chunks[1].consoleReplayScript).toBe('');
      expect(chunks[1].isShellReady).toBe(true);

      // One of the chunks should have a hasErrors property of true
      expect(chunks[0].hasErrors || chunks[1].hasErrors).toBe(true);
      expect(chunks[0].hasErrors && chunks[1].hasErrors).toBe(false);
    },
  );

  it.each(['erroneousRenderFunction', 'erroneousAsyncRenderFunction'])(
    'handles error in the %s',
    async (componentType) => {
      const { renderResult, chunks } = setupStreamTest({ componentType });
      await new Promise((resolve) => {
        renderResult.once('end', resolve);
      });

      expect(chunks).toHaveLength(1);
      const errorMessage =
        componentType === 'erroneousRenderFunction'
          ? 'Sync Error from render function'
          : 'Async Error from render function';
      expect(chunks[0].html).toMatch(
        new RegExp(`<pre>Exception in rendering[.\\s\\S]*${errorMessage}[.\\s\\S]*<\\/pre>`),
      );
      expect(chunks[0].consoleReplayScript).toBe('');
      expect(chunks[0].hasErrors).toBe(true);
      expect(chunks[0].isShellReady).toBe(false);
    },
  );

  it.each(['erroneousRenderFunction', 'erroneousAsyncRenderFunction'])(
    'emits an error if there is an error in the %s',
    async (componentType) => {
      const { renderResult, chunks } = setupStreamTest({ componentType, throwJsErrors: true });
      const onError = jest.fn();
      renderResult.on('error', onError);
      await new Promise((resolve) => {
        renderResult.once('end', resolve);
      });

      expect(chunks).toHaveLength(1);
      const errorMessage =
        componentType === 'erroneousRenderFunction'
          ? 'Sync Error from render function'
          : 'Async Error from render function';
      expect(chunks[0].html).toMatch(
        new RegExp(`<pre>Exception in rendering[.\\s\\S]*${errorMessage}[.\\s\\S]*<\\/pre>`),
      );
      expect(chunks[0].consoleReplayScript).toBe('');
      expect(chunks[0].hasErrors).toBe(true);
      expect(chunks[0].isShellReady).toBe(false);
      expect(onError).toHaveBeenCalled();
    },
  );

  it('streams a string from a Promise that resolves to a string', async () => {
    const StringPromiseComponent = () => Promise.resolve('<div>String from Promise</div>');
    ReactOnRails.register({ StringPromiseComponent });

    const renderResult = streamServerRenderedReactComponent({
      name: 'StringPromiseComponent',
      domNodeId: 'stringPromiseId',
      trace: false,
      throwJsErrors: false,
      railsContext: testingRailsContext,
    });

    const chunks = [];
    renderResult.on('data', (chunk) => {
      const decodedText = new TextDecoder().decode(chunk);
      chunks.push(expectStreamChunk(decodedText));
    });

    await new Promise((resolve) => {
      renderResult.once('end', resolve);
    });

    // Verify we have at least one chunk and it contains our string
    expect(chunks.length).toBeGreaterThan(0);
    expect(chunks[0].html).toContain('String from Promise');
    expect(chunks[0].hasErrors).toBe(false);
  });
});
