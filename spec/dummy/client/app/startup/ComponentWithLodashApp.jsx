import React from 'react';
import ComponentWithLodash from '../components/ComponentWithLodash';

/*
 *  Export a function that returns a ReactComponent, depending on a store named SharedReduxStore.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 */
export default () => <ComponentWithLodash />;
