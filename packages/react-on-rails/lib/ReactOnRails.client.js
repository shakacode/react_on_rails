import { createBaseClientObject } from "./base/client.js";
import createReactOnRails from "./createReactOnRails.js";
const currentGlobal = globalThis.ReactOnRails || null;
const ReactOnRails = createReactOnRails(createBaseClientObject, currentGlobal);
export * from "./types/index.js";
export default ReactOnRails;
//# sourceMappingURL=ReactOnRails.client.js.map