/**
 * Used to determine we'll call be calling React.createElement on the component of if this is a
 * Render-Function used return a function that takes props to return a React element
 * @param component
 * @returns {boolean}
 */
export default function isRenderFunction(component) {
  // No for es5 or es6 React Component
  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
  if (component.prototype?.isReactComponent) {
    return false;
  }
  if (component.renderFunction) {
    return true;
  }
  // If zero or one args, then we know that this is a regular function that will
  // return a React component
  if (component.length >= 2) {
    return true;
  }
  return false;
}
