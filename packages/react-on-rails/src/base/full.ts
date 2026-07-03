/**
 * @deprecated Use `capabilities/ssr.ts` instead. This file is kept for backward compatibility
 * with older versions of react-on-rails-pro that import from `react-on-rails/@internal/base/full`.
 */

// This is a thin compatibility shim: the SSR implementations live in `capabilities/ssr.ts`
// (`createSSRCapability`). This file composes them onto the base client object, preserving
// the historical `createBaseFullObject` surface old Pro consumers rely on.

import { createBaseClientObject, type BaseClientObjectType } from './client.ts';
import type { ReactOnRailsInternal } from '../types/index.ts';
import { createSSRCapability } from '../capabilities/ssr.ts';

/**
 * SSR-specific functions that extend the base client object to create a full object.
 * Typed explicitly to ensure type safety when mutating the base object.
 */
export type ReactOnRailsFullSpecificFunctions = Pick<
  ReactOnRailsInternal,
  'handleError' | 'serverRenderReactComponent' | 'prepareRenderResult'
>;

/**
 * Full object type that includes all base methods plus real SSR implementations.
 * Derived from ReactOnRailsInternal by picking base methods and SSR methods.
 * Note: BaseClientObjectType already includes serverRenderReactComponent and handleError,
 * so ReactOnRailsFullSpecificFunctions is a subset.
 * @public
 */
export type BaseFullObjectType = Pick<ReactOnRailsInternal, keyof BaseClientObjectType>;

export function createBaseFullObject(
  registries: Parameters<typeof createBaseClientObject>[0],
  currentObject: BaseClientObjectType | null = null,
): BaseFullObjectType {
  // Get or create client object (with caching logic)
  const clientObject = createBaseClientObject(registries, currentObject);

  // Delegate the SSR-specific functions to `createSSRCapability` (the canonical source).
  // Typed to ReactOnRailsFullSpecificFunctions so we add exactly the SSR surface, nothing more.
  const reactOnRailsFullSpecificFunctions: ReactOnRailsFullSpecificFunctions = createSSRCapability();

  // Type assertion is safe here because:
  // 1. We start with BaseClientObjectType (from createBaseClientObject)
  // 2. We add exactly the methods defined in ReactOnRailsFullSpecificFunctions
  // 3. BaseFullObjectType = BaseClientObjectType + ReactOnRailsFullSpecificFunctions
  // TypeScript can't track the mutation, but we ensure type safety by explicitly typing
  // the functions object above
  const fullObject = clientObject as unknown as BaseFullObjectType;

  // Assign SSR-specific functions to the full object using Object.assign
  // This pattern ensures we add exactly what's defined in the type, nothing more, nothing less
  Object.assign(fullObject, reactOnRailsFullSpecificFunctions);

  return fullObject;
}
