import type { RegisteredComponent, ReactComponentOrRenderFunction } from './types/index';
declare const _default: {
    /**
     * @param components { component1: component1, component2: component2, etc. }
     */
    register(components: {
        [id: string]: ReactComponentOrRenderFunction;
    }): void;
    /**
     * @param name
     * @returns { name, component, isRenderFunction, isRenderer }
     */
    get(name: string): RegisteredComponent;
    /**
     * Get a Map containing all registered components. Useful for debugging.
     * @returns Map where key is the component name and values are the
     * { name, component, renderFunction, isRenderer}
     */
    components(): Map<string, RegisteredComponent>;
};
export default _default;
