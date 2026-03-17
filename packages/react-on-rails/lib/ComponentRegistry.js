import isRenderFunction from "./isRenderFunction.js";
const registeredComponents = new Map();
export default {
    /**
     * @param components { component1: component1, component2: component2, etc. }
     */
    register(components) {
        Object.keys(components).forEach((name) => {
            const component = components[name];
            if (!component) {
                throw new Error(`Called register with null component named ${name}`);
            }
            // Reference comparison lets HMR re-register the same component silently
            // while still catching bugs where different components share a name.
            const existing = registeredComponents.get(name);
            if (existing && existing.component !== component) {
                console.error(`ReactOnRails: Component "${name}" was registered with a different component than previously. ` +
                    'This is likely a bug — ensure each component has a unique registration name.');
            }
            const renderFunction = isRenderFunction(component);
            const isRenderer = renderFunction && component.length === 3;
            registeredComponents.set(name, {
                name,
                component,
                renderFunction,
                isRenderer,
            });
        });
    },
    /**
     * @param name
     * @returns { name, component, renderFunction, isRenderer }
     */
    get(name) {
        const registeredComponent = registeredComponents.get(name);
        if (registeredComponent !== undefined) {
            return registeredComponent;
        }
        const keys = Array.from(registeredComponents.keys()).join(', ');
        throw new Error(`Could not find component registered with name ${name}. \
Registered component names include [ ${keys} ]. Maybe you forgot to register the component?`);
    },
    /**
     * Get a Map containing all registered components. Useful for debugging.
     * @returns Map where key is the component name and values are the
     * { name, component, renderFunction, isRenderer}
     */
    components() {
        return registeredComponents;
    },
    /**
     * Pro-only method that waits for component registration
     * @param _name Component name to wait for
     * @throws Always throws error indicating pro package is required
     */
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    getOrWaitForComponent(_name) {
        throw new Error('getOrWaitForComponent requires react-on-rails-pro package');
    },
    /**
     * Clear all registered components (for testing purposes)
     * @private
     */
    clear() {
        registeredComponents.clear();
    },
};
//# sourceMappingURL=ComponentRegistry.js.map