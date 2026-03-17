import { createBaseClientObject, type BaseClientObjectType } from './client.ts';
import type { BaseFullObjectType } from './full.ts';
export type * from './full.ts';
export declare function createBaseFullObject(registries: Parameters<typeof createBaseClientObject>[0], currentObject?: BaseClientObjectType | null): BaseFullObjectType;
//# sourceMappingURL=full.rsc.d.ts.map