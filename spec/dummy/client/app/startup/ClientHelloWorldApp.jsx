// Top level component for simple client side only rendering
import React from 'react';
import HelloWorld from '../components/HelloWorld';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 *  Ensure that option generator_function is set to true when invoking the helper, or as default.
 */
export default props => <HelloWorld {...props} />;
