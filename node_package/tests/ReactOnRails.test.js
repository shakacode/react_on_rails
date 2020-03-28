/* eslint-disable react/no-multi-comp */
/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */
/* eslint-disable react/jsx-filename-extension */

import { createStore } from 'redux';
import React from 'react';
import createReactClass from 'create-react-class';
import ReactOnRails from '../src/ReactOnRails';

describe('ReactOnRails', () => {
  expect.assertions(14);
  it('render returns a virtual DOM element for component', () => {
    expect.assertions(1);
    const R1 = createReactClass({
      render() {
        return <div> WORLD </div>;
      },
    });
    ReactOnRails.register({ R1 });

    document.body.innerHTML = '<div id="root"></div>';
    // eslint-disable-next-line no-underscore-dangle
    const actual = ReactOnRails.render('R1', {}, 'root')._reactInternalFiber.type;
    expect(actual).toEqual(R1);
  });

  it('accepts traceTurbolinks as an option true', () => {
    ReactOnRails.resetOptions();
    expect.assertions(1);
    ReactOnRails.setOptions({ traceTurbolinks: true });
    const actual = ReactOnRails.option('traceTurbolinks');
    expect(actual).toBe(true);
  });

  it('accepts traceTurbolinks as an option false', () => {
    ReactOnRails.resetOptions();
    expect.assertions(1);
    ReactOnRails.setOptions({ traceTurbolinks: false });
    const actual = ReactOnRails.option('traceTurbolinks');
    expect(actual).toBe(false);
  });

  it('not specified has traceTurbolinks as false', () => {
    ReactOnRails.resetOptions();
    expect.assertions(1);
    ReactOnRails.setOptions({});
    const actual = ReactOnRails.option('traceTurbolinks');
    expect(actual).toBe(false);
  });

  it('setOptions method throws error for invalid options', () => {
    ReactOnRails.resetOptions();
    expect.assertions(1);
    expect(() => ReactOnRails.setOptions({ foobar: true })).toThrow(/Invalid option/);
  });

  it('registerStore throws if passed a falsey object (null, undefined, etc)', () => {
    expect.assertions(3);

    expect(() => ReactOnRails.registerStore(null)).toThrow(/null or undefined/);

    expect(() => ReactOnRails.registerStore(undefined)).toThrow(/null or undefined/);

    expect(() => ReactOnRails.registerStore(false)).toThrow(/null or undefined/);
  });

  it('register store and getStoreGenerator allow registration', () => {
    expect.assertions(2);
    function reducer() {
      return {};
    }

    function storeGenerator(props) {
      return createStore(reducer, props);
    }

    ReactOnRails.registerStore({ storeGenerator });

    const actual = ReactOnRails.getStoreGenerator('storeGenerator');
    expect(actual).toEqual(storeGenerator);

    expect(ReactOnRails.storeGenerators()).toEqual(new Map([['storeGenerator', storeGenerator]]));
  });

  it('setStore and getStore', () => {
    expect.assertions(2);
    function reducer() {
      return {};
    }

    function storeGenerator(props) {
      return createStore(reducer, props);
    }

    const store = storeGenerator({});

    ReactOnRails.setStore('storeGenerator', store);

    const actual = ReactOnRails.getStore('storeGenerator');
    expect(actual).toEqual(store);
    const expected = new Map();
    expected.set('storeGenerator', store);

    expect(ReactOnRails.stores()).toEqual(expected);
  });

  it('clearHydratedStores', () => {
    expect.assertions(2);
    function reducer() {
      return {};
    }

    function storeGenerator(props) {
      return createStore(reducer, props);
    }

    const result = storeGenerator({});
    ReactOnRails.setStore('storeGenerator', result);
    const actual = new Map();
    actual.set('storeGenerator', result);
    expect(actual).toEqual(ReactOnRails.stores());

    ReactOnRails.clearHydratedStores();
    const expected = new Map();
    expect(ReactOnRails.stores()).toEqual(expected);
  });
});
