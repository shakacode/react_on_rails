// Top level component for simple client side only rendering
import React from 'react';
import HelloWorld from '../components/HelloWorld';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 */
window.HelloWorldApp = props => {
  return <HelloWorld {...props}/>;
};

/*
 * If you wish to create a React component via a function, rather than simply props,
 * then you need to set the property "generator" on that function to true.
 * When that is done, the function is invoked with a single parameter of "props",
 * and that function should return a react element.
 */
window.HelloWorldApp.generator = true;
