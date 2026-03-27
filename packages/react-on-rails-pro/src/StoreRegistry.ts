/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import type { Store, StoreGenerator } from 'react-on-rails/types';
import CallbackRegistry from './CallbackRegistry.ts';

const storeGeneratorRegistry = new CallbackRegistry<StoreGenerator>('store generator');
const hydratedStoreRegistry = new CallbackRegistry<Store>('hydrated store');

/**
 * Register a store generator, a function that takes props and returns a store.
 * @param storeGenerators { name1: storeGenerator1, name2: storeGenerator2 }
 * @public
 */
export function register(storeGenerators: Record<string, StoreGenerator>): void {
  Object.keys(storeGenerators).forEach((name) => {
    const storeGenerator = storeGenerators[name];
    if (!storeGenerator) {
      throw new Error(
        'Called ReactOnRails.registerStoreGenerators with a null or undefined as a value ' +
          `for the store generator with key ${name}.`,
      );
    }

    // Reference comparison lets HMR re-register the same store silently
    // while still catching bugs where different stores share a name.
    const existing = storeGeneratorRegistry.getIfExists(name);
    if (existing && existing !== storeGenerator) {
      console.error(
        `ReactOnRails: Store "${name}" was registered with a different store generator than previously. ` +
          'This is likely a bug — ensure each store has a unique registration name.',
      );
    }

    storeGeneratorRegistry.set(name, storeGenerator);
  });
}

/**
 * Used by components to get the hydrated store which contains props.
 * @param name
 * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
 *        there is no store with the given name.
 * @returns Redux Store, possibly hydrated
 * @public
 */
export function getStore(name: string, throwIfMissing = true): Store | undefined {
  try {
    return hydratedStoreRegistry.get(name);
  } catch (error) {
    if (hydratedStoreRegistry.getAll().size === 0) {
      const msg = `There are no stores hydrated and you are requesting the store ${name}.
This can happen if you are server rendering and either:
1. You do not call redux_store near the top of your controller action's view (not the layout)
   and before any call to react_component.
2. You do not render redux_store_hydration_data anywhere on your page.`;
      throw new Error(msg);
    }

    if (throwIfMissing) {
      throw error;
    }
    return undefined;
  }
}

/**
 * Internally used function to get the store creator that was passed to `register`.
 * @param name
 * @returns storeCreator with given name
 * @public
 */
export const getStoreGenerator = (name: string): StoreGenerator => storeGeneratorRegistry.get(name);

/**
 * Internally used function to set the hydrated store after a Rails page is loaded.
 * @param name
 * @param store (not the storeGenerator, but the hydrated store)
 */
export function setStore(name: string, store: Store): void {
  hydratedStoreRegistry.set(name, store);
}

/**
 * Internally used function to completely clear hydratedStores Map.
 * @public
 */
export function clearHydratedStores(): void {
  hydratedStoreRegistry.clear();
}

/**
 * Get a Map containing all registered store generators. Useful for debugging.
 * @returns Map where key is the component name and values are the store generators.
 * @public
 */
export const storeGenerators = (): Map<string, StoreGenerator> => storeGeneratorRegistry.getAll();

/**
 * Get a Map containing all hydrated stores. Useful for debugging.
 * @returns Map where key is the component name and values are the hydrated stores.
 * @public
 */
export const stores = (): Map<string, Store> => hydratedStoreRegistry.getAll();

/**
 * Used by components to get the hydrated store, waiting for it to be hydrated if necessary.
 * @param name Name of the store to wait for
 * @returns Promise that resolves with the Store once hydrated
 */
export const getOrWaitForStore = (name: string): Promise<Store> =>
  hydratedStoreRegistry.getOrWaitForItem(name);

/**
 * Used by components to get the store generator, waiting for it to be registered if necessary.
 * @param name Name of the store generator to wait for
 * @returns Promise that resolves with the StoreGenerator once registered
 */
export const getOrWaitForStoreGenerator = (name: string): Promise<StoreGenerator> =>
  storeGeneratorRegistry.getOrWaitForItem(name);
