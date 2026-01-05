/**
 * Bundle for testing large props JSON parsing.
 *
 * This bundle includes:
 * 1. LargePropsComponent - Registers immediately
 * 2. DelayedLargePropsComponent - Registers after a configurable delay
 *
 * The delay simulates code-splitting scenarios where the component bundle
 * loads asynchronously, creating a window for race conditions.
 *
 * Issue: https://github.com/shakacode/react_on_rails/issues/2283
 */

import ReactOnRails from 'react-on-rails-pro';

import LargePropsComponent from '../components/LargePropsComponent';
import DelayedLargePropsComponent from '../components/DelayedLargePropsComponent';

// Get the delay from a global variable or default to 100ms
// This can be set by the test page to vary the delay
const REGISTRATION_DELAY = window.__DELAYED_COMPONENT_REGISTRATION_DELAY__ || 100;

// Register the immediate component right away
ReactOnRails.register({
  LargePropsComponent,
});

console.log('[large-props-bundle] LargePropsComponent registered immediately');

// Register the delayed component after a delay
// This simulates a code-split bundle that loads asynchronously
setTimeout(() => {
  ReactOnRails.register({
    DelayedLargePropsComponent,
  });
  console.log(
    `[large-props-bundle] DelayedLargePropsComponent registered after ${REGISTRATION_DELAY}ms delay`,
  );
}, REGISTRATION_DELAY);
