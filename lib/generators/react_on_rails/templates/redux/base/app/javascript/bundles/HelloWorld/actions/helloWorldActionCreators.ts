/* eslint-disable import/prefer-default-export */

import { HELLO_WORLD_NAME_UPDATE } from '../constants/helloWorldConstants';

// Action interface
export interface UpdateNameAction {
  type: typeof HELLO_WORLD_NAME_UPDATE;
  text: string;
}

// Union type for all actions
export type HelloWorldAction = UpdateNameAction;

// Action creator with proper TypeScript typing
export const updateName = (text: string): UpdateNameAction => ({
  type: HELLO_WORLD_NAME_UPDATE,
  text,
});
