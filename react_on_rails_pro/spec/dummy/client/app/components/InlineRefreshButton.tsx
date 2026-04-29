'use client';

import * as React from 'react';
import { useCurrentRSCRoute } from 'react-on-rails-pro/RSCRoute';

type Props = {
  label?: string;
  testId?: string;
};

const InlineRefreshButton: React.FC<Props> = ({ label = 'Refresh from inside', testId }) => {
  const { refetch } = useCurrentRSCRoute();
  const [pending, setPending] = React.useState(false);

  const handleClick = () => {
    setPending(true);
    refetch()
      .catch((err: unknown) => {
        console.error('InlineRefreshButton refetch failed', err);
      })
      .finally(() => {
        setPending(false);
      });
  };

  return (
    <button type="button" data-testid={testId} disabled={pending} onClick={handleClick}>
      {pending ? 'Refreshing…' : label}
    </button>
  );
};

export default InlineRefreshButton;
