// See discussion: https://discuss.reactjs.org/t/how-to-determine-if-js-object-is-react-component/2825/2

/**
 * Used to determine we'll call be calling React.createElement on the component of if this is a
 * generator function used return a function that takes props to return a React element
 * @param component
 * @returns {boolean}
 */
export default function generatorFunction(component) {
  if (!component.prototype) {
    return false;
  }

  // es5 or es6 React Component
  const es5OrEs6ReactComponent = component.prototype.isReactComponent;
  return !es5OrEs6ReactComponent;
}
