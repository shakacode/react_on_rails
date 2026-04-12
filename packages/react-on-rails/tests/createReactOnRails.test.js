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
