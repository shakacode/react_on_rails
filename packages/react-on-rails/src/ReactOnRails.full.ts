import { createCoreCapability } from './capabilities/core.ts';
import { createLifecycleCapability } from './capabilities/lifecycle.ts';
import { createSSRCapability } from './capabilities/ssr.ts';
import createReactOnRails from './createReactOnRails.ts';
import ComponentRegistry from './ComponentRegistry.ts';
import StoreRegistry from './StoreRegistry.ts';
import { clientStartup } from './clientStartup.ts';

const registries = { ComponentRegistry, StoreRegistry };
const currentGlobal = globalThis.ReactOnRails || null;

const ReactOnRails = createReactOnRails(
  [createCoreCapability(registries), createLifecycleCapability(), createSSRCapability()],
  {
    currentGlobal,
    startup: typeof window !== 'undefined' ? () => setTimeout(() => clientStartup(), 0) : null,
    registries,
  },
);

export * from './types/index.ts';
export default ReactOnRails;
