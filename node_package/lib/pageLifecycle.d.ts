type PageLifecycleCallback = () => void | Promise<void>;
export declare function onPageLoaded(callback: PageLifecycleCallback): void;
export declare function onPageUnloaded(callback: PageLifecycleCallback): void;
export {};
