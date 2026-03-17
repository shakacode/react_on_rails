import { createBaseClientObject, type BaseClientObjectType } from './base/client.ts';
import { createBaseFullObject } from './base/full.ts';
import type { ReactOnRailsInternal } from './types/index.ts';
type BaseObjectCreator = typeof createBaseClientObject | typeof createBaseFullObject;
export default function createReactOnRails(baseObjectCreator: BaseObjectCreator, currentGlobal?: BaseClientObjectType | null): ReactOnRailsInternal;
export {};
//# sourceMappingURL=createReactOnRails.d.ts.map