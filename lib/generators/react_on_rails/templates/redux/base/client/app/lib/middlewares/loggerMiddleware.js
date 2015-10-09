/* eslint no-console: 0 */
import _ from 'lodash';

// This logger should be configured not to run in a production environment.
// See https://github.com/petehunt/webpack-howto#6-feature-flags for you might turn this off for production.
export default function logger({ getState }) {
  return next => action => {
    console.log('will dispatch', action);

    // Call the next dispatch method in the middleware chain.
    const result = next(action);

    // We can't console.log immutable objects out-of-the-box.
    const immutableState = getState();
    const readableState = _.reduce(immutableState, (result, immutable, key) => {
      result[key] = immutable.toJS();
    }, {});

    console.log('state after dispatch', readableState);

    // This will likely be the action itself, unless
    // a middleware further in chain changed it.
    return result;
  };
}
