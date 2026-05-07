/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

/**
 * PPR (Partial Prerendering) phase tracking.
 *
 * Two phases:
 *   - 'prerender': building the static shell. usePostpone() throws a never-resolving promise,
 *     so the surrounding <Suspense> boundary is captured as a hole.
 *   - 'resume':    request-time fill. usePostpone() is a no-op so the boundary renders normally.
 *
 * AsyncLocalStorage propagates the phase across awaits, timers, and stream events as long as
 * the related callback is registered inside withPhase(...). Pro's PPR capability defensively
 * wraps every callback boundary (timeouts, abort listeners, onError, prerender Promise chain)
 * with `withPhase` to avoid relying on subtle async_hooks behavior.
 */

type PPRPhase = 'prerender' | 'resume';

// AsyncLocalStorage is injected by the Pro node renderer as a VM global. Pull it from globalThis
// rather than `import 'node:async_hooks'` so this module loads cleanly even when run inside a
// constrained sandbox without Node externals (e.g. ExecJS — though PPR is gated to the node
// renderer at the Ruby helper level).
const ALSCtor = (globalThis as unknown as { AsyncLocalStorage?: new () => AsyncLocalStorageLike })
  .AsyncLocalStorage;

interface AsyncLocalStorageLike<T = { phase: PPRPhase }> {
  run<R>(store: T, fn: () => R): R;
  getStore(): T | undefined;
}

let phaseStore: AsyncLocalStorageLike | null = null;

/**
 * Lazily allocate the phase store on first PPR use. If AsyncLocalStorage is missing entirely,
 * we fall back to a module-level slot — safe because the Pro node renderer worker is single-
 * threaded per request and PPR is gated to that runtime by the Ruby helper.
 */
function getPhaseStore(): AsyncLocalStorageLike {
  if (phaseStore) return phaseStore;
  if (ALSCtor) {
    phaseStore = new ALSCtor();
    return phaseStore;
  }
  // Fallback (single-process, single-thread): one slot.
  let slot: { phase: PPRPhase } | undefined;
  const fallback: AsyncLocalStorageLike = {
    run<R>(store: { phase: PPRPhase }, fn: () => R): R {
      const prev = slot;
      slot = store;
      try {
        return fn();
      } finally {
        slot = prev;
      }
    },
    getStore(): { phase: PPRPhase } | undefined {
      return slot;
    },
  };
  phaseStore = fallback;
  return phaseStore;
}

/** Run `fn` with the active PPR phase set. Use defensively at every callback boundary. */
export function withPhase<R>(phase: PPRPhase, fn: () => R): R {
  return getPhaseStore().run({ phase }, fn);
}

/** Returns the current active PPR phase, or null if no PPR call is on the stack. */
export function getCurrentPhase(): PPRPhase | null {
  return getPhaseStore().getStore()?.phase ?? null;
}

// Single shared sentinel — allocated once. Throwing a never-resolving promise is the React 19.2
// idiom for declaring "I am dynamic; postpone my Suspense boundary". (React.unstable_postpone
// was removed before any stable release.)
const NEVER_RESOLVES: Promise<never> = new Promise<never>(() => {
  /* never resolves */
});

/**
 * Mark the surrounding <Suspense> boundary as a postponed hole during PPR's prerender phase.
 *
 * Behaviour:
 *   - Inside prerender → throws a never-resolving promise. The boundary becomes POSTPONED and
 *     its placeholder is emitted as `<template id="B:N"/>` in the prelude.
 *   - Inside resume    → no-op. The component renders normally with full request data.
 *   - Outside any PPR phase → no-op. usePostpone is safe to call from non-PPR render paths.
 *
 * @param _reason developer-friendly note. Unused at runtime but kept for ergonomics + parity
 *                with Next.js' equivalent helper.
 */
export function usePostpone(_reason?: string): void {
  if (getCurrentPhase() === 'prerender') {
    // eslint-disable-next-line @typescript-eslint/no-throw-literal -- React PPR contract is to
    // throw a (never-resolving) promise, not an Error. Throwing a thenable is how Suspense
    // detects "this is async" — the engine awaits it and never gets a result, so the boundary
    // is captured as a postponed task when AbortController fires.
    throw NEVER_RESOLVES;
  }
}
