import { type RegisteredComponent, type ReactComponentOrRenderFunction, type RenderFunction } from './types';
import isRenderFunction from './isRenderFunction';
import CallbackRegistry from './CallbackRegistry';

const componentRegistry = new CallbackRegistry<RegisteredComponent>('component');

export default {
  /**
   * @param components { component1: component1, component2: component2, etc. }
   */
  register(components: { [id: string]: ReactComponentOrRenderFunction }): void {
    Object.keys(components).forEach((name) => {
      if (componentRegistry.has(name)) {
        console.warn('Called register for component that is already registered', name);
      }

      const component = components[name];
      if (!component) {
        throw new Error(`Called register with null component named ${name}`);
      }

      const renderFunction = isRenderFunction(component);
      const isRenderer = renderFunction && (component as RenderFunction).length === 3;

      componentRegistry.set(name, {
        name,
        component,
        renderFunction,
        isRenderer,
      });
    });
  },

  /**
   * @param name
   * @returns { name, component, isRenderFunction, isRenderer }
   */
  get(name: string): RegisteredComponent {
    return componentRegistry.get(name);
  },

  getOrWaitForComponent(name: string): Promise<RegisteredComponent> {
    return componentRegistry.getOrWaitForItem(name);
  },

  /**
   * Get a Map containing all registered components. Useful for debugging.
   * @returns Map where key is the component name and values are the
   * { name, component, renderFunction, isRenderer}
   */
  components(): Map<string, RegisteredComponent> {
    return componentRegistry.getAll();
  },

  clear(): void {
    componentRegistry.clear();
  },
};
