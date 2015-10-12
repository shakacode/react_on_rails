// Shows the mapping from the exported object to the name used by the server rendering.

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

// React components
import HelloWorld from '../components/HelloWorld';
import HelloWorldES5 from '../components/HelloWorldES5';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';

// Generator function
import HelloWorldApp from './HelloWorldApp';

// Example of React + Redux
import ReduxApp from './ServerReduxApp';


// We can use the node global object for exposing.
// NodeJs: https://nodejs.org/api/globals.html#globals_global
global.HelloString = HelloString;
global.ReduxApp = ReduxApp;
global.HelloWorld = HelloWorld;
global.HelloWorldWithLogAndThrow = HelloWorldWithLogAndThrow;
global.HelloWorldES5 = HelloWorldES5;
global.HelloWorldApp = HelloWorldApp;

// Alternative syntax for exposing Vars
// NOTE: you must set exports.output.libraryTarget = 'this' in your webpack.server.js file.
// See client/webpack.server.js:16
// require("expose?HelloString!../non_react/HelloString");
// require("expose?HelloWorld!../components/HelloWorld");
