/**
 * Unit tests for captureReactOwnerStack (issue #3887).
 *
 * captureReactOwnerStack wraps React 19.1+'s dev-only `captureOwnerStack`. The two behaviors that
 * MUST hold regardless of the React version installed in the test workspace:
 *
 *   1. Production / older-React no-op: when `React.captureOwnerStack` is absent (production builds,
 *      and every React < 19.1), the helper never calls it and returns `undefined`.
 *   2. When the API IS present (React >= 19.1 dev build), the helper returns its trimmed string
 *      output and tolerates `null` / empty / throwing implementations.
 *
 * Because the helper reads `React.captureOwnerStack` lazily on each call, we exercise both behaviors
 * by mutating that property on the imported React module within a test, then restoring it.
 */

import * as React from 'react';
import captureReactOwnerStack from '../src/captureReactOwnerStack.ts';

// `react/experimental` types `captureOwnerStack` as a required `() => string | null`, but at runtime
// it is absent in production builds and on React < 19.1. Treat the property as an arbitrary,
// possibly-missing value so the tests can install/remove fakes that model those runtimes.
const reactModule = React as unknown as Record<'captureOwnerStack', unknown>;

const withCaptureOwnerStack = (impl: unknown, run: () => void): void => {
  const had = Object.prototype.hasOwnProperty.call(reactModule, 'captureOwnerStack');
  const original = reactModule.captureOwnerStack;
  reactModule.captureOwnerStack = impl;
  try {
    run();
  } finally {
    if (had) {
      reactModule.captureOwnerStack = original;
    } else {
      delete (reactModule as { captureOwnerStack?: unknown }).captureOwnerStack;
    }
  }
};

describe('captureReactOwnerStack', () => {
  it('returns undefined and does not call captureOwnerStack when the API is absent (production / React < 19.1 no-op)', () => {
    withCaptureOwnerStack(undefined, () => {
      expect(captureReactOwnerStack()).toBeUndefined();
    });
  });

  it('does not invoke a non-function captureOwnerStack', () => {
    // A production build does not export the API at all; assert we never treat a stray
    // non-function value as callable.
    withCaptureOwnerStack(null, () => {
      expect(captureReactOwnerStack()).toBeUndefined();
    });
  });

  it('returns the owner stack string when the dev API provides one', () => {
    const ownerStack = '\n    at Avatar\n    at PostCard\n    at PostList';
    const spy = jest.fn(() => ownerStack);
    withCaptureOwnerStack(spy, () => {
      expect(captureReactOwnerStack()).toBe(ownerStack);
    });
    expect(spy).toHaveBeenCalledTimes(1);
  });

  it('returns undefined when the dev API returns null (called outside render)', () => {
    withCaptureOwnerStack(
      () => null,
      () => {
        expect(captureReactOwnerStack()).toBeUndefined();
      },
    );
  });

  it('returns undefined when the dev API returns an empty / whitespace-only string', () => {
    withCaptureOwnerStack(
      () => '   \n  ',
      () => {
        expect(captureReactOwnerStack()).toBeUndefined();
      },
    );
  });

  it('never throws when the dev API throws', () => {
    withCaptureOwnerStack(
      () => {
        throw new Error('boom');
      },
      () => {
        expect(captureReactOwnerStack()).toBeUndefined();
      },
    );
  });
});
