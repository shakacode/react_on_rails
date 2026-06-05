import type { UnknownAction } from 'redux';

const initialState = {};

export default function nullReducer<State = unknown>(
  state: State = initialState as unknown as State,
  _action: UnknownAction = { type: '' },
): State {
  return state;
}
