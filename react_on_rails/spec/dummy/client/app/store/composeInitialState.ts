import type { RailsContext } from 'react-on-rails/types';

import type { ReduxAppState } from './reduxTypes';
import { propsForReduxState } from './reduxTypes';

export default function composeInitialState(
  props: Record<string, unknown>,
  railsContext: RailsContext,
): ReduxAppState {
  return { ...propsForReduxState(props), railsContext };
}
