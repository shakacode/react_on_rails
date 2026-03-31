# New Architecture: JS Package Design

## Design Principle

Replace the stub-throw + Object.assign mutation pattern with **capability-based composition** where each package provides a self-contained set of features and the final `ReactOnRails` object is assembled from these capabilities in a single, predictable step.

## Current Problem Recap

The `ReactOnRails` global object is built through 5 mutation stages:

```
Stage 1: createBaseClientObject/createBaseFullObject → base methods
Stage 2: createReactOnRails → core overrides + Pro stubs (Object.assign)
Stage 3: createReactOnRailsPro → Pro overrides (Object.assign)
Stage 4: ReactOnRails.node.ts → streaming SSR method
Stage 5: ReactOnRailsRSC.ts → RSC render method
```

Each stage `Object.assign`s onto the same object, with later stages overwriting earlier ones. Pro must check "did a previous stage already add this method?" before overwriting.

## Proposed: Capability Modules

### Core Concept

Instead of mutating a single object through multiple stages, each package exports **capability modules** — plain objects containing related methods. A single factory function composes them:

```typescript
// react-on-rails/src/capabilities/registry.ts
export const registryCapability = {
  register: (components) => ComponentRegistry.register(components),
  getComponent: (name) => ComponentRegistry.get(name),
  registerStore: (stores) => StoreRegistry.register(stores),
  getStore: (name) => StoreRegistry.getStore(name),
  // ...
};

// react-on-rails/src/capabilities/auth.ts
export const authCapability = {
  authenticityToken: () => /* ... */,
  authenticityHeaders: (headers) => /* ... */,
};

// react-on-rails/src/capabilities/rendering.ts
export const clientRenderingCapability = {
  reactHydrateOrRender: (domNode, element, hydrate) => /* ... */,
  render: (name, props, domNodeId, hydrate) => /* ... */,
};

// react-on-rails/src/capabilities/ssr.ts
export const ssrCapability = {
  serverRenderReactComponent: (options) => /* ... */,
  handleError: (options) => /* ... */,
  buildConsoleReplay: () => /* ... */,
};
```

### Assembly (Core)

```typescript
// react-on-rails/src/ReactOnRails.client.ts
import { createReactOnRails } from './createReactOnRails.ts';
import { registryCapability } from './capabilities/registry.ts';
import { authCapability } from './capabilities/auth.ts';
import { clientRenderingCapability } from './capabilities/rendering.ts';
import { clientLifecycleCapability } from './capabilities/lifecycle.ts';

export default createReactOnRails([
  registryCapability,
  authCapability,
  clientRenderingCapability,
  clientLifecycleCapability,
]);

// react-on-rails/src/ReactOnRails.full.ts (server bundle)
import { ssrCapability } from './capabilities/ssr.ts';

export default createReactOnRails([
  registryCapability,
  authCapability,
  clientRenderingCapability,
  clientLifecycleCapability,
  ssrCapability, // adds serverRenderReactComponent, handleError
]);
```

### Assembly (Pro)

```typescript
// react-on-rails-pro/src/ReactOnRails.full.ts
import { createReactOnRails } from 'react-on-rails/createReactOnRails';
import { registryCapability } from 'react-on-rails/capabilities/registry';
import { authCapability } from 'react-on-rails/capabilities/auth';
import { clientRenderingCapability } from 'react-on-rails/capabilities/rendering';
import { ssrCapability } from 'react-on-rails/capabilities/ssr';

// Pro imports its own capabilities that ADD new methods
import { proRegistryCapability } from './capabilities/proRegistry.ts';
import { proLifecycleCapability } from './capabilities/proLifecycle.ts';
import { streamingCapability } from './capabilities/streaming.ts';

export default createReactOnRails([
  registryCapability,
  authCapability,
  clientRenderingCapability,
  ssrCapability,
  // Pro capabilities come after core, overriding specific methods
  proRegistryCapability, // adds getOrWaitForComponent, getOrWaitForStore
  proLifecycleCapability, // replaces reactOnRailsPageLoaded with Pro version
  streamingCapability, // adds streamServerRenderedReactComponent
]);
```

### The Factory Function

