import { HELLO_WORLD_NAME_UPDATE } from '../constants/HelloWorldConstants';

type HelloWorldNameUpdateAction = {
  name: string;
  type: typeof HELLO_WORLD_NAME_UPDATE;
};

function updateName(name: string): HelloWorldNameUpdateAction {
  return {
    type: HELLO_WORLD_NAME_UPDATE,
    name,
  };
}

export type { HelloWorldNameUpdateAction };
export { updateName };
