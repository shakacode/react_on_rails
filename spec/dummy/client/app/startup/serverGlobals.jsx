// Make sure the following files are
// Example of React + Redux
// Shows the mapping from the exported object to the name used by the server rendering.
import App from './ServerApp';

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

// We can use the node global object for exposing.
// NodeJs: https://nodejs.org/api/globals.html#globals_global
// Uncomment next 4 lines to use global
global.HelloString = HelloString;
global.App = App;

// Alternative syntax for exposing Vars
// require("expose?HelloString!./non_react/HelloString.js");
// require("expose?HelloWorld!./HelloWorld.js");