```typescript
// react-on-rails/src/createReactOnRails.ts
import type { ReactOnRailsInternal } from './types/index.ts';

type Capability = Partial<ReactOnRailsInternal>;

export function createReactOnRails(capabilities: Capability[]): ReactOnRailsInternal {
  // Compose all capabilities into a single object
  const reactOnRails = {} as ReactOnRailsInternal;

  for (const capability of capabilities) {
    Object.assign(reactOnRails, capability);
  }

  // Validate that all required methods are present
  validateRequiredMethods(reactOnRails);

  // Assign to global (idempotent)
  if (!globalThis.ReactOnRails) {
    globalThis.ReactOnRails = reactOnRails;
    reactOnRails.resetOptions();
    scheduleClientStartup(reactOnRails);
  }

  return reactOnRails;
}

function validateRequiredMethods(obj: ReactOnRailsInternal): void {
  const required = ['register', 'registerStore', 'getStore', 'authenticityToken'];
  for (const method of required) {
    if (typeof (obj as Record<string, unknown>)[method] !== 'function') {
      throw new Error(`ReactOnRails: missing required method '${method}'`);
    }
  }
}
```

## Benefits

### 1. No stub-throw pattern

Core doesn't need to define stubs for Pro methods. If Pro isn't installed, those methods simply don't exist on the object. The TypeScript types handle this:

```typescript
// Public type (what end users see)
interface ReactOnRails {
  register(components: Record<string, ReactComponentOrRenderFunction>): void;
  registerStore(stores: Record<string, StoreGenerator>): void;
  getStore(name: string): Store | undefined;
  // ... core methods
}

// Extended type (available when Pro is installed)
interface ReactOnRailsPro extends ReactOnRails {
  getOrWaitForComponent(name: string): Promise<RegisteredComponent>;
  getOrWaitForStore(name: string): Promise<Store>;
  streamServerRenderedReactComponent(options: RenderParams): Readable;
  serverRenderRSCReactComponent(options: RSCRenderParams): Readable;
}
```

End users who need Pro methods can type-narrow:

```typescript
if ('getOrWaitForComponent' in ReactOnRails) {
  // TypeScript knows this is ReactOnRailsPro
  const component = await ReactOnRails.getOrWaitForComponent('MyComponent');
}
```

### 2. Single-step assembly

The object is composed once from an explicit list of capabilities. No multi-stage mutation, no timing dependencies, no "did someone already add this method?" checks.

### 3. Tree-shakeable

Each capability is an independent module. Bundlers can tree-shake unused capabilities. If a client bundle doesn't import `ssrCapability`, `serverRenderReactComponent` and all its dependencies are eliminated.

### 4. Adding Pro features requires zero core changes

To add a new Pro feature, create a new capability module in `react-on-rails-pro` and include it in the assembly list. Core is untouched.

### 5. Type-safe without `as unknown as`

The factory function returns `ReactOnRailsInternal` (or a narrower type). No type casting needed because the object is built atomically rather than mutated.

## Registry Changes

### Current: Two separate registries with different interfaces

Core `ComponentRegistry.ts`:

```typescript
// Simple synchronous Map
registeredComponents.get(name); // or throws
```

Pro `ComponentRegistry.ts`:

```typescript
// CallbackRegistry with async waiting
componentRegistry.getOrWaitForItem(name);
```

### Proposed: Single configurable registry

```typescript
// react-on-rails/src/ComponentRegistry.ts
class ComponentRegistry {
  private components = new Map<string, RegisteredComponent>();
  private waiters = new Map<string, Array<(component: RegisteredComponent) => void>>();

  register(components: Record<string, ReactComponentOrRenderFunction>): void {
    for (const [name, component] of Object.entries(components)) {
      const registered = this.classify(name, component);
      this.components.set(name, registered);
      // Resolve any pending waiters
      this.resolveWaiters(name, registered);
    }
  }

  get(name: string): RegisteredComponent {
    const component = this.components.get(name);
    if (component) return component;
    throw new Error(`Component '${name}' not registered`);
  }

  // Async waiting is built into the core registry but only exposed via Pro capability
  getOrWaitFor(name: string, timeout: number): Promise<RegisteredComponent> {
    const existing = this.components.get(name);
    if (existing) return Promise.resolve(existing);

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new Error(`Timed out waiting for component '${name}'`));
      }, timeout);

      const waiters = this.waiters.get(name) || [];
      waiters.push((component) => {
        clearTimeout(timer);
        resolve(component);
      });
      this.waiters.set(name, waiters);
    });
  }

  private resolveWaiters(name: string, component: RegisteredComponent): void {
    const waiters = this.waiters.get(name);
    if (!waiters) return;
    waiters.forEach((resolve) => resolve(component));
    this.waiters.delete(name);
  }

  private classify(name: string, component: ReactComponentOrRenderFunction): RegisteredComponent {
    const renderFunction = isRenderFunction(component);
    const isRenderer = renderFunction && component.length === 3;
    return { name, component, renderFunction, isRenderer };
  }
}
```

