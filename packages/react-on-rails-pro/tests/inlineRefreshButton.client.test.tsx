/* eslint-disable react/prop-types */
import * as React from 'react';
import { Suspense } from 'react';
import { act, fireEvent, render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

import { createRSCProvider } from '../src/RSCProvider.tsx';
import RSCRoute, { useCurrentRSCRoute } from '../src/RSCRoute.tsx';
import { getNodeVersion } from './testUtils';

type InlineRefreshButtonProps = {
  label?: string;
  testId?: string;
};

const InlineRefreshButton: React.FC<InlineRefreshButtonProps> = ({
  label = 'Refresh from inside',
  testId,
}) => {
  const { refetch } = useCurrentRSCRoute();
  const [isPending, startTransition] = React.useTransition();

  const handleClick = () =>
    startTransition(() => {
      void refetch();
    });

  return (
    <button type="button" data-testid={testId} disabled={isPending} onClick={handleClick}>
      {isPending ? 'Refreshing…' : label}
    </button>
  );
};

type GetServerComponentArgs = {
  componentName: string;
  componentProps: unknown;
  enforceRefetch?: boolean;
};

type Deferred<T> = {
  promise: Promise<T>;
  resolve: (v: T) => void;
  reject: (err: unknown) => void;
};

const createDeferred = <T,>(): Deferred<T> => {
  let resolveFn!: (v: T) => void;
  let rejectFn!: (err: unknown) => void;
  const promise = new Promise<T>((resolve, reject) => {
    resolveFn = resolve;
    rejectFn = reject;
  });
  return { promise, resolve: resolveFn, reject: rejectFn };
};

(getNodeVersion() >= 18 ? describe : describe.skip)('InlineRefreshButton', () => {
  let getServerComponent: jest.Mock<Promise<React.ReactNode>, [GetServerComponentArgs]>;
  let RSCProvider: React.FC<{ children: React.ReactNode }>;

  const setupDeferredFetcher = () => {
    const pending: Deferred<React.ReactNode>[] = [];
    getServerComponent = jest.fn((_args: GetServerComponentArgs) => {
      const d = createDeferred<React.ReactNode>();
      pending.push(d);
      return d.promise;
    });
    RSCProvider = createRSCProvider({ getServerComponent });
    return pending;
  };

  const TestHarness: React.FC<{ children: React.ReactNode }> = ({ children }) => (
    <RSCProvider>
      <Suspense fallback={<div data-testid="fallback">loading</div>}>{children}</Suspense>
    </RSCProvider>
  );

  const NeverSettles: React.FC = () => {
    throw new Promise(() => {});
  };

  it('keeps the visible button pending until the refetched route tree commits', async () => {
    const pending = setupDeferredFetcher();

    await act(async () => {
      render(
        <TestHarness>
          <RSCRoute componentName="InlineDemo" componentProps={{}} />
        </TestHarness>,
      );
    });
    await act(async () => {
      pending[0].resolve(
        <div data-testid="card">
          v1
          <InlineRefreshButton testId="inline-refresh" />
        </div>,
      );
    });

    expect(screen.getByTestId('card')).toHaveTextContent('v1');
    expect(screen.getByTestId('inline-refresh')).toBeEnabled();

    await act(async () => {
      fireEvent.click(screen.getByTestId('inline-refresh'));
    });

    expect(screen.getByTestId('inline-refresh')).toBeDisabled();
    expect(screen.getByTestId('inline-refresh')).toHaveTextContent('Refreshing…');

    await act(async () => {
      pending[1].resolve(<NeverSettles />);
      await pending[1].promise;
    });

    expect(screen.getByTestId('card')).toHaveTextContent('v1');
    expect(screen.getByTestId('inline-refresh')).toBeDisabled();
    expect(screen.getByTestId('inline-refresh')).toHaveTextContent('Refreshing…');
  });
});
