"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var registeredStoreGenerators = new Map();
var hydratedStores = new Map();
exports.default = {
    /**
     * Register a store generator, a function that takes props and returns a store.
     * @param storeGenerators { name1: storeGenerator1, name2: storeGenerator2 }
     */
    register: function (storeGenerators) {
        Object.keys(storeGenerators).forEach(function (name) {
            if (registeredStoreGenerators.has(name)) {
                console.warn('Called registerStore for store that is already registered', name);
            }
            var store = storeGenerators[name];
            if (!store) {
                throw new Error('Called ReactOnRails.registerStores with a null or undefined as a value ' +
                    "for the store generator with key ".concat(name, "."));
            }
            registeredStoreGenerators.set(name, store);
        });
    },
    /**
     * Used by components to get the hydrated store which contains props.
     * @param name
     * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
     *        there is no store with the given name.
     * @returns Redux Store, possibly hydrated
     */
    getStore: function (name, throwIfMissing) {
        if (throwIfMissing === void 0) { throwIfMissing = true; }
        if (hydratedStores.has(name)) {
            return hydratedStores.get(name);
        }
        var storeKeys = Array.from(hydratedStores.keys()).join(', ');
        if (storeKeys.length === 0) {
            var msg = "There are no stores hydrated and you are requesting the store ".concat(name, ".\nThis can happen if you are server rendering and either:\n1. You do not call redux_store near the top of your controller action's view (not the layout)\n   and before any call to react_component.\n2. You do not render redux_store_hydration_data anywhere on your page.");
            throw new Error(msg);
        }
        if (throwIfMissing) {
            console.log('storeKeys', storeKeys);
            throw new Error("Could not find hydrated store with name '".concat(name, "'. ") +
                "Hydrated store names include [".concat(storeKeys, "]."));
        }
        return undefined;
    },
    /**
     * Internally used function to get the store creator that was passed to `register`.
     * @param name
     * @returns storeCreator with given name
     */
    getStoreGenerator: function (name) {
        if (registeredStoreGenerators.has(name)) {
            return registeredStoreGenerators.get(name);
        }
        var storeKeys = Array.from(registeredStoreGenerators.keys()).join(', ');
        throw new Error("Could not find store registered with name '".concat(name, "'. Registered store ") +
            "names include [ ".concat(storeKeys, " ]. Maybe you forgot to register the store?"));
    },
    /**
     * Internally used function to set the hydrated store after a Rails page is loaded.
     * @param name
     * @param store (not the storeGenerator, but the hydrated store)
     */
    setStore: function (name, store) {
        hydratedStores.set(name, store);
    },
    /**
     * Internally used function to completely clear hydratedStores Map.
     */
    clearHydratedStores: function () {
        hydratedStores.clear();
    },
    /**
     * Get a Map containing all registered store generators. Useful for debugging.
     * @returns Map where key is the component name and values are the store generators.
     */
    storeGenerators: function () {
        return registeredStoreGenerators;
    },
    /**
     * Get a Map containing all hydrated stores. Useful for debugging.
     * @returns Map where key is the component name and values are the hydrated stores.
     */
    stores: function () {
        return hydratedStores;
    },
};
