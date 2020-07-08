/* eslint-disable react/no-multi-comp */
/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */
/* eslint-disable react/jsx-filename-extension */
/* eslint-disable no-unused-vars */
/* eslint-disable import/extensions */

import React from 'react';
import createReactClass from 'create-react-class';

import ComponentRegistry from '../src/ComponentRegistry';

describe('ComponentRegistry', () => {
  beforeEach(() => {
    ComponentRegistry.components().clear();
  });

  it('registers and retrieves React function components', () => {
    expect.assertions(1);
    const C1 = () => <div>HELLO</div>;
    ComponentRegistry.register({ C1 });
    const actual = ComponentRegistry.get('C1');
    const expected = { name: 'C1', component: C1, renderFunction: false, isRenderer: false };
    expect(actual).toEqual(expected);
  });

  it('registers and retrieves Render-Function components where property renderFunction is set and zero params', () => {
    expect.assertions(1);
    const C1 = () => <div>HELLO</div>;
    C1.renderFunction = true;
    ComponentRegistry.register({ C1 });
    const actual = ComponentRegistry.get('C1');
    const expected = { name: 'C1', component: C1, renderFunction: true, isRenderer: false };
    expect(actual).toEqual(expected);
  });

  it('registers and retrieves ES5 class components', () => {
    expect.assertions(1);
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
    expect.assertions(1);
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
    expect.assertions(1);
    const C4 = (a1, a2, a3) => null;
    ComponentRegistry.register({ C4 });
    const actual = ComponentRegistry.get('C4');
    const expected = { name: 'C4', component: C4, renderFunction: true, isRenderer: true };
    expect(actual).toEqual(expected);
  });

  /*
   * NOTE: Since is a singleton, it preserves value as the tests run.
   * Thus, tests are cummulative.
   */
  it('registers and retrieves multiple components', () => {
    expect.assertions(4);
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
    expect.assertions(2);
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
    expect.assertions(1);
    expect(() => ComponentRegistry.get('foobar')).toThrow(
      /Could not find component registered with name foobar/,
    );
  });

  it('throws error for setting null component', () => {
    expect.assertions(1);
    const C9 = null;
    expect(() => ComponentRegistry.register({ C9 })).toThrow(/Called register with null component named C9/);
  });
});
