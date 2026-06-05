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
