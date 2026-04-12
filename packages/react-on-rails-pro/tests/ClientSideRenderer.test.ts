/**
 * @jest-environment jsdom
 */

import * as React from 'react';
import { resetRailsContext } from 'react-on-rails/context';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';
import * as StoreRegistry from '../src/StoreRegistry.ts';
import { renderOrHydrateComponent, hydrateStore, unmountAll } from '../src/ClientSideRenderer.ts';

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

  function setupTestStoreDom(storeName: string): Element {
    const storeDataElement = document.createElement('div');
    storeDataElement.setAttribute('data-js-react-on-rails-store', storeName);
    storeDataElement.textContent = JSON.stringify({ key: 'value' });
    document.body.appendChild(storeDataElement);
    return storeDataElement;
  }

  it('does not cache a component renderer created before railsContext exists', async () => {
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

  it('does not cache a store renderer created before railsContext exists', async () => {
    const storeGenerator = jest.fn((_props, _railsContext) => ({ getState: () => ({}) }));
    StoreRegistry.register({ TestStore: storeGenerator });
    const storeElement = setupTestStoreDom('TestStore');

    await hydrateStore(storeElement);
    expect(storeGenerator).not.toHaveBeenCalled();

    addRailsContext();
    await hydrateStore(storeElement);
    expect(storeGenerator).toHaveBeenCalledTimes(1);
  });
});
