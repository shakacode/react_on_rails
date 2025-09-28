import { createStore } from 'redux';

import * as StoreRegistry from '../src/pro/StoreRegistry.ts';

function reducer() {
  return {};
}

function storeGenerator(props) {
  return createStore(reducer, props);
}

function storeGenerator2(props) {
  return createStore(reducer, props);
}

describe('StoreRegistry', () => {
  beforeEach(() => {
    StoreRegistry.stores().clear();
  });

  it('StoreRegistry throws error for registering null or undefined store', () => {
    expect(() => StoreRegistry.register({ storeGenerator: null })).toThrow(
      /Called ReactOnRails.registerStoreGenerators with a null or undefined as a value/,
    );
    expect(() => StoreRegistry.register({ storeGenerator: undefined })).toThrow(
      /Called ReactOnRails.registerStoreGenerators with a null or undefined as a value/,
    );
  });

  it('StoreRegistry throws error for retrieving unregistered store', () => {
    expect(() => StoreRegistry.getStore('foobar')).toThrow(
      /There are no stores hydrated and you are requesting the store/,
    );
  });

  it('StoreRegistry registers and retrieves Render-Function stores', () => {
    StoreRegistry.register({ storeGenerator, storeGenerator2 });
    const actual = StoreRegistry.getStoreGenerator('storeGenerator');
    const expected = storeGenerator;
    expect(actual).toEqual(expected);
    const actual2 = StoreRegistry.getStoreGenerator('storeGenerator2');
    const expected2 = storeGenerator2;
    expect(actual2).toEqual(expected2);
  });

  it('StoreRegistry throws error for retrieving unregistered store generator', () => {
    expect(() => StoreRegistry.getStoreGenerator('foobar')).toThrow(
      /Could not find store generator registered with name foobar\. Registered store generator names include/,
    );
  });

  it('StoreRegistry returns undefined for retrieving unregistered store, passing throwIfMissing = false', () => {
    StoreRegistry.setStore('foobarX', {});
    const actual = StoreRegistry.getStore('foobar', false);
    const expected = undefined;
    expect(actual).toEqual(expected);
  });

  it('StoreRegistry getStore, setStore', () => {
    const store = storeGenerator({});
    StoreRegistry.setStore('storeGenerator', store);
    const actual = StoreRegistry.getStore('storeGenerator');
    const expected = store;
    expect(actual).toEqual(expected);
  });

  it('StoreRegistry throws error for retrieving unregistered hydrated store', () => {
    expect(() => StoreRegistry.getStore('foobar')).toThrow(
      /Could not find hydrated store registered with name foobar\. Registered hydrated store names include/,
    );
  });

  it('StoreRegistry clearHydratedStores', () => {
    StoreRegistry.clearHydratedStores();

    const result = storeGenerator({});
    StoreRegistry.setStore('storeGenerator', result);
    const actual = new Map();
    actual.set('storeGenerator', result);
    expect(actual).toEqual(StoreRegistry.stores());

    StoreRegistry.clearHydratedStores();
    const expected = new Map();
    expect(StoreRegistry.stores()).toEqual(expected);
  });
});
