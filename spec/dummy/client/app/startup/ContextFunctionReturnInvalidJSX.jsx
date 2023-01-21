// Example of incorrectly taking two params and returning JSX
import React, { useState } from 'react';
import css from '../components/HelloWorld.module.scss';
import RailsContext from '../components/RailsContext';

const ContextFunctionReturnInvalidJSX = (props, railsContext) => (
  <>
    <h3 className={css.brightColor}>Hello, {props.helloWorldData.name}!</h3>
    <p>Rails Context :</p>
    <RailsContext {...{ railsContext }} />
  </>
);

/* Wrapping in a function would be correct in this case, since two params
   are passed to the registered function:

   This code should have been written like:

const ContextFunctionReturnInvalidJSX = (props, railsContext) => () => (
  <>
    <h3 className={css.brightColor}>Hello, {props.name}!</h3>
    <p>Rails Context :</p>
    <RailsContext {...{ railsContext }} />
  </>
);
 */

export default ContextFunctionReturnInvalidJSX;
