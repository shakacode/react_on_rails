// Example of incorrectly taking two params and returning JSX
import React, { useState } from 'react';
import css from './HelloWorld.scss';
import RailsContext from './RailsContext';

const ContextFunctionReturnJSX = (props, railsContext) => (
  <>
    <h3 className={css.brightColor}>Hello, {props.name}!</h3>
    <p>Rails Context :</p>
    <RailsContext {...{ railsContext }} />
  </>
);

/* Wrapping in a function would be correct in this case, since two params
   are passed to the registered function:
const ContextFunctionReturnJSX = (props, railsContext) => () => (
  <>
    <h3 className={css.brightColor}>Hello, {props.name}!</h3>
    <p>Rails Context :</p>
    <RailsContext {...{ railsContext }} />
  </>
);
 */

export default ContextFunctionReturnJSX;
