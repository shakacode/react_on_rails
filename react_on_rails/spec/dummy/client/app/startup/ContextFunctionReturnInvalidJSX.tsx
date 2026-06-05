// Example of incorrectly taking two params and returning JSX
import React from 'react';
import css from '../components/HelloWorld.module.scss';
import RailsContext from '../components/RailsContext';
import type { RailsContextForDisplay } from '../types/railsContext';

type ContextFunctionReturnInvalidJSXProps = Record<string, unknown> & {
  helloWorldData: Record<string, unknown> & {
    name: string;
  };
};

/*
 * This is intentionally wrong: a 2-arg function that returns JSX directly.
 * React on Rails treats 2-arg functions as render functions, so this gets
 * called as renderFn(props, railsContext) and the JSX is used as if it were
 * a React component type, which will fail at runtime.
 *
 * The correct pattern for a render function that uses railsContext is:
 *
 *   const ContextFunctionReturnInvalidJSX = (
 *     { helloWorldData }: ContextFunctionReturnInvalidJSXProps,
 *     railsContext: RailsContextForDisplay,
 *   ) => () => (
 *     <>
 *       <h3>Hello, {helloWorldData.name}!</h3>
 *       <RailsContext railsContext={railsContext} />
 *     </>
 *   );
 */
const ContextFunctionReturnInvalidJSX = (
  { helloWorldData }: ContextFunctionReturnInvalidJSXProps,
  railsContext: RailsContextForDisplay,
) => (
  <>
    <h3 className={css.brightColor}>Hello, {helloWorldData.name}!</h3>
    <p>Rails Context :</p>
    <RailsContext railsContext={railsContext} />
  </>
);

export default ContextFunctionReturnInvalidJSX;
