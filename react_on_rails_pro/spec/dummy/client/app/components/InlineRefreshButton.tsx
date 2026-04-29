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
  return (
    <button
      type="button"
      data-testid={testId}
      disabled={pending}
      onClick={async () => {
        setPending(true);
        try {
          await refetch();
        } finally {
          setPending(false);
        }
      }}
    >
      {pending ? 'Refreshing…' : label}
    </button>
  );
};

export default InlineRefreshButton;
