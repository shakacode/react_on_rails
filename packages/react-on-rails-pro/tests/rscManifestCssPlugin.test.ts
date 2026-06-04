import { readFileSync } from 'fs';
import * as path from 'path';

// The plugin ships as a generated, app-owned CommonJS file (no default export, uses
// `require('url')`), so it is loaded with `require` rather than an ESM import. We load the
// generator template — the source of truth the generator copies into new apps — and separately
// assert the Pro dummy copy stays byte-identical (see "copies stay in sync" below).
const TEMPLATE_PATH = path.join(
  __dirname,
  '../../../react_on_rails/lib/generators/react_on_rails/templates/rsc/base/config/webpack/rscManifestCssPlugin.js',
);
const DUMMY_COPY_PATH = path.join(
  __dirname,
  '../../../react_on_rails_pro/spec/dummy/config/webpack/rscManifestCssPlugin.js',
);

// eslint-disable-next-line @typescript-eslint/no-require-imports, global-require, import/no-dynamic-require
const RSCManifestCssPlugin = require(TEMPLATE_PATH);

// webpack's Compilation.PROCESS_ASSETS_STAGE_REPORT constant; the plugin runs at REPORT + 1.
const REPORT_STAGE = 5000;

type FakeChunk = { id: unknown; files: string[] };
type FakeModule = { resource?: unknown; modules?: FakeModule[] };
type ManifestEntry = { chunks?: unknown[]; css?: unknown[]; [key: string]: unknown };
type ParsedManifest = { filePathToModuleMetadata: Record<string, ManifestEntry> };

class FakeRawSource {
  value: string;

  constructor(value: string) {
    this.value = value;
  }

  source(): string {
    return this.value;
  }
}

type CompilationConfig = {
  // The manifest the build emitted: an object (serialized to JSON), a raw string (to exercise
  // parse failures), or undefined (asset not emitted at all).
  manifest?: unknown;
  assetName?: string;
  chunks?: FakeChunk[];
  modules?: FakeModule[];
  moduleChunks?: Map<FakeModule, FakeChunk[]>;
  // Names returned by getAssets(); defaults to [assetName] when a manifest is present, else [].
  assetNames?: string[];
};

type FakeCompilation = {
  warnings: Error[];
  updates: { name: string; value: string }[];
  resultManifest: () => ParsedManifest | undefined;
  [key: string]: unknown;
};

function buildCompilation(config: CompilationConfig = {}): FakeCompilation {
  const {
    manifest,
    assetName = 'react-client-manifest.json',
    chunks = [],
    modules = [],
    moduleChunks = new Map<FakeModule, FakeChunk[]>(),
    assetNames,
  } = config;

  const warnings: Error[] = [];
  const updates: { name: string; value: string }[] = [];

  const manifestSource =
    manifest === undefined
      ? undefined
      : { source: () => (typeof manifest === 'string' ? manifest : JSON.stringify(manifest)) };

  const emittedNames = assetNames ?? (manifest === undefined ? [] : [assetName]);

  return {
    chunks,
    modules,
    warnings,
    updates,
    chunkGraph: {
      getModuleChunksIterable: (module: FakeModule) => moduleChunks.get(module) ?? [],
    },
    getAsset: (name: string) =>
      manifest !== undefined && name === assetName ? { source: manifestSource } : undefined,
    getAssets: () => emittedNames.map((name) => ({ name })),
    updateAsset: (name: string, src: FakeRawSource) => {
      updates.push({ name, value: src.source() });
    },
    resultManifest() {
      return updates.length > 0 ? JSON.parse(updates[updates.length - 1].value) : undefined;
    },
  };
}

