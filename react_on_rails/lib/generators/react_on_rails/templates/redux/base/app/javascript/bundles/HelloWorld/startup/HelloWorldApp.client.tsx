import { useMemo, type FC } from 'react';
import { Provider } from 'react-redux';

import configureStore, { type RailsProps } from '../store/helloWorldStore';
import HelloWorldContainer from '../containers/HelloWorldContainer';

// Props interface matches what Rails will pass from the controller
interface HelloWorldAppProps extends RailsProps {}

// See documentation for https://github.com/reactjs/react-redux.
// This is how you get props from the Rails view into the redux store.
// This code here binds your smart component to the redux store.
const HelloWorldApp: FC<HelloWorldAppProps> = (props) => {
  const store = useMemo(() => configureStore(props), [props]);

  return (
    <Provider store={store}>
      <HelloWorldContainer />
    </Provider>
  );
};

export default HelloWorldApp;
