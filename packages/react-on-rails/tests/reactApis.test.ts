/**
 * @jest-environment jsdom
 */

// reactApis loads react-dom/client inside a try so webpack treats it as optional for React 16/17.
// Only a missing react-dom/client may fall back to react-dom. Any other load failure must surface.

const moduleNotFound = (specifier: string): Error =>
  Object.assign(new Error(`Cannot find module '${specifier}'`), { code: 'MODULE_NOT_FOUND' });

describe('reactApis loading react-dom/client', () => {
  beforeEach(() => {
    jest.resetModules();
    jest.dontMock('react');
    jest.doMock('react-dom', () => ({ version: '19.0.0' }));
  });

  const loadReactApis = () =>
    // eslint-disable-next-line @typescript-eslint/no-require-imports, global-require
    require('../src/reactApis.cts') as typeof import('../src/reactApis.cts');

  it('rethrows when a dependency of react-dom/client cannot be found', () => {
    jest.doMock('react-dom/client', () => {
      throw moduleNotFound('scheduler');
    });

    expect(loadReactApis).toThrow("Cannot find module 'scheduler'");
  });

  it('rethrows when react-dom/client throws an error that is not MODULE_NOT_FOUND', () => {
    jest.doMock('react-dom/client', () => {
      throw new TypeError('react-dom/client failed to initialize');
    });

    expect(loadReactApis).toThrow('react-dom/client failed to initialize');
  });

  it('falls back to react-dom when react-dom/client itself is missing', () => {
    const hydrateRoot = jest.fn();
    jest.doMock('react-dom', () => ({ version: '19.0.0', hydrateRoot }));
    jest.doMock('react-dom/client', () => {
      throw moduleNotFound('react-dom/client');
    });

    const domNode = document.createElement('div');

    loadReactApis().reactHydrate(domNode, null as never);

    expect(hydrateRoot).toHaveBeenCalledWith(domNode, null, undefined);
  });

  it('does not load client-only APIs in React Server Components', () => {
    jest.doMock('react', () => ({ use: jest.fn() }));
    const loadClient = jest.fn(() => {
      throw new Error('react-dom/client is not supported in React Server Components.');
    });
    jest.doMock('react-dom/client', loadClient);

    expect(loadReactApis).not.toThrow();
    expect(loadClient).not.toHaveBeenCalled();
  });

  it('uses react-dom/client when it loads', () => {
    const hydrateRoot = jest.fn();
    jest.doMock('react-dom/client', () => ({ createRoot: jest.fn(), hydrateRoot }));
    const domNode = document.createElement('div');

    loadReactApis().reactHydrate(domNode, null as never);

    expect(hydrateRoot).toHaveBeenCalledWith(domNode, null, undefined);
  });
});
