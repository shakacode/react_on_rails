import * as React from 'react';

type BoundaryState = {
  hasError: boolean;
};

class RootErrorBoundary extends React.Component<React.PropsWithChildren, BoundaryState> {
  constructor(props: React.PropsWithChildren) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(): BoundaryState {
    return { hasError: true };
  }

  render() {
    const { hasError } = this.state;
    const { children } = this.props;
    return hasError ? <div role="status">Boundary caught render error</div> : children;
  }
}

const BoundaryThrowingChild: React.FC<{ shouldThrow: boolean }> = ({ shouldThrow }) => {
  if (shouldThrow) {
    throw new Error('Deliberate caught render error from RootErrorBoundaryThrower');
  }

  return <p>Boundary child ready</p>;
};

/**
 * Test fixture for issue #3892 (rootErrorHandlers.onCaughtError).
 *
 * The child throws during render after a click, but the local error boundary catches it. React 19
 * routes that separate caught-error path to the root's `onCaughtError` callback.
 */
const RootErrorBoundaryThrower: React.FC = () => {
  const [shouldThrow, setShouldThrow] = React.useState(false);

  return (
    <RootErrorBoundary>
      <div>
        <h3>Root Error Boundary Thrower</h3>
        <button type="button" onClick={() => setShouldThrow(true)}>
          Throw boundary error
        </button>
        <BoundaryThrowingChild shouldThrow={shouldThrow} />
      </div>
    </RootErrorBoundary>
  );
};

export default RootErrorBoundaryThrower;