The async waiting logic lives in the core registry, but `getOrWaitFor` is only exposed through the Pro capability:

```typescript
// react-on-rails-pro/src/capabilities/proRegistry.ts
export const proRegistryCapability = {
  getOrWaitForComponent(name: string): Promise<RegisteredComponent> {
    return ComponentRegistry.getOrWaitFor(name, timeout);
  },
  getOrWaitForStore(name: string): Promise<Store> {
    return StoreRegistry.getOrWaitFor(name, timeout);
  },
};
```

This eliminates the need for two separate registry implementations while keeping the public interface unchanged.

## Package Export Changes

### Current

```json
{
  "exports": {
    ".": "lib/ReactOnRails.full.js",
    "./client": "lib/ReactOnRails.client.js",
    "./@internal/base/client": "lib/base/client.js",
    "./@internal/base/full": {
      "react-server": "lib/base/full.rsc.js",
      "default": "lib/base/full.js"
    }
  }
}
```

Pro imports from `@internal` paths, creating tight coupling to core's internal structure.

### Proposed

```json
{
  "exports": {
    ".": "lib/ReactOnRails.full.js",
    "./client": "lib/ReactOnRails.client.js",
    "./createReactOnRails": "lib/createReactOnRails.js",
    "./capabilities/registry": "lib/capabilities/registry.js",
    "./capabilities/auth": "lib/capabilities/auth.js",
    "./capabilities/rendering": "lib/capabilities/rendering.js",
    "./capabilities/ssr": "lib/capabilities/ssr.js",
    "./capabilities/lifecycle": "lib/capabilities/lifecycle.js",
    "./ComponentRegistry": "lib/ComponentRegistry.js",
    "./StoreRegistry": "lib/StoreRegistry.js",
    "./types": "lib/types/index.js"
  }
}
```

Pro imports from stable public exports (`capabilities/*`), not internal paths. The capabilities are the explicit extension API.

## Client Startup Changes

### Current: Different startup for Core vs Pro

Core calls `clientStartup()` in setTimeout. Pro calls its own `clientStartup()` synchronously (for immediate hydration). These are separate code paths that can conflict.

### Proposed: Lifecycle capability handles startup

```typescript
// Core lifecycle
export const clientLifecycleCapability = {
  reactOnRailsPageLoaded(): Promise<void> {
    renderAllComponents();
    return Promise.resolve();
  },
  reactOnRailsComponentLoaded(domId: string): Promise<void> {
    return renderComponent(domId);
  },
};

// Pro lifecycle (replaces core when Pro is used)
export const proLifecycleCapability = {
  reactOnRailsPageLoaded(): Promise<void> {
    return Promise.all([hydrateAllStores(), renderOrHydrateAllComponents()]).then(() => {});
  },
  reactOnRailsComponentLoaded(domId: string): Promise<void> {
    return renderOrHydrateComponent(domId);
  },
  reactOnRailsStoreLoaded(storeName: string): Promise<void> {
    return hydrateStore(storeName);
  },
};
```

The factory function handles startup scheduling based on which lifecycle capability is present, removing the need for separate startup logic per package.

## Summary

| Current                                                  | Proposed                                             |
| -------------------------------------------------------- | ---------------------------------------------------- |
| 5-stage Object.assign mutation                           | Single-step capability composition                   |
| Stub-throw for Pro methods                               | Methods only exist when their capability is included |
| `@internal` package imports                              | `capabilities/*` public exports                      |
| Two separate ComponentRegistry implementations           | Single registry with optional async features         |
| Two separate factory functions                           | One factory, different capability lists              |
| `as unknown as` type casts                               | Atomic object construction, no casts needed          |
| Global `__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__` flag | Factory handles idempotency                          |
