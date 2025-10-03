import { createBaseFullObject } from './base/full.ts';
import { createReactOnRails } from './createReactOnRails.ts';

const ReactOnRails = createReactOnRails(createBaseFullObject);

export * from './types/index.ts';
export default ReactOnRails;
