import 'idempotent-babel-polyfill';
import ReactOnRails from 'react-on-rails';
import App from '../bundles/foo/startup/foo-bundle.imports-loadable';

ReactOnRails.register({
  App,
});
