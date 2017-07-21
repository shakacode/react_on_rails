/* eslint-disable no-param-reassign */
import React from 'react';
import PropTypes from 'prop-types';

function contextReducer(result, key) {
  result[key] = PropTypes.any;
  return result;
}

function autoContextTypes(context) {
  return Object.keys(context).reduce(contextReducer, {});
}

export class RailsContextError extends Error {
  constructor(message) {
    super(message);
    this.name = 'RailsContextError';
  }
}

/**
 * Wraps Component in a constructor and passes railsContext as childContext.
 *
 * This lib was created because ReactOnRails dont know
 * how to pass the railsContext correctly to React.
 *
 * Component - Constructor for react compoment, it must be a class.
 *
 * Examples
 *
 *  import ReactOnRails from 'react-on-rails';
 *  import {wrapRailsContext} from 'react-on-rails/wrapRailsContext';
 *  import GuidePage from '../components/pages/GuidePage';
 *
 *  // The railsContext will be exposed as child context on GuidePage
 *  ReactOnRails.register({GuidePage: wrapRailsContext(GuidePage)});
 *
 * Returns constructor Function(props, context) for ReactOnRails.
 **/
export default function wrapRailsContext(Component) {
  if (!(Component.prototype instanceof React.Component)) {
    throw new RailsContextError(`"${Component.name || Component}" is not a class Component`);
  }

  return function railsContextWrapper(props, railsContext) {
    Component.prototype.getChildContext = () => railsContext;
    Component.childContextTypes = autoContextTypes(railsContext);

    return <Component {... props} />;
  };
}

/**
 * Wraps all object values using `wrapRailsContext`
 *
 * object - object with values to wrap.
 *
 * Examples
 *
 *  import ReactOnRails from 'react-on-rails';
 *  import {wrapAll} from 'react-on-rails/wrapRailsContext';
 *  import GuidePage from '../components/pages/GuidePage';
 *  import OtherPage from '../components/pages/OtherPage';
 *
 *  // The railsContext will be exposed as child context on GuidePage, OtherPage.
 *  ReactOnRails.register(wrapAll({GuidePage, OtherPage}));
 *
 * Returns an other object with the same keys but wrapped values.
 **/
export function wrapAll(object) {
  return Object.keys(object).reduce((result, key) => {
    result[key] = wrapRailsContext(object[key]);
    return result;
  }, {});
}
