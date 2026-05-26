/**
 * @jest-environment node
 */

import * as React from 'react';
import * as PropTypes from 'prop-types';
import streamServerRenderedReactComponent from '../src/streamServerRenderedReactComponent.ts';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';
import ReactOnRails from '../src/ReactOnRails.node.ts';
import LengthPrefixedStreamParser from '../src/parseLengthPrefixedStream.ts';
import wrapServerComponentRenderer from '../src/wrapServerComponentRenderer/server.tsx';
import RSCRoute from '../src/RSCRoute.tsx';
import { RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST } from '../src/RSCRouteSSRFalseBailoutError.ts';

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

const RSCBailoutStreamingShell = () => (
  <main>
    <h1>Shell before skipped route</h1>
    <React.Suspense fallback={<aside>Loading skipped route...</aside>}>
      <RSCRoute componentName="SkippedServerRoute" componentProps={{ id: 1 }} ssr={false} />
    </React.Suspense>
    <footer>Shell after skipped route</footer>
  </main>
);

const NestedSuspenseServerError = () => {
  throw new Error('Unexpected nested Suspense failure');
};

const UnexpectedNestedSuspenseErrorShell = () => (
  <main>
    <h1>Shell before errored boundary</h1>
    <React.Suspense fallback={<aside>Loading errored boundary...</aside>}>
      <NestedSuspenseServerError />
    </React.Suspense>
    <footer>Shell after errored boundary</footer>
  </main>
);

