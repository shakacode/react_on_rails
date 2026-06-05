import type { RailsContext } from 'react-on-rails/types';
import type { Store } from 'redux';

import type { HELLO_WORLD_NAME_UPDATE } from '../constants/HelloWorldConstants';

type HelloWorldData = Record<string, unknown> & {
  lastActionType?: typeof HELLO_WORLD_NAME_UPDATE | null;
  name: string;
};

type ReduxAppProps = Record<string, unknown> & {
  helloWorldData: HelloWorldData;
  modificationTarget?: unknown;
  prerender?: boolean;
};

type StateProps = Record<string, unknown> & {
  helloWorldData: HelloWorldData;
  modificationTarget: unknown;
};

type ReduxAppState = StateProps & {
  railsContext: RailsContext & Record<string, unknown>;
};

type ReduxAppStore = Store<ReduxAppState>;

function propsForReduxState(props: Record<string, unknown>): StateProps {
  const stateProps = { ...(props as ReduxAppProps) };
  delete stateProps.prerender;

  return { ...stateProps, modificationTarget: undefined };
}

export type { HelloWorldData, ReduxAppProps, ReduxAppState, ReduxAppStore, StateProps };
export { propsForReduxState };
