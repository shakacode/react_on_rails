import type { Registries } from './capabilities/core.ts';
import type { ReactOnRailsInternal } from './types/index.ts';

export type { Registries };

// Module-level cache for singleton enforcement and validation
let cachedObject: ReactOnRailsInternal | null = null;
let cachedRegistries: Registries | null = null;

/**
 * Assembles the ReactOnRails global object from an array of capabilities.
 *
 * Each capability is a partial implementation of ReactOnRailsInternal.
 * Capabilities are merged in array order (last wins for overlapping keys).
 *
 * @param capabilities - Array of capability objects to merge.
 * @param options.currentGlobal - Current globalThis.ReactOnRails value (for misconfiguration detection).
 * @param options.startup - Callback invoked once on first initialization, after the global is set.
 * @param options.registries - The registries used by the core capability (for mixing detection).
 */
export default function createReactOnRails(
  capabilities: Partial<ReactOnRailsInternal>[],
  options: {
    currentGlobal: ReactOnRailsInternal | null;
    startup: (() => void) | null;
    registries: Registries;
  },
): ReactOnRailsInternal {
  const { currentGlobal, startup, registries } = options;

  // ===================================================================
  // VALIDATION — preserved from base/client.ts
  // ===================================================================

  // Webpack misconfiguration detection: currentGlobal is null but we have a cached object.
  // This indicates webpack's optimization.runtimeChunk is set to "true" or "multiple".
  if (currentGlobal === null && cachedObject !== null) {
    throw new Error(`\
ReactOnRails was already initialized, but a new initialization was attempted without passing the existing global.
This usually means Webpack's optimization.runtimeChunk is set to "true" or "multiple" instead of "single".

Fix: Set optimization.runtimeChunk to "single" in your webpack configuration.
See: https://github.com/shakacode/react_on_rails/issues/1558`);
  }

  // Cross-runtime detection: another bundle/runtime already initialized the global,
  // but this module instance hasn't cached anything yet.
  // In development with HMR/fast-refresh, webpack invalidates the module cache
  // (resetting cachedObject to null) while globalThis.ReactOnRails persists from the
  // previous load. The old base/client.ts code handled this gracefully by returning
  // the existing global. We preserve that behavior in development and only throw in
  // production where this genuinely indicates misconfiguration (multiple runtimes or
  // mixed core/pro bundles).
  if (currentGlobal !== null && cachedObject === null) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error(`\
ReactOnRails was already initialized by another bundle or runtime instance.
This usually means multiple webpack runtimes or mixed core/pro bundles were loaded on the same page.

Fix: Ensure only one ReactOnRails bundle initializes per page, and set optimization.runtimeChunk to "single".`);
    }
    // In development (HMR), accept the pre-existing global and re-cache it.
    cachedObject = currentGlobal;
    cachedRegistries = registries;
    return cachedObject;
  }

  // Global contamination detection: currentGlobal exists but doesn't match cached object.
  if (currentGlobal !== null && cachedObject !== null && currentGlobal !== cachedObject) {
    throw new Error(`\
ReactOnRails global object mismatch detected.
The current global ReactOnRails object is different from the one created by this package.

This usually means:
1. You're mixing react-on-rails (core) with react-on-rails-pro
2. Another library is interfering with the global ReactOnRails object

Fix: Use only one package (core OR pro) consistently throughout your application.`);
  }

  // Registry mixing detection: different registries indicate core/pro package mixing.
  if (cachedRegistries !== null) {
    if (
      registries.ComponentRegistry !== cachedRegistries.ComponentRegistry ||
      registries.StoreRegistry !== cachedRegistries.StoreRegistry
    ) {
      throw new Error(`\
Cannot mix react-on-rails (core) with react-on-rails-pro.
Different registries detected - the packages use incompatible registries.

Fix: Use only react-on-rails OR react-on-rails-pro, not both.`);
    }
  }

  // Return cached object if already initialized (all validation passed above).
  // Merge only additive capabilities onto the existing object.
  // The first capability is the core baseline, which includes client/pro stubs.
  // Re-applying it during a later initialization can downgrade already-added methods
  // (e.g., SSR/streaming/RSC) back to stubs.
  if (cachedObject !== null) {
    Object.assign(cachedObject, ...capabilities.slice(1));
    return cachedObject;
  }

  // ===================================================================
  // ASSEMBLY — merge all capabilities in order
  // ===================================================================

  const reactOnRails = Object.assign({}, ...capabilities) as ReactOnRailsInternal;

  // Cache the object and registries
  cachedObject = reactOnRails;
  cachedRegistries = registries;

  // ===================================================================
  // GLOBAL ASSIGNMENT — only on first initialization
  // ===================================================================

  globalThis.ReactOnRails = reactOnRails;

  // Reset options to defaults
  reactOnRails.resetOptions();

  // Run startup callback
  if (startup) {
    startup();
  }

  return reactOnRails;
}