const MixedRSCRouteBailoutAndNestedSuspenseErrorShell = () => (
  <main>
    <h1>Shell before mixed boundaries</h1>
    <React.Suspense fallback={<aside>Loading skipped route...</aside>}>
      <RSCRoute componentName="SkippedServerRoute" componentProps={{ id: 1 }} ssr={false} />
    </React.Suspense>
    <React.Suspense fallback={<aside>Loading errored boundary...</aside>}>
      <NestedSuspenseServerError />
    </React.Suspense>
    <footer>Shell after mixed boundaries</footer>
  </main>
);

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
    ComponentRegistry.clear();
  });

  // Parses a length-prefixed stream chunk: metadata\tcontent_len\ncontent
  const parseStreamChunk = (rawBytes) => {
    const parser = new LengthPrefixedStreamParser();
    const results = [];
    parser.feed(rawBytes, (content, metadata) => {
      const decoder = new TextDecoder();
      results.push({ html: decoder.decode(content), ...metadata });
    });
    expect(results).toHaveLength(1);
    return results[0];
  };

  const expectStreamChunk = (chunk) => {
    const parsed = parseStreamChunk(chunk);
    expect(typeof parsed.html).toBe('string');
    expect(typeof parsed.consoleReplayScript).toBe('string');
    expect(typeof parsed.hasErrors).toBe('boolean');
    expect(typeof parsed.isShellReady).toBe('boolean');
    return parsed;
  };

  const collectStreamResult = async (renderResult) => {
    const chunks = [];
    const errors = [];

    renderResult.on('data', (chunk) => {
      chunks.push(expectStreamChunk(chunk));
    });
    renderResult.on('error', (error) => {
      errors.push(error);
    });

    await new Promise((resolve) => {
      renderResult.once('end', resolve);
    });

    return { chunks, errors };
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
      chunks.push(expectStreamChunk(chunk));
    });

    return { renderResult, chunks };
  };

  const setupRSCRouteSSRFalseStreamTest = ({ throwJsErrors = false, onPostSSRHook } = {}) => {
    const generateRSCPayload = jest.fn();
    const renderFunction = (_props, railsContext) => {
      if (onPostSSRHook) {
        railsContext.addPostSSRHook(onPostSSRHook);
      }

      return RSCBailoutStreamingShell;
    };

    ReactOnRails.register({
      RSCBailoutStreamingShell: wrapServerComponentRenderer(renderFunction, 'RSCBailoutStreamingShell'),
    });

    const renderResult = streamServerRenderedReactComponent({
      name: 'RSCBailoutStreamingShell',
      domNodeId: 'rscBailoutDomId',
      trace: false,
      throwJsErrors,
      railsContext: testingRailsContext,
      generateRSCPayload,
    });

    return { renderResult, generateRSCPayload };
  };

  const setupUnexpectedNestedSuspenseErrorStreamTest = ({ onPostSSRHook } = {}) => {
    const renderFunction = (_props, railsContext) => {
      if (onPostSSRHook) {
        railsContext.addPostSSRHook(onPostSSRHook);
      }

      return UnexpectedNestedSuspenseErrorShell;
    };

    ReactOnRails.register({
      UnexpectedNestedSuspenseErrorShell: wrapServerComponentRenderer(
        renderFunction,
        'UnexpectedNestedSuspenseErrorShell',
      ),
    });

    return streamServerRenderedReactComponent({
      name: 'UnexpectedNestedSuspenseErrorShell',
      domNodeId: 'unexpectedNestedSuspenseErrorDomId',
      trace: false,
      throwJsErrors: false,
      railsContext: testingRailsContext,
      generateRSCPayload: jest.fn(),
    });
  };

  const setupMixedRSCRouteBailoutAndNestedSuspenseErrorStreamTest = ({ onPostSSRHook } = {}) => {
    const generateRSCPayload = jest.fn();
    const renderFunction = (_props, railsContext) => {
      if (onPostSSRHook) {
        railsContext.addPostSSRHook(onPostSSRHook);
      }

      return MixedRSCRouteBailoutAndNestedSuspenseErrorShell;
    };

    ReactOnRails.register({
      MixedRSCRouteBailoutAndNestedSuspenseErrorShell: wrapServerComponentRenderer(
        renderFunction,
        'MixedRSCRouteBailoutAndNestedSuspenseErrorShell',
      ),
    });

    const renderResult = streamServerRenderedReactComponent({
      name: 'MixedRSCRouteBailoutAndNestedSuspenseErrorShell',
      domNodeId: 'mixedRSCRouteBailoutAndNestedSuspenseErrorDomId',
      trace: false,
      throwJsErrors: false,
      railsContext: testingRailsContext,
      generateRSCPayload,
    });

    return { renderResult, generateRSCPayload };
  };

  it('renders the nearest Suspense fallback for RSCRoute ssr=false without generating an RSC payload', async () => {
    const { renderResult, generateRSCPayload } = setupRSCRouteSSRFalseStreamTest();
    const { chunks, errors } = await collectStreamResult(renderResult);
    const html = chunks.map((chunk) => chunk.html).join('');

    expect(errors).toHaveLength(0);
    expect(generateRSCPayload).not.toHaveBeenCalled();
    expect(html).toContain('Shell before skipped route');
    expect(html).toContain('Loading skipped route...');
    expect(html).toContain('Shell after skipped route');
    expect(html).toContain(`data-dgst="${RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST}"`);
    expect(html).not.toContain('REACT_ON_RAILS_RSC_PAYLOADS');
    expect(chunks.length).toBeGreaterThan(0);
    expect(chunks.every((chunk) => chunk.hasErrors === false)).toBe(true);
    expect(chunks.every((chunk) => chunk.isShellReady === true)).toBe(true);
  });

  it('does not emit a stream error for the classified RSCRoute ssr=false bailout when throwJsErrors is true', async () => {
    const { renderResult, generateRSCPayload } = setupRSCRouteSSRFalseStreamTest({ throwJsErrors: true });
    const { chunks, errors } = await collectStreamResult(renderResult);
    const html = chunks.map((chunk) => chunk.html).join('');

    expect(errors).toHaveLength(0);
    expect(generateRSCPayload).not.toHaveBeenCalled();
    expect(html).toContain('Loading skipped route...');
    expect(chunks.length).toBeGreaterThan(0);
    expect(chunks.every((chunk) => chunk.hasErrors === false)).toBe(true);
  });

  it('runs post-SSR hooks once for the classified RSCRoute ssr=false bailout path', async () => {
    const onPostSSRHook = jest.fn();
    const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    const { renderResult } = setupRSCRouteSSRFalseStreamTest({ onPostSSRHook });

    try {
      await collectStreamResult(renderResult);

      expect(onPostSSRHook).toHaveBeenCalledTimes(1);
      expect(consoleWarnSpy).not.toHaveBeenCalledWith(
        expect.stringContaining('notifySSREnd() called multiple times'),
      );
    } finally {
      consoleWarnSpy.mockRestore();
    }
  });

  it('preserves the duplicate notifySSREnd warning for unexpected nested Suspense errors', async () => {
    const onPostSSRHook = jest.fn();
    const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    const renderResult = setupUnexpectedNestedSuspenseErrorStreamTest({ onPostSSRHook });

    try {
      const { chunks, errors } = await collectStreamResult(renderResult);

      expect(errors).toHaveLength(0);
      expect(onPostSSRHook).toHaveBeenCalledTimes(1);
      expect(chunks.some((chunk) => chunk.hasErrors)).toBe(true);
      expect(consoleWarnSpy).toHaveBeenCalledWith(
        expect.stringContaining('notifySSREnd() called multiple times'),
      );
    } finally {
      consoleWarnSpy.mockRestore();
    }
  });

  it('preserves the duplicate notifySSREnd warning when a real error occurs with an RSCRoute ssr=false bailout', async () => {
    const onPostSSRHook = jest.fn();
    const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    const { renderResult, generateRSCPayload } = setupMixedRSCRouteBailoutAndNestedSuspenseErrorStreamTest({
      onPostSSRHook,
    });

    try {
      const { chunks, errors } = await collectStreamResult(renderResult);
      const html = chunks.map((chunk) => chunk.html).join('');

      expect(errors).toHaveLength(0);
      expect(generateRSCPayload).not.toHaveBeenCalled();
      expect(onPostSSRHook).toHaveBeenCalledTimes(1);
      expect(html).toContain('Loading skipped route...');
      expect(html).toContain('Loading errored boundary...');
      expect(chunks.some((chunk) => chunk.hasErrors)).toBe(true);
      expect(consoleWarnSpy).toHaveBeenCalledWith(
        expect.stringContaining('notifySSREnd() called multiple times'),
      );
    } finally {
      consoleWarnSpy.mockRestore();
    }
  });

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
  }, 100000);

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
      chunks.push(expectStreamChunk(chunk));
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
