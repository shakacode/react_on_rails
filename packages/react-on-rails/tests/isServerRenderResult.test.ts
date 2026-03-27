import { isServerRenderHash } from '../src/isServerRenderResult.ts';

describe('isServerRenderHash', () => {
  it('returns true for primary server render keys', () => {
    expect(isServerRenderHash({ renderedHtml: '<div />' })).toBe(true);
    expect(isServerRenderHash({ redirectLocation: { pathname: '/foo', search: '' } })).toBe(true);
    expect(isServerRenderHash({ routeError: { status: 404 } })).toBe(true);
    expect(isServerRenderHash({ error: 'boom' })).toBe(true);
  });

  it('does not classify clientProps-only objects as server render hashes', () => {
    expect(isServerRenderHash({ clientProps: { __tanstackRouterDehydratedState: { url: '/x' } } })).toBe(
      false,
    );
    expect(isServerRenderHash({ clientProps: { foo: 'bar' }, data: 'value' })).toBe(false);
    expect(isServerRenderHash({ clientProps: { foo: 'bar' }, then: () => {} })).toBe(false);
  });
});
