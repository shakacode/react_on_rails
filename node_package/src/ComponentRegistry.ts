import type { RegisteredComponent, ReactComponentOrRenderFunction, RenderFunction } from './types/index';
import isRenderFunction from './isRenderFunction';

function logRegisteredComponents(value: string, key: string) {
  console.warn(key);
}

const registeredComponents = new Map();

export default {
  /**
   * @param components { component1: component1, component2: component2, etc. }
   */
  register(components: { [id: string]: ReactComponentOrRenderFunction }): void {
    Object.keys(components).forEach(name => {
      if (registeredComponents.has(name)) {
        console.warn('Called register for component that is already registered', name);
      }

      const component = components[name];
      if (!component) {
        throw new Error(`Called register with null component named ${name}`);
      }
      console.warn("registering ".concat(name, " component"));

      const renderFunction = isRenderFunction(component);
      const isRenderer = renderFunction && (component as RenderFunction).length === 3;

      registeredComponents.set(name, {
        name,
        component,
        renderFunction,
        isRenderer,
      });

      registeredComponents.forEach(logRegisteredComponents)
    });
  },

  /**
   * @param name
   * @returns { name, component, isRenderFunction, isRenderer }
   */
  get(name: string): RegisteredComponent {
    if (registeredComponents.has(name)) {
      return registeredComponents.get(name);
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
  components(): Map<string, RegisteredComponent> {
    return registeredComponents;
  },
};
