import type { UnknownAction } from 'redux';

import type { HelloWorldNameUpdateAction } from '../actions/HelloWorldActions';
import { HELLO_WORLD_NAME_UPDATE } from '../constants/HelloWorldConstants';
import type { HelloWorldData } from '../store/reduxTypes';

const initialState: HelloWorldData = {
  lastActionType: null,
  name: 'Alex',
};

function isHelloWorldNameUpdateAction(action: UnknownAction): action is HelloWorldNameUpdateAction {
  return action.type === HELLO_WORLD_NAME_UPDATE && typeof action.name === 'string';
}

export default function helloWorldReducer(
  state: HelloWorldData = initialState,
  action: UnknownAction = { type: '' },
): HelloWorldData {
  if (isHelloWorldNameUpdateAction(action)) {
    return {
      lastActionType: action.type,
      name: action.name,
    };
  }

  return state;
}
