/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import type reactHydrateOrRenderType from '../src/reactHydrateOrRender.ts';

const mockRender = jest.fn();
const mockCreateRoot = jest.fn(() => ({ render: mockRender }));
const mockHydrateRoot = jest.fn();

describe('reactHydrateOrRender', () => {
  beforeEach(() => {
    jest.resetModules();
    jest.clearAllMocks();
    jest.doMock('react-dom', () => ({
      version: '18.2.0',
    }));
    jest.doMock('react-dom/client', () => ({
      createRoot: mockCreateRoot,
      hydrateRoot: mockHydrateRoot,
    }));
  });

  const loadReactHydrateOrRender = (): typeof reactHydrateOrRenderType =>
    // eslint-disable-next-line @typescript-eslint/no-require-imports, global-require
    (require('../src/reactHydrateOrRender.ts') as { default: typeof reactHydrateOrRenderType }).default;

  it('passes options to createRoot for client renders', () => {
    const reactHydrateOrRender = loadReactHydrateOrRender();
    const domNode = document.createElement('div');
    const reactElement = React.createElement('div', null, 'client render');
    const options = { identifierPrefix: 'dom-id-123' };

    reactHydrateOrRender(domNode, reactElement, false, options);

    expect(mockCreateRoot).toHaveBeenCalledWith(domNode, options);
    expect(mockRender).toHaveBeenCalledWith(reactElement);
  });

  it('passes options to hydrateRoot for hydration', () => {
    const reactHydrateOrRender = loadReactHydrateOrRender();
    const domNode = document.createElement('div');
    const reactElement = React.createElement('div', null, 'hydrate');
    const options = { identifierPrefix: 'server-prefix-123' };

    reactHydrateOrRender(domNode, reactElement, true, options);

    expect(mockHydrateRoot).toHaveBeenCalledWith(domNode, reactElement, options);
  });
});
