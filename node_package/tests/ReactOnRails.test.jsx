/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */

import { createStore } from 'redux';
import * as React from 'react';
import * as createReactClass from 'create-react-class';
import ReactOnRails from '../src/ReactOnRails.client.ts';

describe('ReactOnRails', () => {
  it('render returns a virtual DOM element for component', () => {
    const R1 = createReactClass({
      render() {
        return <div> WORLD </div>;
      },
    });
    ReactOnRails.register({ R1 });

    const root = document.createElement('div');
    root.id = 'root';
    root.textContent = ' WORLD ';

    document.body.innerHTML = '';
    document.body.appendChild(root);
    ReactOnRails.render('R1', {}, 'root');

    expect(document.getElementById('root').textContent).toBe(' WORLD ');
  });

  it('accepts traceTurbolinks as an option true', () => {
    ReactOnRails.resetOptions();
    ReactOnRails.setOptions({ traceTurbolinks: true });
    const actual = ReactOnRails.option('traceTurbolinks');
    expect(actual).toBe(true);
  });

  it('accepts traceTurbolinks as an option false', () => {
    ReactOnRails.resetOptions();
    ReactOnRails.setOptions({ traceTurbolinks: false });
    const actual = ReactOnRails.option('traceTurbolinks');
    expect(actual).toBe(false);
  });

  it('not specified has traceTurbolinks as false', () => {
    ReactOnRails.resetOptions();
    ReactOnRails.setOptions({});
    const actual = ReactOnRails.option('traceTurbolinks');
    expect(actual).toBe(false);
  });

  it('setOptions method throws error for invalid options', () => {
    ReactOnRails.resetOptions();
    expect(() => ReactOnRails.setOptions({ foobar: true })).toThrow(/Invalid options/);
  });

  it('setOptions allows setting multiple options at once', () => {
    ReactOnRails.resetOptions();
    ReactOnRails.setOptions({ 
      traceTurbolinks: true, 
      rscPayloadGenerationUrlPath: '/custom_rsc' 
    });
    expect(ReactOnRails.option('traceTurbolinks')).toBe(true);
    expect(ReactOnRails.option('rscPayloadGenerationUrlPath')).toBe('/custom_rsc');
  });

  it('setOptions preserves unspecified options when setting specific ones', () => {
    ReactOnRails.resetOptions();
    
    ReactOnRails.setOptions({ 
      traceTurbolinks: true,
      turbo: true,
      rscPayloadGenerationUrlPath: '/custom_rsc'
    });
    
    ReactOnRails.setOptions({ 
      rscPayloadGenerationUrlPath: '/different_path' 
    });
    
    expect(ReactOnRails.option('rscPayloadGenerationUrlPath')).toBe('/different_path');
    
    expect(ReactOnRails.option('traceTurbolinks')).toBe(true);
    expect(ReactOnRails.option('turbo')).toBe(true);
  });

  it('setOptions ignores undefined values', () => {
    ReactOnRails.resetOptions();
    ReactOnRails.setOptions({
      traceTurbolinks: true,
      turbo: true,
      rscPayloadGenerationUrlPath: '/custom_rsc'
    });
    
    ReactOnRails.setOptions({
      rscPayloadGenerationUrlPath: undefined
    });
  
    expect(ReactOnRails.option('rscPayloadGenerationUrlPath')).toBe('/custom_rsc');
    expect(ReactOnRails.option('traceTurbolinks')).toBe(true);
    expect(ReactOnRails.option('turbo')).toBe(true);
  });

  it('registerStore throws if passed a falsey object (null, undefined, etc)', () => {
    expect(() => ReactOnRails.registerStore(null)).toThrow(/null or undefined/);

    expect(() => ReactOnRails.registerStore(undefined)).toThrow(/null or undefined/);

    expect(() => ReactOnRails.registerStore(false)).toThrow(/null or undefined/);
  });

  it('register store and getStoreGenerator allow registration', () => {
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
