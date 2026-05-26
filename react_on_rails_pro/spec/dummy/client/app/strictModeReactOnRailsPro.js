import ReactOnRails from 'react-on-rails-pro/ReactOnRails.full';
import { enableStrictModeForReactOnRails } from './strictModeSupport';

const shouldEnableStrictMode = process.env.NODE_ENV !== 'production';

// Outer guard for clarity; enableStrictModeForReactOnRails also no-ops in production.
export default shouldEnableStrictMode ? enableStrictModeForReactOnRails(ReactOnRails) : ReactOnRails;
