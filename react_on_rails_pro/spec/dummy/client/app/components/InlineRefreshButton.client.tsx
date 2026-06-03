'use client';

import * as React from 'react';
import { useCurrentRSCRoute } from 'react-on-rails-pro/RSCRoute';

type Props = {
  label?: string;
  testId?: string;
};

const InlineRefreshButton: React.FC<Props> = ({ label = 'Refresh from inside', testId }) => {
  const { refetch } = useCurrentRSCRoute();
  const [isPending, startTransition] = React.useTransition();

  const handleClick = () =>
    startTransition(() => {
      void refetch().catch((err: unknown) => {
        console.error('InlineRefreshButton refetch failed', err);
      });
    });

  return (
    <button type="button" data-testid={testId} disabled={isPending} onClick={handleClick}>
      {isPending ? 'Refreshing…' : label}
    </button>
  );
};

export default InlineRefreshButton;
