import ReactOnRails from 'react-on-rails-pro/ReactOnRails.client';
import { enableStrictModeForReactOnRails } from './strictModeSupport';

const shouldEnableStrictMode = process.env.NODE_ENV !== 'production';

export default shouldEnableStrictMode ? enableStrictModeForReactOnRails(ReactOnRails) : ReactOnRails;
