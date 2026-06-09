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
  // Redux's Reducer<S> requires S to be indexable; RailsContext is a discriminated union with no index
  // signature, so intersect with Record<string, unknown> to satisfy that constraint while keeping known fields.
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
