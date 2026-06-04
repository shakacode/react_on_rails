// See discussion:
// https://discuss.reactjs.org/t/how-to-determine-if-js-object-is-react-component/2825/2
import type { RegisteredComponentValue, RenderFunction } from './types/index.ts';

/**
 * Used to determine we'll call be calling React.createElement on the component of if this is a
 * Render-Function used return a function that takes props to return a React element
 * @param component
 * @returns {boolean}
 */
export default function isRenderFunction(component: RegisteredComponentValue): component is RenderFunction {
  if (typeof component !== 'function') {
    return false;
  }

  const callableComponent = component as RenderFunction;

  // No for es5 or es6 React Component
  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
  if (callableComponent.prototype?.isReactComponent) {
    return false;
  }

  if (callableComponent.renderFunction) {
    return true;
  }

  // If zero or one args, then we know that this is a regular function that will
  // return a React component
  if (callableComponent.length >= 2) {
    return true;
  }

  return false;
}
