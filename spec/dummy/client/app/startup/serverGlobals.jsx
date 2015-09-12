// Make sure the following files are
// Example of React + Redux
// Shows the mapping from the exported object to the name used by the server rendering.
import App from './ServerApp';

// Example of server rendering without using Redux
import { HelloWorld, HelloES5 } from './ServerApp';

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

/*
 * If you wish to create a React component via a function, rather than simply props,
 * then you need to set the property "generator" on that function to true.
 * When that is done, the function is invoked with a single parameter of "props",
 * and that function should return a react element.
 */
App.generator = true;

// We can use the node global object for exposing.
// NodeJs: https://nodejs.org/api/globals.html#globals_global
global.App = App;
global.HelloWorld = HelloWorld;
global.HelloES5 = HelloES5;
global.HelloString = HelloString;

// Alternative syntax for exposing Vars
// require("expose?HelloString!./non_react/HelloString.js");
// require("expose?HelloWorld!./HelloWorld.js");
