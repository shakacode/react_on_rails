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

  // Return cached object if already initialized (all validation passed above)
  if (cachedObject !== null) {
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
