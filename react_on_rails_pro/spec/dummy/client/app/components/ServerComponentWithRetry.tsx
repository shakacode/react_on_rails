import React, { useState } from 'react';
import { ErrorBoundary } from 'react-error-boundary';
import RSCRoute from 'react-on-rails-pro/RSCRoute';
import { useRSC } from 'react-on-rails-pro/RSCProvider';
import { isServerComponentFetchError } from 'react-on-rails-pro/ServerComponentFetchError';

const ErrorFallback = ({ error, resetErrorBoundary }: { error: Error; resetErrorBoundary: () => void }) => {
  const { refetchComponent } = useRSC();

  if (isServerComponentFetchError(error)) {
    const { serverComponentName, serverComponentProps } = error;
    return (
      <div>
        <div>Error happened while fetching the server component: {error.message}</div>
        <button
          type="button"
          onClick={() => {
            refetchComponent(serverComponentName, serverComponentProps)
              .catch((err: unknown) => {
                console.error(err);
              })
              .finally(() => {
                resetErrorBoundary();
              });
          }}
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div>
      <div>Error: {error.message}</div>
    </div>
  );
};

const ServerComponentWithRetry: React.FC = () => {
  const { refetchComponent } = useRSC();
  // Used to force re-render the component
  const [, setKey] = useState(0);

  return (
    <div>
      <ErrorBoundary FallbackComponent={ErrorFallback}>
        <RSCRoute componentName="ErrorThrowingServerComponent" componentProps={{}} />
        <button
          type="button"
          onClick={() => {
            refetchComponent('ErrorThrowingServerComponent', {})
              .catch((err: unknown) => {
                console.error(err);
              })
              .finally(() => {
                setKey((key) => key + 1);
              });
          }}
        >
          Refetch
        </button>
      </ErrorBoundary>
    </div>
  );
};

export default ServerComponentWithRetry;
