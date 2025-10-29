import { createBaseClientObject, type BaseClientObjectType } from './client.ts';
import type { ReactOnRailsInternal, RenderParams, RenderResult, ErrorOptions } from '../types/index.ts';
import handleError from '../handleError.ts';
import serverRenderReactComponent from '../serverRenderReactComponent.ts';

// Warn about bundle size when included in browser bundles
if (typeof window !== 'undefined') {
  console.warn(
    'Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. ' +
      'Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 ' +
      '(Requires creating a free account). Click this for the stack trace.',
  );
}

/**
 * SSR-specific functions that extend the base client object to create a full object.
 * Typed explicitly to ensure type safety when mutating the base object.
 */
export type ReactOnRailsFullSpecificFunctions = Pick<
  ReactOnRailsInternal,
  'handleError' | 'serverRenderReactComponent'
>;

/**
 * Full object type that includes all base methods plus real SSR implementations.
 * Derived from ReactOnRailsInternal by picking base methods and SSR methods.
 * @public
 */
export type BaseFullObjectType = Pick<
  ReactOnRailsInternal,
  keyof BaseClientObjectType | keyof ReactOnRailsFullSpecificFunctions
>;

export function createBaseFullObject(
  registries: Parameters<typeof createBaseClientObject>[0],
  currentObject: BaseClientObjectType | null = null,
): BaseFullObjectType {
  // Get or create client object (with caching logic)
  const clientObject = createBaseClientObject(registries, currentObject);

  // Define SSR-specific functions with proper types
  // This object acts as a type-safe specification of what we're adding to the base object
  const reactOnRailsFullSpecificFunctions: ReactOnRailsFullSpecificFunctions = {
    handleError(options: ErrorOptions): string | undefined {
      return handleError(options);
    },

    serverRenderReactComponent(options: RenderParams): null | string | Promise<RenderResult> {
      return serverRenderReactComponent(options);
    },
  };

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
