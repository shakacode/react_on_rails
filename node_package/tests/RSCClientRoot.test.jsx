/* eslint-disable no-underscore-dangle */
/* eslint-disable import/first */
/**
 * @jest-environment jsdom
 */

// Mock webpack require system for RSC
window.__webpack_require__ = jest.fn();
window.__webpack_chunk_load__ = jest.fn();

import * as React from 'react';
import { enableFetchMocks } from 'jest-fetch-mock';
import { render, waitFor, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import path from 'path';
import fs from 'fs';
import { createNodeReadableStream } from './testUtils';

import RSCClientRoot, { resetRenderCache } from '../src/RSCClientRoot';

enableFetchMocks();

// TODO: Remove this once we made these tests compatible with React 19
(process.env.USE_REACT_18 ? describe : describe.skip)('RSCClientRoot', () => {
  beforeEach(() => {
    jest.clearAllMocks();

    jest.resetModules();
    resetRenderCache();
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

  const mockRSCRequest = (rscRenderingUrlPath = 'rsc-render') => {
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
      rscRenderingUrlPath,
    };

    const { rerender } = render(<RSCClientRoot {...props} />);

    return {
      rerender: () => rerender(<RSCClientRoot {...props} />),
      pushFirstChunk: () => push(JSON.stringify(chunk1)),
      pushSecondChunk: () => push(JSON.stringify(chunk2)),
      pushCustomChunk: (chunk) => push(chunk),
      endStream: () => push(null),
    };
  };

  it('fetches and caches component data', async () => {
    const { rerender, pushFirstChunk, pushSecondChunk, endStream } = mockRSCRequest();

    expect(window.fetch).toHaveBeenCalledWith('/rsc-render/TestComponent');
    expect(window.fetch).toHaveBeenCalledTimes(1);
    expect(screen.queryByText('StaticServerComponent')).not.toBeInTheDocument();

    pushFirstChunk();
    await waitFor(() => expect(screen.getByText('StaticServerComponent')).toBeInTheDocument());
    expect(screen.getByText('Loading AsyncComponent...')).toBeInTheDocument();
    expect(screen.queryByText('AsyncComponent')).not.toBeInTheDocument();

    pushSecondChunk();
    endStream();
    await waitFor(() => expect(screen.getByText('AsyncComponent')).toBeInTheDocument());
    expect(screen.queryByText('Loading AsyncComponent...')).not.toBeInTheDocument();

    // Second render - should use cache
    rerender();

    expect(screen.getByText('AsyncComponent')).toBeInTheDocument();
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it('replays console logs', async () => {
    const consoleSpy = jest.spyOn(console, 'log');
    const { rerender, pushFirstChunk, pushSecondChunk, endStream } = mockRSCRequest();

    pushFirstChunk();
    await waitFor(() => expect(consoleSpy).toHaveBeenCalledWith('[SERVER] Console log at first chunk'));
    expect(consoleSpy).toHaveBeenCalledTimes(1);

    pushSecondChunk();
    await waitFor(() => expect(consoleSpy).toHaveBeenCalledWith('[SERVER] Console log at second chunk'));
    endStream();
    expect(consoleSpy).toHaveBeenCalledTimes(2);

    // On rerender, console logs should not be replayed again
    rerender();
    expect(consoleSpy).toHaveBeenCalledTimes(2);
  });

  it('strips leading and trailing slashes from rscRenderingUrlPath', async () => {
    const { pushFirstChunk, pushSecondChunk, endStream } = mockRSCRequest('/rsc-render/');

    pushFirstChunk();
    pushSecondChunk();
    endStream();

    await waitFor(() => expect(window.fetch).toHaveBeenCalledWith('/rsc-render/TestComponent'));
    expect(window.fetch).toHaveBeenCalledTimes(1);

    await waitFor(() => expect(screen.getByText('StaticServerComponent')).toBeInTheDocument());
  });
});
