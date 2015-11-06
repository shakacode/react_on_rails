/* eslint no-console: 0 */
import _ from 'lodash';

// This logger should be configured not to run in a production environment.
// See https://github.com/petehunt/webpack-howto#6-feature-flags for you might turn this off for production.
export default function logger({ getState }) {
  return next => action => {
    console.log('will dispatch', action);

    // Call the next dispatch method in the middleware chain.
    const nextAction = next(action);

    const immutableState = getState();
    const readableState = _.reduce(immutableState, (result, immutableItem, key) => {
      result[key] = immutableItem.toJS();
      return result;
    }, {});

    console.log('state after dispatch', readableState);

    // This will likely be the action itself, unless
    // a middleware further in chain changed it.
    return nextAction;
  };
}
