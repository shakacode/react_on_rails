/* eslint-disable no-underscore-dangle */

// Mock webpack require system for RSC
window.__webpack_require__ = jest.fn();
window.__webpack_chunk_load__ = jest.fn();

import { enableFetchMocks } from 'jest-fetch-mock';
import { screen, act } from '@testing-library/react';
import '@testing-library/jest-dom';
import * as path from 'path';
import * as fs from 'fs';
import { createNodeReadableStream, getNodeVersion } from './testUtils.ts';
import ReactOnRails from '../src/ReactOnRails.client.ts';
import registerServerComponent from '../src/registerServerComponent/client.tsx';
import { clear as clearComponentRegistry } from '../src/ComponentRegistry.ts';

enableFetchMocks();

// React Server Components tests require React 19 and only run with Node version 18 (`newest` in our CI matrix)
(getNodeVersion() >= 18 ? describe : describe.skip)('registerServerComponent', () => {
  let container;
  const mockDomNodeId = 'test-container';

  beforeEach(() => {
    // Setup DOM element
    clearComponentRegistry();
    container = document.createElement('div');
    container.id = mockDomNodeId;
    document.body.appendChild(container);
    jest.clearAllMocks();

    jest.resetModules();
  });

  afterEach(() => {
    document.body.removeChild(container);
  });

  it('throws error when React.use is not defined', () => {
    jest.mock('react', () => ({
      ...jest.requireActual('react'),
      use: undefined,
    }));

    expect(() => {
      // Re-import to trigger the check
      jest.requireActual('../src/wrapServerComponentRenderer/client.tsx');
    }).toThrow('React.use is not defined');
  });

  const mockRSCRequest = async (rscPayloadGenerationUrlPath = 'rsc-render') => {
    const chunksDirectory = path.join(
      __dirname,
      'fixtures',
      'rsc-payloads',
      'simple-shell-with-async-component',
    );
    const chunk1 = JSON.parse(fs.readFileSync(path.join(chunksDirectory, 'chunk1.json'), 'utf8'));
    const chunk2 = JSON.parse(fs.readFileSync(path.join(chunksDirectory, 'chunk2.json'), 'utf8'));

    const { stream, push } = createNodeReadableStream();
    window.fetchMock.mockResolvedValue(new Response(stream));

    registerServerComponent('TestComponent');
    const railsContext = {
      rscPayloadGenerationUrlPath,
    };

    // Execute the render
    const render = async () => {
      const Component = ReactOnRails.getComponent('TestComponent');
      await Component.component({}, railsContext, mockDomNodeId);
    };

    return {
      render,
      pushFirstChunk: () => push(`${JSON.stringify(chunk1)}\n`),
      pushSecondChunk: () => push(`${JSON.stringify(chunk2)}\n`),
      pushCustomChunk: (chunk) => push(`${chunk}\n`),
      endStream: () => push(null),
    };
  };

  it('renders component progressively', async () => {
    const { render, pushFirstChunk, pushSecondChunk, endStream } = await mockRSCRequest();

    expect(screen.queryByText('StaticServerComponent')).not.toBeInTheDocument();

    await act(async () => {
      pushFirstChunk();
      await render();
    });
    expect(window.fetch).toHaveBeenCalledWith('/rsc-render/TestComponent?props=%7B%7D');
    expect(window.fetch).toHaveBeenCalledTimes(1);
    expect(screen.getByText('StaticServerComponent')).toBeInTheDocument();
    expect(screen.getByText('Loading AsyncComponent...')).toBeInTheDocument();
    expect(screen.queryByText('AsyncComponent')).not.toBeInTheDocument();

    await act(async () => {
      pushSecondChunk();
      endStream();
    });
    expect(screen.getByText('AsyncComponent')).toBeInTheDocument();
    expect(screen.queryByText('Loading AsyncComponent...')).not.toBeInTheDocument();
  });

  it('replays console logs', async () => {
    const consoleSpy = jest.spyOn(console, 'log');
    const { render, pushFirstChunk, pushSecondChunk, endStream } = await mockRSCRequest();

    await act(async () => {
      await render();
      pushFirstChunk();
    });
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('Console log at first chunk'),
      expect.anything(),
      expect.anything(),
      expect.anything(),
    );
    expect(consoleSpy).toHaveBeenCalledTimes(1);

    await act(async () => {
      pushSecondChunk();
    });
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('Console log at second chunk'),
      expect.anything(),
      expect.anything(),
      expect.anything(),
    );
    await act(async () => {
      endStream();
    });
    expect(consoleSpy).toHaveBeenCalledTimes(2);
  });

  it('strips leading and trailing slashes from rscPayloadGenerationUrlPath', async () => {
    const { render, pushFirstChunk, pushSecondChunk, endStream } = await mockRSCRequest('/rsc-render/');

    await act(async () => {
      await render();
      pushFirstChunk();
      pushSecondChunk();
      endStream();
    });

    expect(window.fetch).toHaveBeenCalledWith('/rsc-render/TestComponent?props=%7B%7D');
    expect(window.fetch).toHaveBeenCalledTimes(1);

    expect(screen.getByText('StaticServerComponent')).toBeInTheDocument();
  });

  describe('preloaded RSC payloads', () => {
    let chunk1;
    let chunk2;
    let railsContext;

    beforeEach(() => {
      // Setup test fixtures
      const chunksDirectory = path.join(
        __dirname,
        'fixtures',
        'rsc-payloads',
        'simple-shell-with-async-component',
      );
      chunk1 = JSON.stringify(JSON.parse(fs.readFileSync(path.join(chunksDirectory, 'chunk1.json'), 'utf8')));
      chunk2 = JSON.stringify(JSON.parse(fs.readFileSync(path.join(chunksDirectory, 'chunk2.json'), 'utf8')));

      registerServerComponent('TestComponent');
      railsContext = {
        rscPayloadGenerationUrlPath: 'rsc-render',
      };

      // Cleanup any previous payload data
      delete window.REACT_ON_RAILS_RSC_PAYLOADS;
    });

    afterEach(() => {
      // Clean up
      delete window.REACT_ON_RAILS_RSC_PAYLOADS;
    });

    it('uses preloaded RSC payloads without making a fetch request', async () => {
      // Mock the global window.REACT_ON_RAILS_RSC_PAYLOADS
      window.REACT_ON_RAILS_RSC_PAYLOADS = {
        'TestComponent-{}-test-container': [`${chunk1}\n`, `${chunk2}\n`],
      };

      await act(async () => {
        const Component = ReactOnRails.getComponent('TestComponent');
        await Component.component({}, railsContext, mockDomNodeId);
      });

      // Verify no fetch request was made
      expect(window.fetch).not.toHaveBeenCalled();

      // Verify the component rendered correctly
      expect(screen.getByText('StaticServerComponent')).toBeInTheDocument();
      expect(screen.getByText('AsyncComponent')).toBeInTheDocument();
      expect(screen.queryByText('Loading AsyncComponent...')).not.toBeInTheDocument();
    });

    it('renders progressively when additional chunks are pushed to preloaded RSC payloads', async () => {
      // Mock document.readyState to be 'loading'
      const originalReadyState = document.readyState;
      Object.defineProperty(document, 'readyState', { value: 'loading', writable: true });

      // Mock the global window.REACT_ON_RAILS_RSC_PAYLOADS with only the first chunk initially
      window.REACT_ON_RAILS_RSC_PAYLOADS = {
        'TestComponent-{}-test-container': [`${chunk1}\n`],
      };

      await act(async () => {
        const Component = ReactOnRails.getComponent('TestComponent');
        await Component.component({}, railsContext, mockDomNodeId);
      });

      // Verify no fetch request was made
      expect(window.fetch).not.toHaveBeenCalled();

      // After first chunk, StaticServerComponent should be visible but AsyncComponent should be loading
      expect(screen.getByText('StaticServerComponent')).toBeInTheDocument();
      expect(screen.getByText('Loading AsyncComponent...')).toBeInTheDocument();
      expect(screen.queryByText('AsyncComponent')).not.toBeInTheDocument();

      // Now push the second chunk to the preloaded array and set document to complete
      await act(async () => {
        window.REACT_ON_RAILS_RSC_PAYLOADS['TestComponent-{}-test-container'].push(`${chunk2}\n`);

        // Set document.readyState to 'complete' and dispatch readystatechange event
        Object.defineProperty(document, 'readyState', { value: 'complete', writable: true });
        document.dispatchEvent(new Event('readystatechange'));
        document.dispatchEvent(new Event('DOMContentLoaded'));
      });

      // After the second chunk, AsyncComponent should now be visible and loading indicator gone
      expect(screen.getByText('AsyncComponent')).toBeInTheDocument();
      expect(screen.queryByText('Loading AsyncComponent...')).not.toBeInTheDocument();

      // Restore original readyState
      Object.defineProperty(document, 'readyState', { value: originalReadyState });
    });
  });
});
