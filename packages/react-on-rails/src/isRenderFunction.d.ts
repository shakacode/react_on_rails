import { ReactComponentOrRenderFunction, RenderFunction } from './types/index.ts';
/**
 * Used to determine we'll call be calling React.createElement on the component of if this is a
 * Render-Function used return a function that takes props to return a React element
 * @param component
 * @returns {boolean}
 */
export default function isRenderFunction(
  component: ReactComponentOrRenderFunction,
): component is RenderFunction;
//# sourceMappingURL=isRenderFunction.d.ts.map
