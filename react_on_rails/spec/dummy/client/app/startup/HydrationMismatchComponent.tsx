import * as React from 'react';

/**
 * Test fixture for issue #3892 (rootErrorHandlers.onRecoverableError).
 *
 * Deliberately renders nondeterministic content so the server-rendered HTML can never match the
 * client render, forcing a React hydration mismatch. React recovers by re-rendering on the
 * client, which must invoke the `onRecoverableError` callback registered via
 * `ReactOnRails.setOptions({ rootErrorHandlers })` in client-bundle.ts.
 *
 * Only use this component on pages that test hydration-error reporting (e.g.
 * /root_error_callbacks); it intentionally violates the render-purity rules real components
 * should follow.
 */
const HydrationMismatchComponent: React.FC = () => (
  <div>
    <h3>Hydration Mismatch Component</h3>
    {/* Math.random() guarantees server/client divergence regardless of the SSR runtime. */}
    <div data-testid="mismatch-content">Render token: {Math.random()}</div>
  </div>
);

export default HydrationMismatchComponent;
