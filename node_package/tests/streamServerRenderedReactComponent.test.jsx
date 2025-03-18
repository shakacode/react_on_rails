/**
 * @jest-environment node
 */

import * as React from 'react';
import * as PropTypes from 'prop-types';
import streamServerRenderedReactComponent from '../src/streamServerRenderedReactComponent';
import ComponentRegistry from '../src/ComponentRegistry';

const AsyncContent = async ({ throwAsyncError }) => {
  await new Promise((resolve) => {
    setTimeout(resolve, 0);
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
        ComponentRegistry.register({ TestComponentForStreaming });
        break;
      case 'renderFunction':
        ComponentRegistry.register({
          TestComponentForStreaming: (props, _railsContext) => () => <TestComponentForStreaming {...props} />,
        });
        break;
      case 'asyncRenderFunction':
        ComponentRegistry.register({
          TestComponentForStreaming: (props, _railsContext) => () =>
            Promise.resolve(<TestComponentForStreaming {...props} />),
        });
        break;
    }
    const renderResult = streamServerRenderedReactComponent({
      name: 'TestComponentForStreaming',
      domNodeId: 'myDomId',
      trace: false,
      props: { throwSyncError, throwAsyncError },
      throwJsErrors,
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
      renderResult.on('end', resolve);
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
      renderResult.on('end', resolve);
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
      renderResult.on('end', resolve);
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
      renderResult.on('end', resolve);
    });

    expect(onError).toHaveBeenCalled();
    expect(chunks).toHaveLength(2);
    expect(chunks[0].html).toContain('Header In The Shell');
    expect(chunks[0].consoleReplayScript).toBe('');
    expect(chunks[0].hasErrors).toBe(false);
    expect(chunks[0].isShellReady).toBe(true);
    // Script that fallbacks the render to client side
    expect(chunks[1].html).toMatch(/<script>[.\s\S]*Async Error[.\s\S]*<\/script>/);
    expect(chunks[1].consoleReplayScript).toBe('');
    expect(chunks[1].hasErrors).toBe(true);
    expect(chunks[1].isShellReady).toBe(true);
  });

  it("doesn't emit an error if there is an error in the async content and throwJsErrors is false", async () => {
    const { renderResult, chunks } = setupStreamTest({ throwAsyncError: true, throwJsErrors: false });
    const onError = jest.fn();
    renderResult.on('error', onError);
    await new Promise((resolve) => {
      renderResult.on('end', resolve);
    });

    expect(onError).not.toHaveBeenCalled();
    expect(chunks).toHaveLength(2);
    expect(chunks[0].html).toContain('Header In The Shell');
    expect(chunks[0].consoleReplayScript).toBe('');
    expect(chunks[0].hasErrors).toBe(false);
    expect(chunks[0].isShellReady).toBe(true);
    // Script that fallbacks the render to client side
    expect(chunks[1].html).toMatch(/<script>[.\s\S]*Async Error[.\s\S]*<\/script>/);
    expect(chunks[1].consoleReplayScript).toBe('');
    expect(chunks[1].hasErrors).toBe(true);
    expect(chunks[1].isShellReady).toBe(true);
  });

  it.each(['asyncRenderFunction', 'renderFunction'])(
    'streams a component from a %s that resolves to a React component',
    async (componentType) => {
      const { renderResult, chunks } = setupStreamTest({ componentType });
      await new Promise((resolve) => renderResult.on('end', resolve));

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

  it('streams a string from a Promise that resolves to a string', async () => {
    const StringPromiseComponent = () => Promise.resolve('<div>String from Promise</div>');
    ComponentRegistry.register({ StringPromiseComponent });

    const renderResult = streamServerRenderedReactComponent({
      name: 'StringPromiseComponent',
      domNodeId: 'stringPromiseId',
      trace: false,
      throwJsErrors: false,
    });

    const chunks = [];
    renderResult.on('data', (chunk) => {
      const decodedText = new TextDecoder().decode(chunk);
      chunks.push(expectStreamChunk(decodedText));
    });

    await new Promise((resolve) => renderResult.on('end', resolve));

    // Verify we have at least one chunk and it contains our string
    expect(chunks.length).toBeGreaterThan(0);
    expect(chunks[0].html).toContain('String from Promise');
    expect(chunks[0].hasErrors).toBe(false);
  });
});
