/**
 * Suppression pattern for the "Module not found: Can't resolve 'react-dom/client'"
 * warning that webpack emits when building React 16/17 apps with react-on-rails.
 *
 * The warning is harmless: react-on-rails detects the React version at runtime and
 * only calls into react-dom/client when React 18+ is available. But webpack's static
 * analysis still tries to resolve the conditional require at build time, so the
 * warning shows up on React 16/17 builds even though the build is healthy.
 *
 * Usage in your webpack config (Webpack 5 / Shakapacker):
 *
 *   const { reactDomClientWarning } = require('react-on-rails/webpackHelpers');
 *
 *   module.exports = {
 *     // ...
 *     ignoreWarnings: [reactDomClientWarning],
 *   };
 *
 * Webpack 4 / Webpacker 5 users can pass the same regex to
 * `stats.warningsFilter` instead, since `ignoreWarnings` is a Webpack 5 option.
 *
 * Tracking issue: https://github.com/shakacode/react_on_rails/issues/3137
 */
// eslint-disable-next-line import/prefer-default-export -- intentionally named so additional helpers can be added later without a breaking change
export const reactDomClientWarning: RegExp = /Module not found: Error: Can't resolve 'react-dom\/client'/;
