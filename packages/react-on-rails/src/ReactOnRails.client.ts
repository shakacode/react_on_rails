import { createBaseClientObject } from './base/client.ts';
import createReactOnRails from './createReactOnRails.ts';

const currentGlobal = globalThis.ReactOnRails || null;
const ReactOnRails = createReactOnRails(createBaseClientObject, currentGlobal);

export * from './types/index.ts';
export default ReactOnRails;
