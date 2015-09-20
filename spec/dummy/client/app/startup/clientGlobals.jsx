import HelloWorld from '../components/HelloWorld';
import HelloWorldES5 from '../components/HelloWorldES5';
import ReduxApp from './ClientReduxApp';
import HelloWorldApp from './HelloWorldApp';

// This is an example of how to render a React component directly, without using Redux
window.HelloWorld = HelloWorld;
window.HelloWorldES5 = HelloWorldES5;
window.ReduxApp = ReduxApp;
window.HelloWorldApp = HelloWorldApp;
