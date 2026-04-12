import { createCoreCapability } from './capabilities/core.ts';
import { createLifecycleCapability } from './capabilities/lifecycle.ts';
import createReactOnRails from './createReactOnRails.ts';
import ComponentRegistry from './ComponentRegistry.ts';
import StoreRegistry from './StoreRegistry.ts';
import { clientStartup } from './clientStartup.ts';

const registries = { ComponentRegistry, StoreRegistry };
const currentGlobal = globalThis.ReactOnRails || null;

const ReactOnRails = createReactOnRails([createCoreCapability(registries), createLifecycleCapability()], {
  currentGlobal,
  // Defer startup to the next tick so all synchronous <script> tags finish evaluating
  // before we scan the DOM for components. Pro's proClientStartup runs synchronously
  // because streaming hydration needs to attach listeners before the first paint.
  startup: typeof window !== 'undefined' ? () => setTimeout(() => clientStartup(), 0) : null,
  registries,
});

export * from './types/index.ts';
export default ReactOnRails;
