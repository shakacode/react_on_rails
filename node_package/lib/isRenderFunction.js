"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Used to determine we'll call be calling React.createElement on the component of if this is a
 * Render-Function used return a function that takes props to return a React element
 * @param component
 * @returns {boolean}
 */
function isRenderFunction(component) {
    // No for es5 or es6 React Component
    if (component.prototype &&
        component.prototype.isReactComponent) {
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
exports.default = isRenderFunction;
