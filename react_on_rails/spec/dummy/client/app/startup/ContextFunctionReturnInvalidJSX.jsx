// Example of incorrectly taking two params and returning JSX
import React from 'react';
import PropTypes from 'prop-types';
import css from '../components/HelloWorld.module.scss';
import RailsContext from '../components/RailsContext';

const ContextFunctionReturnInvalidJSX = ({ helloWorldData }, railsContext) => (
  <>
    <h3 className={css.brightColor}>Hello, {helloWorldData.name}!</h3>
    <p>Rails Context :</p>
    <RailsContext {...{ railsContext }} />
  </>
);

ContextFunctionReturnInvalidJSX.propTypes = {
  helloWorldData: PropTypes.shape({
    name: PropTypes.string,
  }).isRequired,
};

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
