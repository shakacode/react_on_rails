/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

// See discussion:
// https://discuss.reactjs.org/t/how-to-determine-if-js-object-is-react-component/2825/2
import { ReactComponentOrRenderFunction, RenderFunction } from './types/index.ts';

/**
 * Used to determine we'll call be calling React.createElement on the component of if this is a
 * Render-Function used return a function that takes props to return a React element
 * @param component
 * @returns {boolean}
 */
export default function isRenderFunction(
  component: ReactComponentOrRenderFunction,
): component is RenderFunction {
  // No for es5 or es6 React Component
  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
  if ((component as RenderFunction).prototype?.isReactComponent) {
    return false;
  }

  if ((component as RenderFunction).renderFunction) {
    return true;
  }

  // If zero or one args, then we know that this is a regular function that will
  // return a React component
  if ((component as RenderFunction).length >= 2) {
    return true;
  }

  return false;
}
