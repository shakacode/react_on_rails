import { createBaseClientObject } from './base/client.ts';
import { createReactOnRails } from './createReactOnRails.ts';

const ReactOnRails = createReactOnRails(createBaseClientObject);

export * from './types/index.ts';
export default ReactOnRails;
