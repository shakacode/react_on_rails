export declare function renderOrHydrateComponent(domIdOrElement: string | Element): Promise<void>;
export declare const renderOrHydrateImmediateHydratedComponents: () => Promise<void>;
export declare const renderOrHydrateAllComponents: () => Promise<void>;
export declare function hydrateStore(storeNameOrElement: string | Element): Promise<void>;
export declare const hydrateImmediateHydratedStores: () => Promise<void>;
export declare const hydrateAllStores: () => Promise<void>;
export declare function unmountAll(): void;
