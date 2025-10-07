import { createBaseFullObject } from './base/full.ts';
import createReactOnRails from './createReactOnRails.ts';

const currentGlobal = globalThis.ReactOnRails || null;
const ReactOnRails = createReactOnRails(createBaseFullObject, currentGlobal);

export * from './types/index.ts';
export default ReactOnRails;
