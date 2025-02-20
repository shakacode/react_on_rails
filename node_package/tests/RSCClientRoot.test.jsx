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
import { render, screen, act } from '@testing-library/react';
import '@testing-library/jest-dom';
import path from 'path';
import fs from 'fs';
import { createNodeReadableStream } from './testUtils';

import RSCClientRoot, { resetRenderCache } from '../src/RSCClientRoot';

enableFetchMocks();

const nodeVersion = parseInt(process.version.slice(1), 10);

// React Server Components tests are not compatible with Experimental React 18 and React 19
// That only run with node version 18 and above
(nodeVersion >= 18 ? describe : describe.skip)('RSCClientRoot', () => {
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

    const { rerender } = await act(async () => render(<RSCClientRoot {...props} />));

    return {
      rerender: () => rerender(<RSCClientRoot {...props} />),
      pushFirstChunk: () => push(`${JSON.stringify(chunk1)}\n`),
      pushSecondChunk: () => push(`${JSON.stringify(chunk2)}\n`),
      pushCustomChunk: (chunk) => push(`${chunk}\n`),
      endStream: () => push(null),
    };
  };

  it('fetches and caches component data', async () => {
    const { rerender, pushFirstChunk, pushSecondChunk, endStream } = await mockRSCRequest();

    expect(window.fetch).toHaveBeenCalledWith('/rsc-render/TestComponent');
    expect(window.fetch).toHaveBeenCalledTimes(1);
    expect(screen.queryByText('StaticServerComponent')).not.toBeInTheDocument();

    await act(async () => {
      pushFirstChunk();
    });
    expect(screen.getByText('StaticServerComponent')).toBeInTheDocument();
    expect(screen.getByText('Loading AsyncComponent...')).toBeInTheDocument();
    expect(screen.queryByText('AsyncComponent')).not.toBeInTheDocument();

    await act(async () => {
      pushSecondChunk();
      endStream();
    });
    expect(screen.getByText('AsyncComponent')).toBeInTheDocument();
    expect(screen.queryByText('Loading AsyncComponent...')).not.toBeInTheDocument();

    // Second render - should use cache
    rerender();

    expect(screen.getByText('AsyncComponent')).toBeInTheDocument();
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it('replays console logs', async () => {
    const consoleSpy = jest.spyOn(console, 'log');
    const { rerender, pushFirstChunk, pushSecondChunk, endStream } = await mockRSCRequest();

    await act(async () => {
      pushFirstChunk();
    });
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('Console log at first chunk'),
      expect.anything(), expect.anything(), expect.anything()
    );
    expect(consoleSpy).toHaveBeenCalledTimes(1);

    await act(async () => {
      pushSecondChunk();
    });
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('Console log at second chunk'),
      expect.anything(), expect.anything(), expect.anything()
    );
    await act(async () => {
      endStream();
    });
    expect(consoleSpy).toHaveBeenCalledTimes(2);

    // On rerender, console logs should not be replayed again
    rerender();
    expect(consoleSpy).toHaveBeenCalledTimes(2);
  });

  it('strips leading and trailing slashes from rscPayloadGenerationUrlPath', async () => {
    const { pushFirstChunk, pushSecondChunk, endStream } = await mockRSCRequest('/rsc-render/');

    await act(async () => {
      pushFirstChunk();
      pushSecondChunk();
      endStream();
    });

    expect(window.fetch).toHaveBeenCalledWith('/rsc-render/TestComponent');
    expect(window.fetch).toHaveBeenCalledTimes(1);

    expect(screen.getByText('StaticServerComponent')).toBeInTheDocument();
  });
});
