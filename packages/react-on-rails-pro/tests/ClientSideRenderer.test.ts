/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import { resetRailsContext } from 'react-on-rails/context';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';
import { renderOrHydrateComponent, unmountAll } from '../src/ClientSideRenderer.ts';

jest.mock('react-on-rails/reactHydrateOrRender', () => ({
  __esModule: true,
  default: jest.fn(),
}));

describe('ClientSideRenderer', () => {
  const mockReactHydrateOrRender = jest.requireMock('react-on-rails/reactHydrateOrRender')
    .default as jest.Mock;

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

  function addRailsContext(): void {
    const railsContext = document.createElement('div');
    railsContext.id = 'js-react-on-rails-context';
    railsContext.textContent = JSON.stringify({
      serverSide: false,
      rorPro: true,
    });
    document.body.appendChild(railsContext);
  }

  it('does not cache a renderer created before railsContext exists', async () => {
    ComponentRegistry.register({
      TestComponent: ({ greeting }: { greeting: string }) => React.createElement('div', null, greeting),
    });
    const componentSpec = setupTestComponentDom('dom-id-123');

    await renderOrHydrateComponent(componentSpec);
    expect(mockReactHydrateOrRender).not.toHaveBeenCalled();

    addRailsContext();
    await renderOrHydrateComponent(componentSpec);
    expect(mockReactHydrateOrRender).toHaveBeenCalledTimes(1);
  });
});
