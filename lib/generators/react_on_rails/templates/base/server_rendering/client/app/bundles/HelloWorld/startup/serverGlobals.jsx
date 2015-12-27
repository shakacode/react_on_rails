import ReactOnRails from 'react-on-rails';
import HelloWorldAppServer from './HelloWorldAppServer';

global.HelloWorldAppServer = HelloWorldAppServer;
ReactOnRails.register('HelloWorldAppServer', HelloWorldAppServer);
