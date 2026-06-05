/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import { resetRailsContext } from 'react-on-rails/context';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';
import { renderOrHydrateComponent, unmountAll } from '../src/ClientSideRenderer.ts';

jest.mock('react-on-rails/reactApis', () => ({
  supportsHydrate: false,
  supportsRootApi: false,
  unmountComponentAtNode: jest.fn(() => true),
}));

jest.mock('react-on-rails/reactHydrateOrRender', () => ({
  __esModule: true,
  default: jest.fn(),
}));

describe('ClientSideRenderer legacy React unmount behavior', () => {
  const mockReactHydrateOrRender = jest.requireMock('react-on-rails/reactHydrateOrRender')
    .default as jest.Mock;
  const { unmountComponentAtNode } = jest.requireMock('react-on-rails/reactApis') as {
    unmountComponentAtNode: jest.Mock;
  };

  beforeEach(() => {
    ComponentRegistry.clear();
    unmountAll();
    resetRailsContext();
    document.body.innerHTML = '';
    document.head.innerHTML = '';
    jest.clearAllMocks();
  });

  afterEach(() => {
    ComponentRegistry.clear();
    unmountAll();
    resetRailsContext();
  });

  function addRailsContext(): void {
    const railsContext = document.createElement('div');
    railsContext.id = 'js-react-on-rails-context';
    railsContext.textContent = JSON.stringify({
      serverSide: false,
      rorPro: true,
    });
    document.body.appendChild(railsContext);
  }

  function setupTestComponentDom(domId: string): Element {
    const componentSpec = document.createElement('div');
    componentSpec.className = 'js-react-on-rails-component';
    componentSpec.setAttribute('data-component-name', 'TestComponent');
    componentSpec.setAttribute('data-dom-id', domId);
    componentSpec.textContent = JSON.stringify({ greeting: 'hello' });
    document.body.appendChild(componentSpec);

    const mountNode = document.createElement('div');
    mountNode.id = domId;
    document.body.appendChild(mountNode);
    return componentSpec;
  }

  it('unmounts the old stored node when a same-id node is replaced', async () => {
    ComponentRegistry.register({
      TestComponent: ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting),
    });
    const componentSpec = setupTestComponentDom('dom-id-legacy-replace');
    addRailsContext();

    await renderOrHydrateComponent(componentSpec);
    expect(mockReactHydrateOrRender).toHaveBeenCalledTimes(1);

    const oldMountNode = document.getElementById('dom-id-legacy-replace');
    expect(oldMountNode).not.toBeNull();
    const newMountNode = document.createElement('div');
    newMountNode.id = 'dom-id-legacy-replace';
    oldMountNode?.replaceWith(newMountNode);

    await renderOrHydrateComponent(componentSpec);

    expect(unmountComponentAtNode).toHaveBeenCalledTimes(1);
    const legacyUnmountNode = unmountComponentAtNode.mock.calls[0][0];
    expect(legacyUnmountNode).toBe(oldMountNode);
    expect(legacyUnmountNode).not.toBe(newMountNode);
    expect(mockReactHydrateOrRender).toHaveBeenCalledTimes(2);
    expect(mockReactHydrateOrRender.mock.calls[1][0]).toBe(newMountNode);
  });
});
