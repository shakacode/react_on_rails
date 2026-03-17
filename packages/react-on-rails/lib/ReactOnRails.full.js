import { createBaseFullObject } from "./base/full.js";
import createReactOnRails from "./createReactOnRails.js";
const currentGlobal = globalThis.ReactOnRails || null;
const ReactOnRails = createReactOnRails(createBaseFullObject, currentGlobal);
export * from "./types/index.js";
export default ReactOnRails;
//# sourceMappingURL=ReactOnRails.full.js.map