/**
 * @jest-environment node
 */

import React, { Suspense } from 'react';
import PropTypes from 'prop-types';
import { streamServerRenderedReactComponent } from '../src/serverRenderReactComponent';
import ComponentRegistry from '../src/ComponentRegistry';

const AsyncContent = async ({ throwAsyncError }) => {
  await new Promise((resolve) => setTimeout(resolve, 0));
  if (throwAsyncError) {
    throw new Error('Async Error');
  }
  return <div>Async Content</div>;
};

const TestComponentForStreaming = ({ throwSyncError, throwAsyncError }) => {
  if (throwSyncError) {
    throw new Error('Sync Error');
  }

  return (
    <div>
      <h1>Header In The Shell</h1>
      <Suspense fallback={<div>Loading...</div>}>
        <AsyncContent throwAsyncError={throwAsyncError} />
      </Suspense>
    </div>
  );
}

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
  }

  const setupStreamTest = ({ throwSyncError = false, throwJsErrors = false, throwAsyncError = false } = {}) => {
    ComponentRegistry.register({ TestComponentForStreaming });
    const renderResult = streamServerRenderedReactComponent({ 
      name: 'TestComponentForStreaming', 
      domNodeId: 'myDomId', 
      trace: false,
      props: { throwSyncError, throwAsyncError },
      throwJsErrors
    });

    const chunks = [];
    renderResult.on('data', (chunk) => {
      const decodedText = new TextDecoder().decode(chunk);
      chunks.push(expectStreamChunk(decodedText));
    });

    return { renderResult, chunks };
  }

  it('streamServerRenderedReactComponent streams the rendered component', async () => {
    const { renderResult, chunks } = setupStreamTest();
    await new Promise(resolve => renderResult.on('end', resolve));

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
    await new Promise(resolve => renderResult.on('end', resolve));

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
    await new Promise(resolve => renderResult.on('end', resolve));

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
    await new Promise(resolve => renderResult.on('end', resolve));

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
    await new Promise(resolve => renderResult.on('end', resolve));

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
});
