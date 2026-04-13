describe('createReactOnRails validation', () => {
  const makeCoreCapability = (overrides = {}) => ({
    options: {},
    resetOptions() {
      this.options = {};
    },
    ...overrides,
  });

  const makeRegistries = () => ({
    ComponentRegistry: {},
    StoreRegistry: {},
  });

  beforeEach(() => {
    jest.resetModules();
    delete globalThis.ReactOnRails;
  });

  it('throws when webpack runtimeChunk is misconfigured (currentGlobal null, already cached)', () => {
    jest.isolateModules(() => {
      const createReactOnRails = require('../src/createReactOnRails.ts').default;
      const registries = makeRegistries();

      // First init succeeds and caches the object
      createReactOnRails([makeCoreCapability()], {
        currentGlobal: null,
        startup: null,
        registries,
      });

      // Second init with currentGlobal=null means a separate runtime chunk
      expect(() =>
        createReactOnRails([makeCoreCapability()], {
          currentGlobal: null,
          startup: null,
          registries,
        }),
      ).toThrow(/optimization\.runtimeChunk/);
    });
  });

  it('throws on global object mismatch (currentGlobal differs from cached)', () => {
    jest.isolateModules(() => {
      const createReactOnRails = require('../src/createReactOnRails.ts').default;
      const registries = makeRegistries();

      createReactOnRails([makeCoreCapability()], {
        currentGlobal: null,
        startup: null,
        registries,
      });

      // Replace globalThis.ReactOnRails with a different object
      const imposter = { fake: true };
      globalThis.ReactOnRails = imposter;

      expect(() =>
        createReactOnRails([makeCoreCapability()], {
          currentGlobal: imposter,
          startup: null,
          registries,
        }),
      ).toThrow(/global object mismatch/);
    });
  });

  it('throws on registry mismatch (different registries indicate core/pro mixing)', () => {
    jest.isolateModules(() => {
      const createReactOnRails = require('../src/createReactOnRails.ts').default;
      const registries1 = makeRegistries();

      createReactOnRails([makeCoreCapability()], {
        currentGlobal: null,
        startup: null,
        registries: registries1,
      });

      // Second init with different registries
      const registries2 = makeRegistries();
      expect(() =>
        createReactOnRails([makeCoreCapability()], {
          currentGlobal: globalThis.ReactOnRails,
          startup: null,
          registries: registries2,
        }),
      ).toThrow(/Cannot mix react-on-rails/);
    });
  });

  it('re-caches gracefully in development when HMR resets module state', () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';
    try {
      const registries = makeRegistries();

      // First init in one module instance
      jest.resetModules();
      const createReactOnRails1 = require('../src/createReactOnRails.ts').default;
      const first = createReactOnRails1([makeCoreCapability()], {
        currentGlobal: null,
        startup: null,
        registries,
      });

      // Simulate HMR: module re-evaluates (fresh import, cachedObject=null)
      // but globalThis.ReactOnRails still holds the previous object.
      jest.resetModules();
      const createReactOnRails2 = require('../src/createReactOnRails.ts').default;

      // Should NOT throw — should gracefully re-cache the existing global
      const second = createReactOnRails2([makeCoreCapability()], {
        currentGlobal: first,
        startup: null,
        registries,
      });

      expect(second).toBe(first);
    } finally {
      process.env.NODE_ENV = originalEnv;
    }
  });
});

describe('createReactOnRails capability layering', () => {
  const makeCoreCapability = (overrides = {}) => ({
    options: {},
    resetOptions() {
      this.options = {};
    },
    ...overrides,
  });

  const makeRegistries = () => ({
    ComponentRegistry: {},
    StoreRegistry: {},
  });

  beforeEach(() => {
    jest.resetModules();
    delete globalThis.ReactOnRails;
  });

  it('preserves a previously layered SSR implementation on re-initialization', () => {
    jest.isolateModules(() => {
      const createReactOnRails = require('../src/createReactOnRails.ts').default;
      const registries = makeRegistries();
      const serverRenderStub = jest.fn(() => 'core-stub');
      const serverRenderImpl = jest.fn(() => 'full-implementation');

      const firstInitialization = createReactOnRails(
        [
          makeCoreCapability({
            serverRenderReactComponent: serverRenderStub,
          }),
          {
            serverRenderReactComponent: serverRenderImpl,
          },
        ],
        {
          currentGlobal: null,
          startup: null,
          registries,
        },
      );

      const secondInitialization = createReactOnRails(
        [
          makeCoreCapability({
            serverRenderReactComponent: serverRenderStub,
          }),
        ],
        {
          currentGlobal: globalThis.ReactOnRails,
          startup: null,
          registries,
        },
      );

      expect(secondInitialization).toBe(firstInitialization);
      expect(secondInitialization.serverRenderReactComponent).toBe(serverRenderImpl);
    });
  });

  it('still layers newly provided capabilities on top of a cached object', () => {
    jest.isolateModules(() => {
      const createReactOnRails = require('../src/createReactOnRails.ts').default;
      const registries = makeRegistries();
      const streamStub = jest.fn(() => 'core-stub');
      const streamImpl = jest.fn(() => 'pro-implementation');

      const firstInitialization = createReactOnRails(
        [
          makeCoreCapability({
            streamServerRenderedReactComponent: streamStub,
          }),
        ],
        {
          currentGlobal: null,
          startup: null,
          registries,
        },
      );

      const secondInitialization = createReactOnRails(
        [
          makeCoreCapability({
            streamServerRenderedReactComponent: streamStub,
          }),
          {
            streamServerRenderedReactComponent: streamImpl,
          },
        ],
        {
          currentGlobal: globalThis.ReactOnRails,
          startup: null,
          registries,
        },
      );

      expect(secondInitialization).toBe(firstInitialization);
      expect(secondInitialization.streamServerRenderedReactComponent).toBe(streamImpl);
    });
  });
});
