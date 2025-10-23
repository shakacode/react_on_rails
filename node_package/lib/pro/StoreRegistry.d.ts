import type { Store, StoreGenerator } from '../types/index.ts';
/**
 * Register a store generator, a function that takes props and returns a store.
 * @param storeGenerators { name1: storeGenerator1, name2: storeGenerator2 }
 */
export declare function register(storeGenerators: Record<string, StoreGenerator>): void;
/**
 * Used by components to get the hydrated store which contains props.
 * @param name
 * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
 *        there is no store with the given name.
 * @returns Redux Store, possibly hydrated
 */
export declare function getStore(name: string, throwIfMissing?: boolean): Store | undefined;
/**
 * Internally used function to get the store creator that was passed to `register`.
 * @param name
 * @returns storeCreator with given name
 */
export declare const getStoreGenerator: (name: string) => StoreGenerator;
/**
 * Internally used function to set the hydrated store after a Rails page is loaded.
 * @param name
 * @param store (not the storeGenerator, but the hydrated store)
 */
export declare function setStore(name: string, store: Store): void;
/**
 * Internally used function to completely clear hydratedStores Map.
 */
export declare function clearHydratedStores(): void;
/**
 * Get a Map containing all registered store generators. Useful for debugging.
 * @returns Map where key is the component name and values are the store generators.
 */
export declare const storeGenerators: () => Map<string, StoreGenerator>;
/**
 * Get a Map containing all hydrated stores. Useful for debugging.
 * @returns Map where key is the component name and values are the hydrated stores.
 */
export declare const stores: () => Map<string, Store>;
/**
 * Used by components to get the hydrated store, waiting for it to be hydrated if necessary.
 * @param name Name of the store to wait for
 * @returns Promise that resolves with the Store once hydrated
 */
export declare const getOrWaitForStore: (name: string) => Promise<Store>;
/**
 * Used by components to get the store generator, waiting for it to be registered if necessary.
 * @param name Name of the store generator to wait for
 * @returns Promise that resolves with the StoreGenerator once registered
 */
export declare const getOrWaitForStoreGenerator: (name: string) => Promise<StoreGenerator>;
