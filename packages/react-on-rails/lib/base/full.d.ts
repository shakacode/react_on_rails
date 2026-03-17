import { createBaseClientObject, type BaseClientObjectType } from './client.ts';
import type { ReactOnRailsInternal } from '../types/index.ts';
/**
 * SSR-specific functions that extend the base client object to create a full object.
 * Typed explicitly to ensure type safety when mutating the base object.
 */
export type ReactOnRailsFullSpecificFunctions = Pick<ReactOnRailsInternal, 'handleError' | 'serverRenderReactComponent'>;
/**
 * Full object type that includes all base methods plus real SSR implementations.
 * Derived from ReactOnRailsInternal by picking base methods and SSR methods.
 * Note: BaseClientObjectType already includes serverRenderReactComponent and handleError,
 * so ReactOnRailsFullSpecificFunctions is a subset.
 * @public
 */
export type BaseFullObjectType = Pick<ReactOnRailsInternal, keyof BaseClientObjectType>;
export declare function createBaseFullObject(registries: Parameters<typeof createBaseClientObject>[0], currentObject?: BaseClientObjectType | null): BaseFullObjectType;
//# sourceMappingURL=full.d.ts.map