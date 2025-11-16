import { createBaseClientObject, type BaseClientObjectType } from './client.ts';
import type { BaseFullObjectType, ReactOnRailsFullSpecificFunctions } from './full.ts';

export type * from './full.ts';

export function createBaseFullObject(
  registries: Parameters<typeof createBaseClientObject>[0],
  currentObject: BaseClientObjectType | null = null,
): BaseFullObjectType {
  // Get or create client object (with caching logic)
  const clientObject = createBaseClientObject(registries, currentObject);

  // Define SSR-specific functions with proper types
  // This object acts as a type-safe specification of what we're adding to the base object
  const reactOnRailsFullSpecificFunctions: ReactOnRailsFullSpecificFunctions = {
    handleError() {
      throw new Error('"handleError" function is not supported in RSC bundle');
    },

    serverRenderReactComponent() {
      throw new Error('"serverRenderReactComponent" function is not supported in RSC bundle');
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
