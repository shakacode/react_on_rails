/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */

import { createStore } from 'redux';
import * as React from 'react';
import * as createReactClass from 'create-react-class';
import ReactOnRails from '../src/ReactOnRails.client.ts';
import ComponentRegistry from '../src/ComponentRegistry.ts';
import StoreRegistry from '../src/StoreRegistry.ts';

describe('ReactOnRails', () => {
  afterEach(() => {
    ComponentRegistry.clear();
    StoreRegistry.storeGenerators().clear();
    StoreRegistry.stores().clear();
  });

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

  it('rejects renderer functions passed to manual render without invoking them', () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    try {
      // 3-argument arity makes ComponentRegistry classify this as a renderer (isRenderer === true).
      const renderer = jest.fn();
      function ManualRenderer(props, railsContext, domNodeId) {
        return renderer(props, railsContext, domNodeId);
      }
      ReactOnRails.register({ ManualRenderer });

      const root = document.createElement('div');
      root.id = 'manual-renderer-root';
      document.body.innerHTML = '';
      document.body.appendChild(root);

      expect(() => ReactOnRails.render('ManualRenderer', {}, 'manual-renderer-root')).toThrow(
        'ReactOnRails.render() does not support renderer functions ("ManualRenderer").',
      );
      // The renderer is rejected *before* it is invoked, so it can't create a leaked mount, and the
      // failure surfaces only through the thrown error — not a confusing console.error on a path that
      // already throws.
      expect(renderer).not.toHaveBeenCalled();
      expect(consoleErrorSpy).not.toHaveBeenCalled();
    } finally {
      consoleErrorSpy.mockRestore();
    }
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
    expect(() => ReactOnRails.setOptions({ foobar: true })).toThrow(/Invalid option/);
  });

  it('setOptions accepts rootErrorHandlers and resetOptions clears them', () => {
    // eslint-disable-next-line global-require
    const { getRootErrorHandlers } = require('../src/rootErrorHandlers.ts');
    ReactOnRails.resetOptions();
    const onRecoverableError = jest.fn();
    const onUncaughtError = jest.fn();
    ReactOnRails.setOptions({ rootErrorHandlers: { onRecoverableError, onUncaughtError } });

    expect(ReactOnRails.option('rootErrorHandlers')).toEqual({ onRecoverableError, onUncaughtError });
    // setOptions writes through to the module-level registration the renderers read.
    expect(getRootErrorHandlers().onRecoverableError).toBe(onRecoverableError);
    expect(getRootErrorHandlers().onUncaughtError).toBe(onUncaughtError);

    ReactOnRails.resetOptions();
    expect(ReactOnRails.option('rootErrorHandlers')).toBeUndefined();
    expect(getRootErrorHandlers()).toEqual({});
  });

  it('setOptions throws when a rootErrorHandlers entry is not a function', () => {
    ReactOnRails.resetOptions();
    expect(() => ReactOnRails.setOptions({ rootErrorHandlers: { onCaughtError: 'nope' } })).toThrow(
      /onCaughtError must be a function/,
    );
  });

  it('setOptions merges partial rootErrorHandlers updates per key', () => {
    // eslint-disable-next-line global-require
    const { getRootErrorHandlers } = require('../src/rootErrorHandlers.ts');
    ReactOnRails.resetOptions();
    const onRecoverableError = jest.fn();
    const onUncaughtError = jest.fn();
    ReactOnRails.setOptions({ rootErrorHandlers: { onRecoverableError } });
    // A later call that sets only another key must not drop the earlier registration
    // (consistent with how traceTurbolinks/turbo update independently).
    ReactOnRails.setOptions({ rootErrorHandlers: { onUncaughtError } });

    expect(getRootErrorHandlers()).toEqual({ onRecoverableError, onUncaughtError });
    expect(ReactOnRails.option('rootErrorHandlers')).toEqual({ onRecoverableError, onUncaughtError });

    ReactOnRails.resetOptions();
  });

  it('setOptions clears all rootErrorHandlers when rootErrorHandlers is explicitly undefined', () => {
    // eslint-disable-next-line global-require
    const { getRootErrorHandlers } = require('../src/rootErrorHandlers.ts');
    ReactOnRails.resetOptions();
    const onRecoverableError = jest.fn();

    ReactOnRails.setOptions({ rootErrorHandlers: { onRecoverableError } });
    ReactOnRails.setOptions({ rootErrorHandlers: undefined });

    expect(ReactOnRails.option('rootErrorHandlers')).toBeUndefined();
    expect(getRootErrorHandlers()).toEqual({});
  });

  it('deprecated base client clears all rootErrorHandlers when rootErrorHandlers is explicitly undefined', () => {
    jest.isolateModules(() => {
      // eslint-disable-next-line global-require
      const { createBaseClientObject } = require('../src/base/client.ts');
      // eslint-disable-next-line global-require
      const { getRootErrorHandlers } = require('../src/rootErrorHandlers.ts');
      const registries = {
        ComponentRegistry: {
          register: jest.fn(),
          get: jest.fn(),
          components: jest.fn(() => new Map()),
        },
        StoreRegistry: {
          register: jest.fn(),
          getStore: jest.fn(),
          getStoreGenerator: jest.fn(),
          setStore: jest.fn(),
          clearHydratedStores: jest.fn(),
          storeGenerators: jest.fn(() => new Map()),
          stores: jest.fn(() => new Map()),
        },
      };
      const baseClient = createBaseClientObject(registries);
      const onRecoverableError = jest.fn();

      baseClient.resetOptions();
      baseClient.setOptions({ rootErrorHandlers: { onRecoverableError } });
      baseClient.setOptions({ rootErrorHandlers: undefined });

      expect(baseClient.option('rootErrorHandlers')).toBeUndefined();
      expect(getRootErrorHandlers()).toEqual({});
    });
  });

  it('registerStore throws if passed a falsey object (null, undefined, etc)', () => {
    expect(() => ReactOnRails.registerStore(null)).toThrow(/null or undefined/);

    expect(() => ReactOnRails.registerStore(undefined)).toThrow(/null or undefined/);

    expect(() => ReactOnRails.registerStore(false)).toThrow(/null or undefined/);
  });

  it('registerStoreGenerators and getStoreGenerator allow legacy Redux-compatible registration', () => {
    function reducer() {
      return {};
    }

    function storeGenerator(props) {
      return createStore(reducer, props);
    }

    ReactOnRails.registerStoreGenerators({ storeGenerator });

    const actual = ReactOnRails.getStoreGenerator('storeGenerator');
    expect(actual).toEqual(storeGenerator);

    expect(ReactOnRails.storeGenerators()).toEqual(new Map([['storeGenerator', storeGenerator]]));
  });

  it('registerStore remains a deprecated alias for store generator registration', () => {
    function reducer() {
      return {};
    }

    function storeGenerator(props) {
      return createStore(reducer, props);
    }

    ReactOnRails.registerStore({ storeGenerator });

    expect(ReactOnRails.getStoreGenerator('storeGenerator')).toEqual(storeGenerator);
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
