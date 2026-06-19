import * as React from 'react';

/**
 * Test fixture for issue #3887 (Owner Stacks in CSR/SSR error reports).
 *
 * A deliberately *nested* component tree so React 19.1+'s owner stack
 * (`captureOwnerStack`, dev builds only) has a meaningful chain to report:
 *
 *   OwnerStackThrower  →  OwnerStackMiddle  →  OwnerStackInner (throws)
 *
 * Client-rendered (createRoot path, `prerender: false`). After the button is clicked the inner
 * component throws during render with no error boundary above it, so React routes the error to the
 * root's `onUncaughtError` callback. React on Rails' dev-mode logger (rootErrorHandlers.ts) then
 * emits a "[ReactOnRails] Render error ... Owner stack:" line naming the owner chain in the browser
 * console.
 *
 * Manual demo only: the branded line is gated to `railsEnv === 'development'` and requires a React
 * >= 19.1 dev build, so it is exercised at the unit level by `rootErrorCallbacksOwnerStack.test.tsx`
 * rather than by the Playwright suite (which boots Rails in `test`). Load `/root_error_callbacks` in
 * a development server and click the button to see it live.
 */

const OwnerStackInner: React.FC<{ shouldThrow: boolean }> = ({ shouldThrow }) => {
  if (shouldThrow) {
    throw new Error('Deliberate owner-stack render error from OwnerStackInner');
  }
  return <p>Owner stack inner ready</p>;
};

const OwnerStackMiddle: React.FC<{ shouldThrow: boolean }> = ({ shouldThrow }) => (
  <OwnerStackInner shouldThrow={shouldThrow} />
);

const OwnerStackThrower: React.FC = () => {
  const [shouldThrow, setShouldThrow] = React.useState(false);

  return (
    <div>
      <h3>Owner Stack Thrower</h3>
      <button type="button" onClick={() => setShouldThrow(true)}>
        Throw nested render error
      </button>
      <OwnerStackMiddle shouldThrow={shouldThrow} />
    </div>
  );
};

export default OwnerStackThrower;
