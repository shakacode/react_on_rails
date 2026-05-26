// `<React.StrictMode>` is a client-only construct: its double-invocation, deprecated-API, and
// ref-validation checks do not run during server-side rendering. Wrapping `register` here is
// effectively a no-op at SSR time. We keep the patch in place so client and server `register`
// call sites resolve through the same shim (uniformity across Pro entry points), and so that
// hot-reload paths or shared code that registers once and renders both client- and server-side
// continues to work without divergence. Per-call cost is bounded by the WeakMap caches in
// `strictModeSupport.tsx` (repeated registrations are O(1)).
import ReactOnRails from 'react-on-rails-pro/ReactOnRails.node';
import { enableStrictModeForReactOnRails } from './strictModeSupport';

// Outer guard for clarity; enableStrictModeForReactOnRails also no-ops in production.
export default shouldEnableStrictMode ? enableStrictModeForReactOnRails(ReactOnRails) : ReactOnRails;

export default shouldEnableStrictMode ? enableStrictModeForReactOnRails(ReactOnRails) : ReactOnRails;
