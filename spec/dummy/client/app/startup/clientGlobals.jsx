import HelloWorld from '../components/HelloWorld';
import HelloES5 from '../components/HelloES5';
import App from './ClientApp';
import HelloWorldApp from './ClientHelloWorldApp';

// This is an example of how to render a React component directly, without using Redux
window.HelloWorld = HelloWorld;
window.HelloES5 = HelloES5;
window.App = App;
window.HelloWorldApp = HelloWorldApp;
