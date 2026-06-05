import type { UnknownAction } from 'redux';

const initialState = {};

export default function nullReducer<State = unknown>(
  // `{}` is a valid initial value for any State shape; the double cast is required for this generic default.
  state: State = initialState as unknown as State,
  _action: UnknownAction = { type: '' },
): State {
  return state;
}
