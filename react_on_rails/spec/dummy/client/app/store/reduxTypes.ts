import type { RailsContext } from 'react-on-rails/types';
import type { Store } from 'redux';

import type { HELLO_WORLD_NAME_UPDATE } from '../constants/HelloWorldConstants';

type HelloWorldStoreData = Record<string, unknown> & {
  lastActionType?: typeof HELLO_WORLD_NAME_UPDATE | null;
  name: string;
};

type ReduxAppProps = Record<string, unknown> & {
  helloWorldData: HelloWorldStoreData;
  modificationTarget?: unknown;
  prerender?: boolean;
};

type StateProps = Record<string, unknown> & {
  helloWorldData: HelloWorldStoreData;
  modificationTarget: unknown;
};

type ReduxAppState = StateProps & {
  // combineReducers indexes state slices by reducer key; keep RailsContext fields while allowing that lookup.
  railsContext: RailsContext & Record<string, unknown>;
};

type ReduxAppStore = Store<ReduxAppState>;

function propsForReduxState(props: Record<string, unknown>): StateProps {
  const stateProps = { ...(props as ReduxAppProps) };
  delete stateProps.prerender;

  // Redux examples do not seed this field from Rails props; direct React props cover that path.
  return { ...stateProps, modificationTarget: undefined };
}

export type { HelloWorldStoreData, ReduxAppProps, ReduxAppState, ReduxAppStore, StateProps };
export { propsForReduxState };
