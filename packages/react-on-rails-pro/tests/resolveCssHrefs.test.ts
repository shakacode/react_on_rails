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

  it('collects CSS across modules, prefixes, dedupes, and sorts', () => {
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

    // shared.css appears in two modules but is emitted once; output is sorted.
    expect(hrefs).toEqual([
      '/webpack/test/css/header.css',
      '/webpack/test/css/layout.css',
      '/webpack/test/css/shared.css',
    ]);
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
