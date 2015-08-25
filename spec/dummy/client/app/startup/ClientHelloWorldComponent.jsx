// Top level component for simple client side only rendering

import HelloWorld  from '../components/HelloWorld';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 */
window.HelloWorldComponent = (props) => {
  return <HelloWorld {...props}/>;
};
