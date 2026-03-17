import type { RegisteredComponent, ReactComponentOrRenderFunction, Store, StoreGenerator, ReactOnRailsInternal } from '../types/index.ts';
interface Registries {
    ComponentRegistry: {
        register: (components: Record<string, ReactComponentOrRenderFunction>) => void;
        get: (name: string) => RegisteredComponent;
        components: () => Map<string, RegisteredComponent>;
    };
    StoreRegistry: {
        register: (storeGenerators: Record<string, StoreGenerator>) => void;
        getStore: (name: string, throwIfMissing?: boolean) => Store | undefined;
        getStoreGenerator: (name: string) => StoreGenerator;
        setStore: (name: string, store: Store) => void;
        clearHydratedStores: () => void;
        storeGenerators: () => Map<string, StoreGenerator>;
        stores: () => Map<string, Store>;
    };
}
/**
 * Base client object type that includes all core ReactOnRails methods except Pro-specific ones.
 * Derived from ReactOnRailsInternal by omitting Pro-only methods.
 */
export type BaseClientObjectType = Omit<ReactOnRailsInternal, 'getOrWaitForComponent' | 'getOrWaitForStore' | 'getOrWaitForStoreGenerator' | 'reactOnRailsStoreLoaded' | 'streamServerRenderedReactComponent' | 'serverRenderRSCReactComponent' | 'addAsyncPropsCapabilityToComponentProps' | 'getOrCreateAsyncPropsManager'>;
export declare function createBaseClientObject(registries: Registries, currentObject?: BaseClientObjectType | null): BaseClientObjectType;
export {};
//# sourceMappingURL=client.d.ts.map