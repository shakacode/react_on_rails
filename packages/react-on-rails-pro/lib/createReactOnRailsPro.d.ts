import { createBaseClientObject, type BaseClientObjectType } from 'react-on-rails/@internal/base/client';
import { createBaseFullObject } from 'react-on-rails/@internal/base/full';
import type { ReactOnRailsInternal } from 'react-on-rails/types';
type BaseObjectCreator = typeof createBaseClientObject | typeof createBaseFullObject;
export default function createReactOnRailsPro(baseObjectCreator: BaseObjectCreator, currentGlobal?: BaseClientObjectType | null): ReactOnRailsInternal;
export {};
//# sourceMappingURL=createReactOnRailsPro.d.ts.map