// Drives the plugin against a fake compiler, returning the processAssets taps it registered so
// tests can assert on stage ordering and whether the tap ran at all.
function runPlugin(
  plugin: { apply: (compiler: unknown) => void },
  compilation: FakeCompilation,
  { missingStageReport = false }: { missingStageReport?: boolean } = {},
): { opts: { name: string; stage: number }; fn: () => void }[] {
  const processAssetsTaps: { opts: { name: string; stage: number }; fn: () => void }[] = [];
  compilation.hooks = {
    processAssets: {
      tap: (opts: { name: string; stage: number }, fn: () => void) => {
        processAssetsTaps.push({ opts, fn });
      },
    },
  };

  let thisCompilationFn: ((compilation: FakeCompilation) => void) | undefined;
  const compiler = {
    webpack: {
      Compilation: missingStageReport ? {} : { PROCESS_ASSETS_STAGE_REPORT: REPORT_STAGE },
      sources: { RawSource: FakeRawSource },
    },
    hooks: {
      thisCompilation: {
        tap: (_name: string, fn: (compilation: FakeCompilation) => void) => {
          thisCompilationFn = fn;
        },
      },
    },
  };

  plugin.apply(compiler);
  thisCompilationFn?.(compilation);
  // Execute the manifest-augmentation callback(s). Empty (a no-op) when the stage guard bailed.
  processAssetsTaps.forEach(({ fn }) => fn());
  return processAssetsTaps;
}

