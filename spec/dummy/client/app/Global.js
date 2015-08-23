// Make sure the following files are
import App from './initters/server.jsx';
import HelloString from './HelloString';

// Alternative syntax for exposing Vars
// require("expose?HelloString!./HelloString.js");
// require("expose?HelloWorld!./HelloWorld.js");
// require("expose?React!react");

// If we do this, then we don't have to use the expose-loader.
// This syntax is a bit easier maybe?
// NodeJs: global
// https://nodejs.org/api/globals.html#globals_global
// Uncomment next 4 lines to use global

 //global.HelloWorld = HelloWorld;
 //global.HelloString = HelloString;
 //import React from 'react';
 //global.React = React;
