import * as Authenticity from "../Authenticity.js";
import buildConsoleReplay, { consoleReplay } from "../buildConsoleReplay.js";
import reactHydrateOrRender from "../reactHydrateOrRender.js";
import createReactOutput from "../createReactOutput.js";
const DEFAULT_OPTIONS = {
    traceTurbolinks: false,
    turbo: false,
    debugMode: false,
    logComponentRegistration: false,
};
// Cache to track created objects and their registries
let cachedObject = null;
let cachedRegistries = null;
export function createBaseClientObject(registries, currentObject = null) {
    const { ComponentRegistry, StoreRegistry } = registries;
    // Error detection: currentObject is null but we have a cached object
    // This indicates webpack misconfiguration (multiple runtime chunks)
    if (currentObject === null && cachedObject !== null) {
        throw new Error(`\
ReactOnRails was already initialized, but a new initialization was attempted without passing the existing global.
This usually means Webpack's optimization.runtimeChunk is set to "true" or "multiple" instead of "single".

Fix: Set optimization.runtimeChunk to "single" in your webpack configuration.
See: https://github.com/shakacode/react_on_rails/issues/1558`);
    }
    // Error detection: currentObject exists but doesn't match cached object
    // This could indicate:
    // 1. Global was contaminated by external code
    // 2. Mixing core and pro packages
    if (currentObject !== null && cachedObject !== null && currentObject !== cachedObject) {
        throw new Error(`\
ReactOnRails global object mismatch detected.
The current global ReactOnRails object is different from the one created by this package.

This usually means:
1. You're mixing react-on-rails (core) with react-on-rails-pro
2. Another library is interfering with the global ReactOnRails object

Fix: Use only one package (core OR pro) consistently throughout your application.`);
    }
    // Error detection: Different registries with existing cache
    // This indicates mixing core and pro packages
    if (cachedRegistries !== null) {
        if (registries.ComponentRegistry !== cachedRegistries.ComponentRegistry ||
            registries.StoreRegistry !== cachedRegistries.StoreRegistry) {
            throw new Error(`\
Cannot mix react-on-rails (core) with react-on-rails-pro.
Different registries detected - the packages use incompatible registries.

Fix: Use only react-on-rails OR react-on-rails-pro, not both.`);
        }
    }
    // If we have a cached object, return it (all checks passed above)
    if (cachedObject !== null) {
        return cachedObject;
    }
    // Create and return new object
    const obj = {
        options: {},
        isRSCBundle: false,
        // ===================================================================
        // STABLE METHOD IMPLEMENTATIONS - Core package implementations
        // ===================================================================
        authenticityToken() {
            return Authenticity.authenticityToken();
        },
        authenticityHeaders(otherHeaders = {}) {
            return Authenticity.authenticityHeaders(otherHeaders);
        },
        reactHydrateOrRender(domNode, reactElement, hydrate) {
            return reactHydrateOrRender(domNode, reactElement, hydrate);
        },
        setOptions(newOptions) {
            if (typeof newOptions.traceTurbolinks !== 'undefined') {
                this.options.traceTurbolinks = newOptions.traceTurbolinks;
                // eslint-disable-next-line no-param-reassign
                delete newOptions.traceTurbolinks;
            }
            if (typeof newOptions.turbo !== 'undefined') {
                this.options.turbo = newOptions.turbo;
                // eslint-disable-next-line no-param-reassign
                delete newOptions.turbo;
            }
            if (typeof newOptions.debugMode !== 'undefined') {
                this.options.debugMode = newOptions.debugMode;
                if (newOptions.debugMode) {
                    console.log('[ReactOnRails] Debug mode enabled');
                }
                // eslint-disable-next-line no-param-reassign
                delete newOptions.debugMode;
            }
            if (typeof newOptions.logComponentRegistration !== 'undefined') {
                this.options.logComponentRegistration = newOptions.logComponentRegistration;
                if (newOptions.logComponentRegistration) {
                    console.log('[ReactOnRails] Component registration logging enabled');
                }
                // eslint-disable-next-line no-param-reassign
                delete newOptions.logComponentRegistration;
            }
            if (Object.keys(newOptions).length > 0) {
                throw new Error(`Invalid options passed to ReactOnRails.options: ${JSON.stringify(newOptions)}`);
            }
        },
        option(key) {
            return this.options[key];
        },
        buildConsoleReplay() {
            return buildConsoleReplay();
        },
        getConsoleReplayScript() {
            return consoleReplay();
        },
        resetOptions() {
            this.options = { ...DEFAULT_OPTIONS };
        },
        // ===================================================================
        // REGISTRY METHOD IMPLEMENTATIONS - Using provided registries
        // ===================================================================
        register(components) {
            if (this.options.debugMode || this.options.logComponentRegistration) {
                // Use performance.now() if available, otherwise fallback to Date.now()
                const perf = typeof performance !== 'undefined' ? performance : { now: () => Date.now() };
                const startTime = perf.now();
                const componentNames = Object.keys(components);
                console.log(`[ReactOnRails] Registering ${componentNames.length} component(s): ${componentNames.join(', ')}`);
                ComponentRegistry.register(components);
                const endTime = perf.now();
                console.log(`[ReactOnRails] Component registration completed in ${(endTime - startTime).toFixed(2)}ms`);
                // Log individual component details if in full debug mode
                if (this.options.debugMode) {
                    componentNames.forEach((name) => {
                        const component = components[name];
                        const size = component.toString().length;
                        console.log(`[ReactOnRails] ✅ Registered: ${name} (${size} chars)`);
                    });
                }
            }
            else {
                ComponentRegistry.register(components);
            }
        },
        registerStore(stores) {
            this.registerStoreGenerators(stores);
        },
        registerStoreGenerators(storeGenerators) {
            if (!storeGenerators) {
                throw new Error('Called ReactOnRails.registerStoreGenerators with a null or undefined, rather than ' +
                    'an Object with keys being the store names and the values are the store generators.');
            }
            StoreRegistry.register(storeGenerators);
        },
        getStore(name, throwIfMissing = true) {
            return StoreRegistry.getStore(name, throwIfMissing);
        },
        getStoreGenerator(name) {
            return StoreRegistry.getStoreGenerator(name);
        },
        setStore(name, store) {
            StoreRegistry.setStore(name, store);
        },
        clearHydratedStores() {
            StoreRegistry.clearHydratedStores();
        },
        getComponent(name) {
            return ComponentRegistry.get(name);
        },
        registeredComponents() {
            return ComponentRegistry.components();
        },
        storeGenerators() {
            return StoreRegistry.storeGenerators();
        },
        stores() {
            return StoreRegistry.stores();
        },
        render(name, props, domNodeId, hydrate) {
            const componentObj = ComponentRegistry.get(name);
            const reactElement = createReactOutput({ componentObj, props, domNodeId });
            return this.reactHydrateOrRender(document.getElementById(domNodeId), reactElement, hydrate);
        },
        // ===================================================================
        // CLIENT-SIDE RENDERING STUBS - To be overridden by createReactOnRails
        // ===================================================================
        reactOnRailsPageLoaded() {
            throw new Error('ReactOnRails.reactOnRailsPageLoaded is not initialized. This is a bug in react-on-rails.');
        },
        reactOnRailsComponentLoaded(domId) {
            void domId; // Mark as used
            throw new Error('ReactOnRails.reactOnRailsComponentLoaded is not initialized. This is a bug in react-on-rails.');
        },
        // ===================================================================
        // SSR STUBS - Will throw errors in client bundle, overridden in full
        // ===================================================================
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        serverRenderReactComponent(...args) {
            void args; // Mark as used
            throw new Error('serverRenderReactComponent is not available in "react-on-rails/client". Import "react-on-rails" server-side.');
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        handleError(...args) {
            void args; // Mark as used
            throw new Error('handleError is not available in "react-on-rails/client". Import "react-on-rails" server-side.');
        },
    };
    // Cache the object and registries
    cachedObject = obj;
    cachedRegistries = registries;
    return obj;
}
//# sourceMappingURL=client.js.map