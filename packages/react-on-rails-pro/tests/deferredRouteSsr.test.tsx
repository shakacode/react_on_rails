import { describe, expect, it, jest } from '@jest/globals';
import * as React from 'react';
import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { renderToString } from 'react-dom/server';
import { createRSCProvider } from '../src/RSCProvider.tsx';
import RSCRoute from '../src/RSCRoute.tsx';
import { isServerComponentFetchError } from '../src/ServerComponentFetchError.ts';

class CapturingErrorBoundary extends React.Component<
  { children: React.ReactNode; onError: (error: Error) => void },
  { hasError: boolean }
> {
  constructor(props: { children: React.ReactNode; onError: (error: Error) => void }) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error) {
    this.props.onError(error);
  }

  render() {
    const { children } = this.props;
    const { hasError } = this.state;

    return hasError ? null : children;
  }
}

const renderRouteToString = (props: Partial<React.ComponentProps<typeof RSCRoute>> = {}) =>
  renderToString(<RSCRoute componentName="DeferredRoute" componentProps={{ id: 1 }} {...props} />);

describe('RSCRoute deferred SSR behavior', () => {
  it('returns empty server output when ssr is false', () => {
    expect(renderRouteToString({ ssr: false })).toBe('');
  });

  it('does not require RSC context while the deferred route is skipped', () => {
    expect(() => renderRouteToString({ ssr: false })).not.toThrow();
  });

  it.each<[string, boolean | undefined]>([
    ['omitted', undefined],
    ['true', true],
  ])('preserves the existing provider requirement when ssr is %s', (_label, ssr) => {
    expect(() => renderRouteToString(ssr === undefined ? {} : { ssr })).toThrow(
      'useRSC must be used within a RSCProvider',
    );
  });

  it('does not generate provider cache keys or call the loader while skipped on the server', () => {
    const circularProps: Record<string, unknown> = {};
    circularProps.self = circularProps;

    const getServerComponent = jest.fn(() => Promise.resolve(<div>Should not load</div>));
    const RSCProvider = createRSCProvider({ getServerComponent });

    expect(() =>
      renderToString(
        <RSCProvider>
          <RSCRoute componentName="CircularRoute" componentProps={circularProps} ssr={false} />
        </RSCProvider>,
      ),
    ).not.toThrow();
    expect(getServerComponent).not.toHaveBeenCalled();
  });

  it('allows default routes to enter the provider path while deferred routes skip server work', () => {
    const getServerComponent = jest.fn(() => Promise.resolve(<div>Loaded route</div>));
    const RSCProvider = createRSCProvider({ getServerComponent });

    try {
      renderToString(
        <RSCProvider>
          <>
            <RSCRoute componentName="DeferredRoute" componentProps={{ id: 2 }} ssr={false} />
            <RSCRoute componentName="ImmediateRoute" componentProps={{ id: 1 }} />
          </>
        </RSCProvider>,
      );
    } catch {
      // renderToString may throw once PromiseWrapper consumes the unresolved immediate route promise.
      // The provider calls that started before that point are the behavior this test asserts.
    }

    expect(getServerComponent).toHaveBeenCalledTimes(1);
    expect(getServerComponent).toHaveBeenCalledWith({
      componentName: 'ImmediateRoute',
      componentProps: { id: 1 },
    });
    expect(getServerComponent).not.toHaveBeenCalledWith({
      componentName: 'DeferredRoute',
      componentProps: { id: 2 },
    });
  });

  it.each<[string, Partial<React.ComponentProps<typeof RSCRoute>>]>([
    ['omitted', {}],
    ['true', { ssr: true }],
  ])('uses the existing provider path when ssr is %s', (_label, props) => {
    const getServerComponent = jest.fn(() => Promise.resolve(<div>Deferred route loaded</div>));
    const RSCProvider = createRSCProvider({ getServerComponent });

    try {
      renderToString(
        <RSCProvider>
          <RSCRoute componentName="DeferredRoute" componentProps={{ id: 1 }} {...props} />
        </RSCProvider>,
      );
    } catch {
      // renderToString may throw once PromiseWrapper consumes the unresolved RSC promise.
      // The provider call happens before that point and is the behavior this test asserts.
    }

    expect(getServerComponent).toHaveBeenCalledTimes(1);
    expect(getServerComponent).toHaveBeenCalledWith({
      componentName: 'DeferredRoute',
      componentProps: { id: 1 },
    });
  });

  it('uses the existing provider path after the deferred route mounts', async () => {
    const getServerComponent = jest.fn(() => Promise.resolve(<div>Deferred route loaded</div>));
    const RSCProvider = createRSCProvider({ getServerComponent });
    const container = document.createElement('div');
    document.body.appendChild(container);
    let root: Root | undefined;

    try {
      root = createRoot(container);

      await act(async () => {
        root?.render(
          <RSCProvider>
            <React.Suspense fallback={<div>Loading deferred route...</div>}>
              <RSCRoute componentName="DeferredRoute" componentProps={{ id: 1 }} ssr={false} />
            </React.Suspense>
          </RSCProvider>,
        );
        await Promise.resolve();
      });

      expect(getServerComponent).toHaveBeenCalledTimes(1);
      expect(getServerComponent).toHaveBeenCalledWith({
        componentName: 'DeferredRoute',
        componentProps: { id: 1 },
      });
    } finally {
      const mountedRoot = root;
      if (mountedRoot) {
        await act(async () => {
          mountedRoot.unmount();
          await Promise.resolve();
        });
      }
      container.remove();
    }
  });

  it('wraps rejected deferred payloads in ServerComponentFetchError after mount', async () => {
    let rejectPayload: ((error: Error) => void) | undefined;
    const payloadPromise = new Promise<React.ReactNode>((_resolve, reject) => {
      rejectPayload = reject;
    });
    const getServerComponent = jest.fn(() => payloadPromise);
    const RSCProvider = createRSCProvider({ getServerComponent });
    const container = document.createElement('div');
    document.body.appendChild(container);
    let root: Root | undefined;
    let capturedError: Error | undefined;
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => undefined);

    try {
      root = createRoot(container);

      await act(async () => {
        root?.render(
          <RSCProvider>
            <CapturingErrorBoundary
              onError={(error) => {
                capturedError = error;
              }}
            >
              <React.Suspense fallback={<div>Loading deferred route...</div>}>
                <RSCRoute componentName="DeferredRoute" componentProps={{ id: 1 }} ssr={false} />
              </React.Suspense>
            </CapturingErrorBoundary>
          </RSCProvider>,
        );
        await Promise.resolve();
      });

      expect(getServerComponent).toHaveBeenCalledTimes(1);

      const payloadError = new Error('payload failed');
      await act(async () => {
        rejectPayload?.(payloadError);
        await payloadPromise.catch(() => undefined);
        await Promise.resolve();
        await Promise.resolve();
      });

      expect(isServerComponentFetchError(capturedError)).toBe(true);
      if (!isServerComponentFetchError(capturedError)) {
        throw new Error('Expected a ServerComponentFetchError');
      }
      expect(capturedError.message).toBe('payload failed');
      expect(capturedError.serverComponentName).toBe('DeferredRoute');
      expect(capturedError.serverComponentProps).toEqual({ id: 1 });
      expect(capturedError.originalError).toBe(payloadError);
    } finally {
      const mountedRoot = root;
      try {
        if (mountedRoot) {
          await act(async () => {
            mountedRoot.unmount();
            await Promise.resolve();
          });
        }
        container.remove();
      } finally {
        consoleErrorSpy.mockRestore();
      }
    }
  });
});
