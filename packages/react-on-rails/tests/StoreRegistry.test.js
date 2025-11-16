import { createStore } from 'redux';

import StoreRegistry from '../src/StoreRegistry.ts';

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
    StoreRegistry.storeGenerators().clear();
  });

  it('StoreRegistry throws error for registering null or undefined store', () => {
    expect(() => StoreRegistry.register({ storeGenerator: null })).toThrow(
      /Called ReactOnRails.registerStores with a null or undefined as a value/,
    );
    expect(() => StoreRegistry.register({ storeGenerator: undefined })).toThrow(
      /Called ReactOnRails.registerStores with a null or undefined as a value/,
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
      /Could not find store registered with name 'foobar'\. Registered store names include/,
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
    StoreRegistry.setStore('someStore', {});
    expect(() => StoreRegistry.getStore('foobar')).toThrow(
      /Could not find hydrated store with name 'foobar'\. Hydrated store names include/,
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

  it('StoreRegistry throws error for getOrWaitForStore (Pro-only method)', () => {
    expect(() => StoreRegistry.getOrWaitForStore('testStore')).toThrow(
      /getOrWaitForStore\('testStore'\) is only available with React on Rails Pro/,
    );
  });

  it('StoreRegistry throws error for getOrWaitForStoreGenerator (Pro-only method)', () => {
    expect(() => StoreRegistry.getOrWaitForStoreGenerator('testStoreGen')).toThrow(
      /getOrWaitForStoreGenerator\('testStoreGen'\) is only available with React on Rails Pro/,
    );
  });

  it('StoreRegistry returns correct storeGenerators Map', () => {
    StoreRegistry.register({ storeGenerator, storeGenerator2 });
    const actual = StoreRegistry.storeGenerators();
    expect(actual.get('storeGenerator')).toEqual(storeGenerator);
    expect(actual.get('storeGenerator2')).toEqual(storeGenerator2);
    expect(actual.size).toBe(2);
  });

  it('StoreRegistry returns correct stores Map', () => {
    const store1 = storeGenerator({});
    const store2 = storeGenerator2({});
    StoreRegistry.setStore('store1', store1);
    StoreRegistry.setStore('store2', store2);
    const actual = StoreRegistry.stores();
    expect(actual.get('store1')).toEqual(store1);
    expect(actual.get('store2')).toEqual(store2);
    expect(actual.size).toBe(2);
  });
});
