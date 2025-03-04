/* eslint-disable no-underscore-dangle */
/* eslint-disable import/first */

// Mock webpack require system for RSC
window.__webpack_require__ = jest.fn();
window.__webpack_chunk_load__ = jest.fn();

import { enableFetchMocks } from 'jest-fetch-mock';
import { screen, act } from '@testing-library/react';
import '@testing-library/jest-dom';
import * as path from 'path';
import * as fs from 'fs';
import { createNodeReadableStream, getNodeVersion } from './testUtils';

import RSCClientRoot from '../src/RSCClientRoot';

enableFetchMocks();

// React Server Components tests are compatible with React 19
// That only run with node version 18 and above
(getNodeVersion() >= 18 ? describe : describe.skip)('RSCClientRoot', () => {
  let container;
  const mockDomNodeId = 'test-container';

  beforeEach(() => {
    // Setup DOM element
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
      jest.requireActual('../src/RSCClientRoot');
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

    const props = {
      componentName: 'TestComponent',
      rscPayloadGenerationUrlPath,
    };

    // Execute the render
    const render = () =>
      act(async () => {
        await RSCClientRoot(props, undefined, mockDomNodeId);
      });

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
      render();
    });
    expect(window.fetch).toHaveBeenCalledWith('/rsc-render/TestComponent?props=undefined');
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
      render();
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
      render();
      pushFirstChunk();
      pushSecondChunk();
      endStream();
    });

    expect(window.fetch).toHaveBeenCalledWith('/rsc-render/TestComponent?props=undefined');
    expect(window.fetch).toHaveBeenCalledTimes(1);

    expect(screen.getByText('StaticServerComponent')).toBeInTheDocument();
  });
});
