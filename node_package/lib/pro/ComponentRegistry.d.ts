import { type RegisteredComponent, type ReactComponentOrRenderFunction } from '../types/index.ts';
/**
 * @param components { component1: component1, component2: component2, etc. }
 */
export declare function register(components: Record<string, ReactComponentOrRenderFunction>): void;
/**
 * @param name
 * @returns { name, component, isRenderFunction, isRenderer }
 */
export declare const get: (name: string) => RegisteredComponent;
export declare const getOrWaitForComponent: (name: string) => Promise<RegisteredComponent>;
/**
 * Get a Map containing all registered components. Useful for debugging.
 * @returns Map where key is the component name and values are the
 * { name, component, renderFunction, isRenderer}
 */
export declare const components: () => Map<string, RegisteredComponent>;
/** @internal Exported only for tests */
export declare function clear(): void;
