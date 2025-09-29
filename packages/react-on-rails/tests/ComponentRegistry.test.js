/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */
/* eslint-disable react/jsx-filename-extension */
/* eslint-disable no-unused-vars */

import * as React from 'react';
import * as createReactClass from 'create-react-class';

import * as ComponentRegistry from '../src/pro/ComponentRegistry.ts';

const onPageLoadedCallbacks = [];
const onPageUnloadedCallbacks = [];

jest.mock('../src/pageLifecycle.ts', () => ({
  onPageLoaded: jest.fn((cb) => {
    onPageLoadedCallbacks.push(cb);
    cb();
  }),
  onPageUnloaded: jest.fn((cb) => {
    onPageUnloadedCallbacks.push(cb);
    cb();
  }),
}));

jest.mock('../src/context.ts', () => ({
  getRailsContext: () => ({ componentRegistryTimeout: 100 }),
}));

describe('ComponentRegistry', () => {
  beforeEach(() => {
    ComponentRegistry.clear();
    onPageLoadedCallbacks.forEach((cb) => cb());
  });

  afterEach(() => {
    onPageUnloadedCallbacks.forEach((cb) => cb());
  });

  it('registers and retrieves React function components', () => {
    const C1 = () => <div>HELLO</div>;
    ComponentRegistry.register({ C1 });
    const actual = ComponentRegistry.get('C1');
    const expected = { name: 'C1', component: C1, renderFunction: false, isRenderer: false };
    expect(actual).toEqual(expected);
  });

  it('registers and retrieves Render-Function components where property renderFunction is set and zero params', () => {
    const C1 = () => <div>HELLO</div>;
    C1.renderFunction = true;
    ComponentRegistry.register({ C1 });
    const actual = ComponentRegistry.get('C1');
    const expected = { name: 'C1', component: C1, renderFunction: true, isRenderer: false };
    expect(actual).toEqual(expected);
  });

  it('registers and retrieves ES5 class components', () => {
    const C2 = createReactClass({
      render() {
        return <div> WORLD </div>;
      },
    });
    ComponentRegistry.register({ C2 });
    const actual = ComponentRegistry.get('C2');
    const expected = { name: 'C2', component: C2, renderFunction: false, isRenderer: false };
    expect(actual).toEqual(expected);
  });

  it('registers and retrieves ES6 class components', () => {
    class C3 extends React.Component {
      render() {
        return <div>Wow!</div>;
      }
    }
    ComponentRegistry.register({ C3 });
    const actual = ComponentRegistry.get('C3');
    const expected = { name: 'C3', component: C3, renderFunction: false, isRenderer: false };
    expect(actual).toEqual(expected);
  });

  it('registers and retrieves renderers if 3 params', () => {
    const C4 = (a1, a2, a3) => null;
    ComponentRegistry.register({ C4 });
    const actual = ComponentRegistry.get('C4');
    const expected = { name: 'C4', component: C4, renderFunction: true, isRenderer: true };
    expect(actual).toEqual(expected);
  });

  /*
   * NOTE: Since is a singleton, it preserves value as the tests run.
   * Thus, tests are cumulative.
   */
  it('registers and retrieves multiple components', () => {
    // Plain react stateless functional components
    const C5 = () => <div>WHY</div>;
    const C6 = () => <div>NOW</div>;
    const C7 = () => <div>NOW</div>;
    C7.renderFunction = true;
    ComponentRegistry.register({ C5 });
    ComponentRegistry.register({ C6 });
    ComponentRegistry.register({ C7 });
    const components = ComponentRegistry.components();
    expect(components.size).toBe(3);
    expect(components.get('C5')).toEqual({
      name: 'C5',
      component: C5,
      renderFunction: false,
      isRenderer: false,
    });
    expect(components.get('C6')).toEqual({
      name: 'C6',
      component: C6,
      renderFunction: false,
      isRenderer: false,
    });
    expect(components.get('C7')).toEqual({
      name: 'C7',
      component: C7,
      renderFunction: true,
      isRenderer: false,
    });
  });

  it('only detects a renderer function if it has three arguments', () => {
    const C7 = (a1, a2) => null;
    const C8 = (a1) => null;
    ComponentRegistry.register({ C7 });
    ComponentRegistry.register({ C8 });
    const components = ComponentRegistry.components();
    expect(components.get('C7')).toEqual({
      name: 'C7',
      component: C7,
      renderFunction: true,
      isRenderer: false,
    });
    expect(components.get('C8')).toEqual({
      name: 'C8',
      component: C8,
      renderFunction: false,
      isRenderer: false,
    });
  });

  it('throws error for retrieving unregistered component', () => {
    expect(() => ComponentRegistry.get('foobar')).toThrow(
      /Could not find component registered with name foobar/,
    );
  });

  it('throws error for setting null component', () => {
    const C9 = null;
    expect(() => ComponentRegistry.register({ C9 })).toThrow(/Called register with null component named C9/);
  });

  it('retrieves component asynchronously when registered later', async () => {
    const C1 = () => <div>HELLO</div>;
    const componentPromise = ComponentRegistry.getOrWaitForComponent('C1');
    ComponentRegistry.register({ C1 });
    const component = await componentPromise;
    expect(component).toEqual({
      name: 'C1',
      component: C1,
      renderFunction: false,
      isRenderer: false,
    });
  });

  it('handles timeout for unregistered components', async () => {
    let error;
    try {
      await ComponentRegistry.getOrWaitForComponent('NonExistent');
    } catch (e) {
      error = e;
    }
    expect(error.message).toMatch(/Could not find component/);
  });
});
