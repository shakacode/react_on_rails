import type { RegisteredComponent, ComponentOrRenderFunction, RenderFunction } from './types/index';
import generatorFunction from './generatorFunction';

const registeredComponents = new Map();

export default {
  /**
   * @param components { component1: component1, component2: component2, etc. }
   */
  register(components: { [id: string]: ComponentOrRenderFunction }): void {
    Object.keys(components).forEach(name => {
      if (registeredComponents.has(name)) {
        console.warn('Called register for component that is already registered', name);
      }

      const component = components[name];
      if (!component) {
        throw new Error(`Called register with null component named ${name}`);
      }

      const isGeneratorFunction = generatorFunction(component);
      const isRenderer = isGeneratorFunction && (component as RenderFunction).length === 3;

      registeredComponents.set(name, {
        name,
        component,
        generatorFunction: isGeneratorFunction,
        isRenderer,
      });
    });
  },

  /**
   * @param name
   * @returns { name, component, generatorFunction, isRenderer }
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
   * { name, component, generatorFunction, isRenderer}
   */
  components(): Map<string, RegisteredComponent> {
    return registeredComponents;
  },
};
