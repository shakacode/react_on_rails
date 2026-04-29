/* eslint-disable react/prop-types, no-underscore-dangle */
import * as React from 'react';
import { Suspense } from 'react';
import { render, screen, act, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';

import { createRSCProvider } from '../src/RSCProvider.tsx';
import RSCRoute, { type RSCRouteHandle, useCurrentRSCRoute } from '../src/RSCRoute.tsx';
import { getNodeVersion } from './testUtils';

type GetServerComponentArgs = {
  componentName: string;
  componentProps: unknown;
  enforceRefetch?: boolean;
};

(getNodeVersion() >= 18 ? describe : describe.skip)('imperative refetch API', () => {
  let getServerComponent: jest.Mock<Promise<React.ReactNode>, [GetServerComponentArgs]>;
  let RSCProvider: React.FC<{ children: React.ReactNode }>;

  const TestHarness: React.FC<{ children: React.ReactNode }> = ({ children }) => (
    <RSCProvider>
      <Suspense fallback={<div data-testid="fallback">loading…</div>}>{children}</Suspense>
    </RSCProvider>
  );

  /**
   * Build a fetcher whose Nth call resolves with payloads[N]. Resolution is
   * deferred to a microtask so React's use() always sees a pending promise
   * first (matches the production path).
   */
  const setupSequencedFetcher = (payloads: React.ReactNode[]) => {
    let i = 0;
    getServerComponent = jest.fn(async (..._args: [GetServerComponentArgs]) => {
      const payload = payloads[i] ?? payloads[payloads.length - 1];
      i += 1;
      // Defer one microtask so `use()` always observes pending first.
      await Promise.resolve();
      return payload;
    });
    RSCProvider = createRSCProvider({ getServerComponent });
  };

  /**
   * Wrap the initial render in an act() so React drains microtasks queued by
   * `use(promise)` and we observe a settled tree on return. Without this,
   * @testing-library's `render` returns while Suspense is still showing the
   * fallback even though the underlying promise has resolved.
   */
  const renderInAct = async (ui: React.ReactElement) => {
    let result!: ReturnType<typeof render>;
    await act(async () => {
      result = render(ui);
    });
    return result;
  };

  const rerenderInAct = async (
    result: ReturnType<typeof render>,
    ui: React.ReactElement,
  ) => {
    await act(async () => {
      result.rerender(ui);
    });
  };

  beforeEach(() => {
    // Start each test with a sensible default; tests that need different
    // payloads call setupSequencedFetcher again.
    setupSequencedFetcher([<span data-testid="default">default</span>]);
  });

  it('1. ref.current.refetch() triggers a fresh getServerComponent call with enforceRefetch=true', async () => {
    setupSequencedFetcher([
      <div data-testid="card">Card v1</div>,
      <div data-testid="card">Card v2</div>,
    ]);
    const ref = React.createRef<RSCRouteHandle>();

    await renderInAct(
      <TestHarness>
        <RSCRoute ref={ref} componentName="UserCard" componentProps={{ id: 1 }} />
      </TestHarness>,
    );

    expect(getServerComponent).toHaveBeenCalledTimes(1);
    expect(getServerComponent).toHaveBeenLastCalledWith({
      componentName: 'UserCard',
      componentProps: { id: 1 },
    });

    expect(screen.getByTestId('card')).toHaveTextContent('Card v1');

    await act(async () => {
      await ref.current!.refetch();
    });

    expect(getServerComponent).toHaveBeenCalledTimes(2);
    expect(getServerComponent).toHaveBeenLastCalledWith({
      componentName: 'UserCard',
      componentProps: { id: 1 },
      enforceRefetch: true,
    });
  });

  it('2. captured refetch reflects latest props after a re-render', async () => {
    setupSequencedFetcher([
      <div data-testid="card">v1</div>,
      <div data-testid="card">v2 initial</div>,
      <div data-testid="card">v2 refetched</div>,
    ]);
    const ref = React.createRef<RSCRouteHandle>();

    const Root: React.FC<{ id: number }> = ({ id }) => (
      <TestHarness>
        <RSCRoute ref={ref} componentName="UserCard" componentProps={{ id }} />
      </TestHarness>
    );

    const result = await renderInAct(<Root id={1} />);
    expect(screen.getByTestId('card')).toHaveTextContent('v1');

    // Capture the handle BEFORE the re-render. A naive impl with
    // useCallback([componentName, componentProps]) would close over id=1 here.
    const captured = ref.current!.refetch;

    await rerenderInAct(result, <Root id={2} />);
    expect(screen.getByTestId('card')).toHaveTextContent('v2 initial');

    // Now invoke the captured (stale-looking) handle. It must read the latest
    // props from latestPropsRef, NOT the values it closed over at first render.
    await act(async () => {
      await captured();
    });

    const calls = getServerComponent.mock.calls.map((c) => c[0]);
    const refetchCall = calls.find((c) => c.enforceRefetch === true);
    expect(refetchCall).toEqual({
      componentName: 'UserCard',
      componentProps: { id: 2 },
      enforceRefetch: true,
    });
  });

  it('3. useCurrentRSCRoute() from a descendant calls refetch with the parent route name and props', async () => {
    const InlineButton: React.FC = () => {
      const { refetch } = useCurrentRSCRoute();
      return (
        <button type="button" data-testid="inline" onClick={() => void refetch()}>
          inline-refresh
        </button>
      );
    };

    setupSequencedFetcher([
      <div data-testid="dashboard">
        Dashboard
        <InlineButton />
      </div>,
      <div data-testid="dashboard">
        Dashboard refreshed
        <InlineButton />
      </div>,
    ]);

    await renderInAct(
      <TestHarness>
        <RSCRoute componentName="Dashboard" componentProps={{ tab: 'overview' }} />
      </TestHarness>,
    );

    expect(screen.getByTestId('inline')).toBeInTheDocument();

    await act(async () => {
      fireEvent.click(screen.getByTestId('inline'));
    });

    expect(getServerComponent).toHaveBeenCalledTimes(2);
    expect(getServerComponent).toHaveBeenLastCalledWith({
      componentName: 'Dashboard',
      componentProps: { tab: 'overview' },
      enforceRefetch: true,
    });
  });

  it('4. useCurrentRSCRoute() outside <RSCRoute> throws with the exact spec message', () => {
    const Bad: React.FC = () => {
      useCurrentRSCRoute();
      return null;
    };

    // Suppress the React-emitted error log for the expected throw.
    const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    expect(() =>
      render(
        <RSCProvider>
          <Bad />
        </RSCProvider>,
      ),
    ).toThrow('useCurrentRSCRoute must be used inside an <RSCRoute>');
    errSpy.mockRestore();
  });

  it('5a. ref.current is null after unmount', async () => {
    setupSequencedFetcher([<div data-testid="x">x</div>]);
    const ref = React.createRef<RSCRouteHandle>();

    const { unmount } = await renderInAct(
      <TestHarness>
        <RSCRoute ref={ref} componentName="X" componentProps={{}} />
      </TestHarness>,
    );
    expect(screen.getByTestId('x')).toBeInTheDocument();
    expect(ref.current).not.toBeNull();

    unmount();
    expect(ref.current).toBeNull();
  });

  it('5b. captured refetch called after unmount still updates the cache and does not throw', async () => {
    setupSequencedFetcher([
      <div data-testid="x">x1</div>,
      <div data-testid="x">x2</div>,
    ]);
    const ref = React.createRef<RSCRouteHandle>();
    const { unmount } = await renderInAct(
      <TestHarness>
        <RSCRoute ref={ref} componentName="X" componentProps={{}} />
      </TestHarness>,
    );
    expect(screen.getByTestId('x')).toHaveTextContent('x1');
    const captured = ref.current!.refetch;

    unmount();

    await act(async () => {
      await captured();
    });

    expect(getServerComponent).toHaveBeenCalledTimes(2);
    expect(getServerComponent).toHaveBeenLastCalledWith({
      componentName: 'X',
      componentProps: {},
      enforceRefetch: true,
    });
  });

  it('6. refetch auto-updates rendered content with no caller-side state bump', async () => {
    setupSequencedFetcher([
      <div data-testid="greeting">Hello A</div>,
      <div data-testid="greeting">Hello B</div>,
    ]);
    const ref = React.createRef<RSCRouteHandle>();

    await renderInAct(
      <TestHarness>
        <RSCRoute ref={ref} componentName="Greeting" componentProps={{}} />
      </TestHarness>,
    );

    expect(screen.getByTestId('greeting')).toHaveTextContent('Hello A');

    // Refetch with a new payload — without the test changing any component key/state.
    await act(async () => {
      await ref.current!.refetch();
    });

    await waitFor(() => expect(screen.getByTestId('greeting')).toHaveTextContent('Hello B'));
  });

  it('7. multi-instance fan-out: refetch on one instance updates a sibling sharing the same key', async () => {
    setupSequencedFetcher([<span>v1</span>, <span>v2</span>]);
    const ref = React.createRef<RSCRouteHandle>();

    await renderInAct(
      <TestHarness>
        <RSCRoute ref={ref} componentName="Shared" componentProps={{}} />
        <RSCRoute componentName="Shared" componentProps={{}} />
      </TestHarness>,
    );

    // Both instances share the cache key, so getServerComponent runs once.
    expect(getServerComponent).toHaveBeenCalledTimes(1);
    expect(screen.getAllByText('v1')).toHaveLength(2);

    await act(async () => {
      await ref.current!.refetch();
    });

    // Both siblings reflect the new payload.
    await waitFor(() => expect(screen.getAllByText('v2')).toHaveLength(2));
    expect(screen.queryByText('v1')).not.toBeInTheDocument();
  });
});