describe('RSCManifestCssPlugin', () => {
  describe('manifest augmentation', () => {
    it('adds the JS chunk pair and CSS siblings for a CSS-first module not yet in the manifest', () => {
      // The exact #3211 case: upstream scanning skips a chunk whose first file is CSS, leaving the
      // module entry with no chunks. The plugin recovers both the JS pair and the CSS sibling.
      const fooModule: FakeModule = { resource: '/app/components/Foo.jsx' };
      const fooChunk: FakeChunk = { id: 'foo', files: ['css/foo.css', 'js/foo.js'] };
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            '/app/components/Foo.jsx': { id: '/app/components/Foo.jsx', chunks: [], name: '*' },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      const entry = compilation.resultManifest()!.filePathToModuleMetadata['/app/components/Foo.jsx'];
      expect(entry.chunks).toEqual(['foo', 'js/foo.js']);
      expect(entry.css).toEqual(['css/foo.css']);
      expect(compilation.warnings).toHaveLength(0);
    });

    it('does not duplicate a JS chunk pair already present in the manifest', () => {
      const fooModule: FakeModule = { resource: '/app/components/Foo.jsx' };
      const fooChunk: FakeChunk = { id: 'foo', files: ['js/foo.js', 'css/foo.css'] };
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            '/app/components/Foo.jsx': {
              id: '/app/components/Foo.jsx',
              chunks: ['foo', 'js/foo.js'],
              name: '*',
            },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      const entry = compilation.resultManifest()!.filePathToModuleMetadata['/app/components/Foo.jsx'];
      // Still a single [id, file] pair — no duplication — but CSS is now recorded.
      expect(entry.chunks).toEqual(['foo', 'js/foo.js']);
      expect(entry.css).toEqual(['css/foo.css']);
    });

    it('excludes hot-update artifacts from both JS pairs and CSS, leaving the manifest untouched', () => {
      const fooModule: FakeModule = { resource: '/app/components/Foo.jsx' };
      const fooChunk: FakeChunk = {
        id: 'foo',
        files: ['js/foo.hot-update.js', 'css/foo.hot-update.css'],
      };
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            '/app/components/Foo.jsx': { id: '/app/components/Foo.jsx', chunks: [], name: '*' },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      // Nothing recordable -> no asset rewrite at all.
      expect(compilation.updates).toHaveLength(0);
      expect(compilation.warnings).toHaveLength(0);
    });

    it('records CSS but skips the JS pair when the chunk id is null', () => {
      const fooModule: FakeModule = { resource: '/app/components/Foo.jsx' };
      const fooChunk: FakeChunk = { id: null, files: ['js/foo.js', 'css/foo.css'] };
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            '/app/components/Foo.jsx': { id: '/app/components/Foo.jsx', chunks: [], name: '*' },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      const entry = compilation.resultManifest()!.filePathToModuleMetadata['/app/components/Foo.jsx'];
      expect(entry.chunks).toEqual([]);
      expect(entry.css).toEqual(['css/foo.css']);
    });

    it('resolves a file:// resourceKey to its module so CSS is attributed correctly', () => {
      const fooModule: FakeModule = { resource: '/app/components/Foo.jsx' };
      const fooChunk: FakeChunk = { id: 'foo', files: ['js/foo.js', 'css/foo.css'] };
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            'file:///app/components/Foo.jsx': { id: '1', chunks: [], name: '*' },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      const entry = compilation.resultManifest()!.filePathToModuleMetadata['file:///app/components/Foo.jsx'];
      expect(entry.css).toEqual(['css/foo.css']);
    });

    it('matches a module by path suffix when the resourceKey is not an exact resource', () => {
      const fooModule: FakeModule = { resource: '/abs/project/root/app/components/Foo.jsx' };
      const fooChunk: FakeChunk = { id: 'foo', files: ['js/foo.js', 'css/foo.css'] };
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            './app/components/Foo.jsx': { id: '1', chunks: [], name: '*' },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      const entry = compilation.resultManifest()!.filePathToModuleMetadata['./app/components/Foo.jsx'];
      expect(entry.css).toEqual(['css/foo.css']);
    });

    it('matches a module whose resource carries a loader query suffix', () => {
      const fooModule: FakeModule = { resource: '/app/components/Foo.scss?modules' };
      const fooChunk: FakeChunk = { id: 'foo', files: ['css/foo.css'] };
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            '/app/components/Foo.scss': { id: '1', chunks: [], name: '*' },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      const entry = compilation.resultManifest()!.filePathToModuleMetadata['/app/components/Foo.scss'];
      expect(entry.css).toEqual(['css/foo.css']);
    });

    it('does not rewrite the manifest when nothing changes', () => {
      const fooModule: FakeModule = { resource: '/app/components/Foo.jsx' };
      const fooChunk: FakeChunk = { id: 'foo', files: ['js/foo.js'] };
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            '/app/components/Foo.jsx': {
              id: '/app/components/Foo.jsx',
              chunks: ['foo', 'js/foo.js'],
              name: '*',
            },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      expect(compilation.updates).toHaveLength(0);
    });

    it('honors a custom clientManifestFilename', () => {
      const fooModule: FakeModule = { resource: '/app/components/Foo.jsx' };
      const fooChunk: FakeChunk = { id: 'foo', files: ['js/foo.js', 'css/foo.css'] };
      const compilation = buildCompilation({
        assetName: 'custom-client-manifest.json',
        manifest: {
          filePathToModuleMetadata: {
            '/app/components/Foo.jsx': { id: '1', chunks: [], name: '*' },
          },
        },
        chunks: [fooChunk],
        modules: [fooModule],
        moduleChunks: new Map([[fooModule, [fooChunk]]]),
      });

      runPlugin(
        new RSCManifestCssPlugin({ clientManifestFilename: 'custom-client-manifest.json' }),
        compilation,
      );

      expect(compilation.updates[0].name).toBe('custom-client-manifest.json');
      const entry = compilation.resultManifest()!.filePathToModuleMetadata['/app/components/Foo.jsx'];
      expect(entry.css).toEqual(['css/foo.css']);
    });
  });

  describe('failure handling', () => {
    it('warns when the configured manifest is missing but another client manifest was emitted', () => {
      const compilation = buildCompilation({
        manifest: undefined,
        assetNames: ['custom-client-manifest.json', 'manifest.json'],
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      expect(compilation.updates).toHaveLength(0);
      expect(compilation.warnings).toHaveLength(1);
      expect(compilation.warnings[0].message).toContain('react-client-manifest.json');
      expect(compilation.warnings[0].message).toContain('custom-client-manifest.json');
      // Only client manifests are surfaced as candidates, not unrelated manifests.
      expect(compilation.warnings[0].message).not.toContain('manifest.json,');
    });

    it('stays silent when no client manifest was emitted at all (HMR / non-RSC builds)', () => {
      const compilation = buildCompilation({
        manifest: undefined,
        assetNames: ['manifest.json', 'js/runtime.js'],
      });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      expect(compilation.updates).toHaveLength(0);
      expect(compilation.warnings).toHaveLength(0);
    });

    it('warns and leaves the manifest untouched when it cannot be parsed', () => {
      const compilation = buildCompilation({ manifest: 'not-json{' });

      runPlugin(new RSCManifestCssPlugin(), compilation);

      expect(compilation.updates).toHaveLength(0);
      expect(compilation.warnings).toHaveLength(1);
      expect(compilation.warnings[0].message).toContain('could not parse react-client-manifest.json');
    });

    it('warns and never taps processAssets when PROCESS_ASSETS_STAGE_REPORT is unavailable', () => {
      const compilation = buildCompilation({
        manifest: {
          filePathToModuleMetadata: {
            '/app/components/Foo.jsx': { id: '1', chunks: [], name: '*' },
          },
        },
      });

      const taps = runPlugin(new RSCManifestCssPlugin(), compilation, { missingStageReport: true });

      expect(taps).toHaveLength(0);
      expect(compilation.updates).toHaveLength(0);
      expect(compilation.warnings).toHaveLength(1);
      expect(compilation.warnings[0].message).toContain('PROCESS_ASSETS_STAGE_REPORT is not available');
    });
  });

  describe('stage ordering', () => {
    it('taps processAssets at PROCESS_ASSETS_STAGE_REPORT + 1 so it runs after the manifest is emitted', () => {
      const compilation = buildCompilation({
        manifest: { filePathToModuleMetadata: {} },
      });

      const taps = runPlugin(new RSCManifestCssPlugin(), compilation);

      expect(taps).toHaveLength(1);
      expect(taps[0].opts.stage).toBe(REPORT_STAGE + 1);
    });
  });

  describe('static helpers', () => {
    it('chunkIdsWithJavaScriptFiles records ids only for real JS files', () => {
      const ids = RSCManifestCssPlugin.chunkIdsWithJavaScriptFiles([
        'a',
        'js/a.js',
        'b',
        'css/b.css',
        'c',
        'js/c.hot-update.js',
      ]);
      expect([...ids]).toEqual(['a']);
    });

    it('javascriptFileForChunk returns the first non-hot-update JS file or null', () => {
      expect(
        RSCManifestCssPlugin.javascriptFileForChunk({ files: ['x.css', 'x.hot-update.js', 'x.js'] }),
      ).toBe('x.js');
      expect(RSCManifestCssPlugin.javascriptFileForChunk({ files: ['x.css'] })).toBeNull();
      expect(RSCManifestCssPlugin.javascriptFileForChunk({})).toBeNull();
    });

    it('cssFilesForChunk returns non-hot-update CSS files', () => {
      expect(RSCManifestCssPlugin.cssFilesForChunk({ files: ['x.js', 'x.css', 'x.hot-update.css'] })).toEqual(
        ['x.css'],
      );
      expect(RSCManifestCssPlugin.cssFilesForChunk({})).toEqual([]);
    });

    it('stripResourceQuery and normalizePath canonicalize resources', () => {
      expect(RSCManifestCssPlugin.stripResourceQuery('foo.scss?modules')).toBe('foo.scss');
      expect(RSCManifestCssPlugin.normalizePath('a\\b\\c.jsx')).toBe('a/b/c.jsx');
    });

    it('sameList compares element-wise and rejects non-arrays', () => {
      expect(RSCManifestCssPlugin.sameList(['a', 'b'], ['a', 'b'])).toBe(true);
      expect(RSCManifestCssPlugin.sameList(['a'], ['a', 'b'])).toBe(false);
      expect(RSCManifestCssPlugin.sameList(['a', 'b'], ['a', 'c'])).toBe(false);
      expect(RSCManifestCssPlugin.sameList(undefined, ['a'])).toBe(false);
    });
  });

  describe('generated copies stay in sync', () => {
    it('keeps the Pro dummy copy byte-identical to the generator template', () => {
      // The plugin is duplicated (generator template + Pro dummy). They must not drift, or the
      // dummy regression spec stops exercising what real apps ship.
      expect(readFileSync(DUMMY_COPY_PATH, 'utf8')).toBe(readFileSync(TEMPLATE_PATH, 'utf8'));
    });
  });
});
