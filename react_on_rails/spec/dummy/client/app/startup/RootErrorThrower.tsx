import * as React from 'react';

/**
 * Test fixture for issue #3892 (rootErrorHandlers.onUncaughtError).
 *
 * Client-rendered (createRoot path) component that throws during render after the button is
 * clicked. With no error boundary above it, React routes the error to the `onUncaughtError`
 * callback registered via `ReactOnRails.setOptions({ rootErrorHandlers })` in client-bundle.ts.
 */
const RootErrorThrower: React.FC = () => {
  const [shouldThrow, setShouldThrow] = React.useState(false);

  if (shouldThrow) {
    throw new Error('Deliberate uncaught render error from RootErrorThrower');
  }

  return (
    <div>
      <h3>Root Error Thrower</h3>
      <button type="button" onClick={() => setShouldThrow(true)}>
        Throw render error
      </button>
    </div>
  );
};

export default RootErrorThrower;
