// TypeScript test store generator
import { createStore } from 'redux';

interface Props {
  route?: string;
}

const routerStore = (props: Props, railsContext: any) => {
  const initialState = { route: props.route || '/' };
  return createStore((state = initialState) => state);
};

export default routerStore;
