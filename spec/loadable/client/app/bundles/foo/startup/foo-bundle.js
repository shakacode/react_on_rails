import 'idempotent-babel-polyfill';
import ReactOnRails from 'react-on-rails';
import App from './foo-bundle.imports-loadable';

ReactOnRails.register({
  App,
});
