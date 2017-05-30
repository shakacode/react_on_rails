import React from 'react';
import { Provider } from 'react-redux';

import configureStore from '../store/mainPageStore';
import MainPageContainer from '../containers/MainPageContainer';

// See documentation for https://github.com/reactjs/react-redux.
// This is how you get props from the Rails view into the redux store.
// This code here binds your smart component to the redux store.
// railsContext provides contextual information especially useful for server rendering, such as
// knowing the locale. See the React on Rails documentation for more info on the railsContext
const MainPageApp = (props, _railsContext) => (
  <Provider store={configureStore(props)}>
    <MainPageContainer />
  </Provider>
);

export default MainPageApp;
