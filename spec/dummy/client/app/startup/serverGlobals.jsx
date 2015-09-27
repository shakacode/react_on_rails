// Example of React + Redux
// Shows the mapping from the exported object to the name used by the server rendering.
import HelloWorld from '../components/HelloWorld';
import HelloWorldWithLogAndThrow from '../components/HelloWorldWithLogAndThrow';
import HelloWorldApp from './HelloWorldApp';
import HelloWorldES5 from '../components/HelloWorldES5';
import ReduxApp from './ServerReduxApp';

// Example of server rendering with no React
import HelloString from '../non_react/HelloString';

// We can use the node global object for exposing.
// NodeJs: https://nodejs.org/api/globals.html#globals_global
global.ReduxApp = ReduxApp;
global.HelloWorld = HelloWorld;
global.HelloWorldWithLogAndThrow = HelloWorldWithLogAndThrow;
global.HelloWorldES5 = HelloWorldES5;
global.HelloString = HelloString;

global.HelloWorldApp = HelloWorldApp;

// Alternative syntax for exposing Vars
// require("expose?HelloString!./non_react/HelloString.js");
// require("expose?HelloWorld!./HelloWorld.js");
