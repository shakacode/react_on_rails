import resolveCssHrefs from '../src/resolveCssHrefs.ts';

describe('resolveCssHrefs', () => {
  it('returns an empty list when no module records CSS', () => {
    expect(
      resolveCssHrefs({
        moduleLoading: { prefix: '/webpack/' },
        filePathToModuleMetadata: {
          'file:///app/Button.jsx': { id: '1', chunks: ['1', 'js/1.js'], name: '*' },
        },
      }),
    ).toEqual([]);
  });

  it('collects CSS across modules, prefixes, dedupes, and preserves manifest order', () => {
    const hrefs = resolveCssHrefs({
      moduleLoading: { prefix: '/webpack/test/' },
      filePathToModuleMetadata: {
        'file:///app/Layout.jsx': {
          id: '1',
          chunks: [],
          css: ['css/layout.css', 'css/shared.css'],
          name: '*',
        },
        'file:///app/Header.jsx': {
          id: '2',
          chunks: [],
          css: ['css/header.css', 'css/shared.css'],
          name: '*',
        },
      },
    });

    // shared.css appears in two modules but is emitted once where it first appears.
    expect(hrefs).toEqual([
      '/webpack/test/css/layout.css',
      '/webpack/test/css/shared.css',
      '/webpack/test/css/header.css',
    ]);
  });

  it('includes CSS for every manifest entry because rendered client references are not available here', () => {
    const hrefs = resolveCssHrefs({
      moduleLoading: { prefix: '/packs/' },
      filePathToModuleMetadata: {
        'file:///app/RenderedClient.jsx': {
          id: '1',
          chunks: [],
          css: ['css/rendered-client.css'],
          name: '*',
        },
        'file:///app/UnrenderedClient.jsx': {
          id: '2',
          chunks: [],
          css: ['css/unrendered-client.css'],
          name: '*',
        },
      },
    });

    expect(hrefs).toEqual(['/packs/css/rendered-client.css', '/packs/css/unrendered-client.css']);
  });

  it('joins prefix and file with exactly one slash regardless of trailing/leading slashes', () => {
    expect(
      resolveCssHrefs({
        moduleLoading: { prefix: 'https://cdn.example.com/assets' },
        filePathToModuleMetadata: {
          'file:///app/A.jsx': { css: ['/css/a.css'] },
          'file:///app/B.jsx': { css: ['css/b.css'] },
        },
      }),
    ).toEqual(['https://cdn.example.com/assets/css/a.css', 'https://cdn.example.com/assets/css/b.css']);
  });

  it('does not double-prefix root-relative css files that already include the webpack prefix', () => {
    expect(
      resolveCssHrefs({
        moduleLoading: { prefix: '/webpack/test/' },
        filePathToModuleMetadata: {
          'file:///app/SimpleClientComponent.jsx': {
            id: '1',
            chunks: [],
            css: ['/webpack/test/css/client5-6dd89694.css'],
            name: '*',
          },
        },
      }),
    ).toEqual(['/webpack/test/css/client5-6dd89694.css']);
  });

  it('still prefixes a root-relative css file that does not already include the webpack prefix', () => {
    expect(
      resolveCssHrefs({
        moduleLoading: { prefix: '/webpack/test/' },
        filePathToModuleMetadata: {
          'file:///app/SimpleClientComponent.jsx': {
            id: '1',
            chunks: [],
            css: ['/css/client5-6dd89694.css'],
            name: '*',
          },
        },
      }),
    ).toEqual(['/webpack/test/css/client5-6dd89694.css']);
  });

  it('treats a missing prefix as empty (bare hrefs)', () => {
    expect(
      resolveCssHrefs({
        filePathToModuleMetadata: {
          'file:///app/A.jsx': { css: ['css/a.css'] },
        },
      }),
    ).toEqual(['css/a.css']);
  });

  it('ignores empty/blank css entries and unpatched manifests', () => {
    expect(
      resolveCssHrefs({
        moduleLoading: { prefix: '/webpack/' },
        filePathToModuleMetadata: {
          'file:///app/A.jsx': { css: [''] },
          'file:///app/B.jsx': undefined,
          'file:///app/C.jsx': { id: '3', chunks: [], name: '*' },
        },
      }),
    ).toEqual([]);

    expect(resolveCssHrefs({})).toEqual([]);
  });
});
