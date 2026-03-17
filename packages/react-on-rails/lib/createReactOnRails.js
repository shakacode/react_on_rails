import { clientStartup, reactOnRailsPageLoaded } from "./clientStartup.js";
import { reactOnRailsComponentLoaded } from "./ClientRenderer.js";
import ComponentRegistry from "./ComponentRegistry.js";
import StoreRegistry from "./StoreRegistry.js";
export default function createReactOnRails(baseObjectCreator, currentGlobal = null) {
    // Create base object with core registries, passing currentGlobal for caching/validation
    const baseObject = baseObjectCreator({
        ComponentRegistry,
        StoreRegistry,
    }, currentGlobal);
    // Define core-specific functions with proper types
    // This object acts as a type-safe specification of what we're adding/overriding on the base object
    const reactOnRailsCoreSpecificFunctions = {
        // Override base stubs with core implementations
        reactOnRailsPageLoaded() {
            reactOnRailsPageLoaded();
            return Promise.resolve();
        },
        reactOnRailsComponentLoaded(domId) {
            return reactOnRailsComponentLoaded(domId);
        },
        // Pro-only stubs (throw errors in core package)
        getOrWaitForComponent() {
            throw new Error('getOrWaitForComponent requires react-on-rails-pro package');
        },
        getOrWaitForStore() {
            throw new Error('getOrWaitForStore requires react-on-rails-pro package');
        },
        getOrWaitForStoreGenerator() {
            throw new Error('getOrWaitForStoreGenerator requires react-on-rails-pro package');
        },
        reactOnRailsStoreLoaded() {
            throw new Error('reactOnRailsStoreLoaded requires react-on-rails-pro package');
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        streamServerRenderedReactComponent() {
            throw new Error('streamServerRenderedReactComponent requires react-on-rails-pro package');
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        serverRenderRSCReactComponent() {
            throw new Error('serverRenderRSCReactComponent requires react-on-rails-pro package');
        },
        addAsyncPropsCapabilityToComponentProps() {
            throw new Error('addAsyncPropsCapabilityToComponentProps requires react-on-rails-pro package');
        },
    };
    // Type assertion is safe here because:
    // 1. We start with BaseClientObjectType or BaseFullObjectType (from baseObjectCreator)
    // 2. We add exactly the methods defined in ReactOnRailsCoreSpecificFunctions
    // 3. ReactOnRailsInternal = Base + ReactOnRailsCoreSpecificFunctions
    // TypeScript can't track the mutation, but we ensure type safety by explicitly typing
    // the functions object above
    const reactOnRails = baseObject;
    // Assign core-specific functions to the ReactOnRails object using Object.assign
    // This pattern ensures we add exactly what's defined in the type, nothing more, nothing less
    Object.assign(reactOnRails, reactOnRailsCoreSpecificFunctions);
    // Assign to global if not already assigned
    if (!globalThis.ReactOnRails) {
        globalThis.ReactOnRails = reactOnRails;
        // Reset options to defaults (only on first initialization)
        reactOnRails.resetOptions();
        // Run client startup (only on first initialization)
        if (typeof window !== 'undefined') {
            setTimeout(() => {
                clientStartup();
            }, 0);
        }
    }
    return reactOnRails;
}
//# sourceMappingURL=createReactOnRails.js.map