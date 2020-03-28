import { createStore } from 'redux';

import StoreRegistry from '../src/StoreRegistry';

function reducer() {
  return {};
}

function storeGenerator(props) {
  return createStore(reducer, props);
}

function storeGenerator2(props) {
  return createStore(reducer, props);
}

describe('', () => {
  expect.assertions(11);
  it('StoreRegistry throws error for registering null or undefined store', () => {
    expect.assertions(2);
    StoreRegistry.stores().clear();
    expect(() => StoreRegistry.register({ storeGenerator: null })).toThrow(
      /Called ReactOnRails.registerStores with a null or undefined as a value/
    );
    expect(() => StoreRegistry.register({ storeGenerator: undefined })).toThrow(
      /Called ReactOnRails.registerStores with a null or undefined as a value/,
    );
  });

  it('StoreRegistry throws error for retrieving unregistered store', () => {
    expect.assertions(1);
    StoreRegistry.stores().clear();
    expect(() => StoreRegistry.getStore('foobar')).toThrow(
      /There are no stores hydrated and you are requesting the store/,
    );
  });

  it('StoreRegistry registers and retrieves generator function stores', () => {
    expect.assertions(2);
    StoreRegistry.register({ storeGenerator, storeGenerator2 });
    const actual = StoreRegistry.getStoreGenerator('storeGenerator');
    const expected = storeGenerator;
    expect(actual).toEqual(expected);
    const actual2 = StoreRegistry.getStoreGenerator('storeGenerator2');
    const expected2 = storeGenerator2;
    expect(actual2).toEqual(expected2);
  });

  it('StoreRegistry throws error for retrieving unregistered store', () => {
    expect.assertions(1);
    expect(() => StoreRegistry.getStoreGenerator('foobar')).toThrow(
      /Could not find store registered with name 'foobar'\. Registered store names include/,
    );
  });

  it('StoreRegistry returns undefined for retrieving unregistered store, ' +
    'passing throwIfMissing = false',
  () => {
    expect.assertions(1);
    StoreRegistry.setStore('foobarX', {});
    const actual = StoreRegistry.getStore('foobar', false);
    const expected = undefined;
    expect(actual).toEqual(expected);
  },
  );

  it('StoreRegistry getStore, setStore', () => {
    expect.assertions(1);
    const store = storeGenerator({});
    StoreRegistry.setStore('storeGenerator', store);
    const actual = StoreRegistry.getStore('storeGenerator');
    const expected = store;
    expect(actual).toEqual(expected);
  });

  it('StoreRegistry throws error for retrieving unregistered hydrated store', () => {
    expect.assertions(1);
    expect(() => StoreRegistry.getStore('foobar')).toThrow(
      /Could not find hydrated store with name 'foobar'\. Hydrated store names include/,
    );
  });

  it('StoreRegistry clearHydratedStores', () => {
    expect.assertions(2);
    StoreRegistry.stores().clear();

    const result = storeGenerator({});
    StoreRegistry.setStore('storeGenerator', result);
    const actual = new Map();
    actual.set('storeGenerator', result);
    expect(actual).toEqual(StoreRegistry.stores());

    StoreRegistry.clearHydratedStores();
    const expected = new Map();
    expect(StoreRegistry.stores()).toEqual(expected);
  })
})
