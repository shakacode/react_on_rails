const { fileURLToPath } = require('url');

class RSCManifestCssPlugin {
  constructor(options = {}) {
    this.clientManifestFilename = options.clientManifestFilename || 'react-client-manifest.json';
  }

  apply(compiler) {
    const pluginName = 'RSCManifestCssPlugin';

    compiler.hooks.thisCompilation.tap(pluginName, (compilation) => {
      const { webpack } = compiler;
      const reportStage = webpack?.Compilation?.PROCESS_ASSETS_STAGE_REPORT;
      const stage = typeof reportStage === 'number' ? reportStage + 1 : undefined;

      compilation.hooks.processAssets.tap(
        {
          name: pluginName,
          stage,
        },
        () => {
          const asset = compilation.getAsset(this.clientManifestFilename);
          if (!asset) return;

          const manifest = this.parseManifest(asset.source.source(), compilation);
          if (!manifest) return;

          const metadata = manifest.filePathToModuleMetadata;
          if (!metadata || typeof metadata !== 'object') return;

          const chunksById = RSCManifestCssPlugin.chunksById(compilation);
          const modulesByResource = RSCManifestCssPlugin.modulesByResource(compilation);
          let changed = false;

          Object.entries(metadata).forEach(([resourceKey, entry]) => {
            if (!entry || !Array.isArray(entry.chunks)) return;

            const nextChunks = Array.isArray(entry.chunks) ? [...entry.chunks] : [];
            const chunkIdsWithJs = RSCManifestCssPlugin.chunkIdsWithJavaScriptFiles(nextChunks);
            const css = Array.isArray(entry.css) ? [...entry.css] : [];
            const seenCss = new Set(css);
            const chunks = RSCManifestCssPlugin.chunksForEntry(
              resourceKey,
              entry,
              chunksById,
              modulesByResource,
              compilation,
            );

            for (const chunk of chunks) {
              const jsFile = RSCManifestCssPlugin.javascriptFileForChunk(chunk);
              if (
                jsFile &&
                chunk.id !== null &&
                chunk.id !== undefined &&
                !chunkIdsWithJs.has(String(chunk.id))
              ) {
                chunkIdsWithJs.add(String(chunk.id));
                nextChunks.push(chunk.id, jsFile);
              }

              for (const file of RSCManifestCssPlugin.cssFilesForChunk(chunk)) {
                if (!seenCss.has(file)) {
                  seenCss.add(file);
                  css.push(file);
                }
              }
            }

            const nextEntry = { ...entry };
            let entryChanged = false;

            if (!RSCManifestCssPlugin.sameList(entry.chunks, nextChunks)) {
              nextEntry.chunks = nextChunks;
              entryChanged = true;
            }

            if (css.length > 0 && !RSCManifestCssPlugin.sameList(entry.css, css)) {
              nextEntry.css = css;
              entryChanged = true;
            }

            if (entryChanged) {
              metadata[resourceKey] = nextEntry;
              changed = true;
            }
          });

          if (!changed) return;

          compilation.updateAsset(
            this.clientManifestFilename,
            new webpack.sources.RawSource(JSON.stringify(manifest, null, 2)),
          );
        },
      );
    });
  }

  parseManifest(source, compilation) {
    try {
      return JSON.parse(source.toString());
    } catch (error) {
      compilation.warnings.push(
        new Error(
          `RSCManifestCssPlugin could not parse ${this.clientManifestFilename}: ${
            error instanceof Error ? error.message : error
          }`,
        ),
      );
      return null;
    }
  }

  static chunksById(compilation) {
    const chunks = new Map();
    for (const chunk of compilation.chunks) {
      if (chunk.id !== null && chunk.id !== undefined) {
        chunks.set(String(chunk.id), chunk);
      }
    }
    return chunks;
  }

  static chunksForEntry(resourceKey, entry, chunksById, modulesByResource, compilation) {
    const chunks = [];
    const seen = new Set();
    const addChunk = (chunk) => {
      if (!chunk || seen.has(chunk)) return;
      seen.add(chunk);
      chunks.push(chunk);
    };

    for (let index = 0; index < entry.chunks.length; index += 2) {
      addChunk(chunksById.get(String(entry.chunks[index])));
    }

    const module = RSCManifestCssPlugin.moduleForEntry(resourceKey, entry, modulesByResource);
    if (module && compilation.chunkGraph?.getModuleChunksIterable) {
      for (const chunk of compilation.chunkGraph.getModuleChunksIterable(module) || []) {
        addChunk(chunk);
      }
    }

    return chunks;
  }

  static chunkIdsWithJavaScriptFiles(chunks) {
    const ids = new Set();

    for (let index = 0; index < chunks.length - 1; index += 2) {
      const file = chunks[index + 1];
      if (typeof file === 'string' && file.endsWith('.js') && !file.endsWith('.hot-update.js')) {
        ids.add(String(chunks[index]));
      }
    }

    return ids;
  }

  static javascriptFileForChunk(chunk) {
    for (const file of chunk.files || []) {
      if (typeof file === 'string' && file.endsWith('.js') && !file.endsWith('.hot-update.js')) {
        return file;
      }
    }

    return null;
  }

  static cssFilesForChunk(chunk) {
    const files = [];

    for (const file of chunk.files || []) {
      if (typeof file === 'string' && file.endsWith('.css') && !file.endsWith('.hot-update.css')) {
        files.push(file);
      }
    }

    return files;
  }

  static modulesByResource(compilation) {
    const modules = new Map();
    const record = (module, owner = module) => {
      if (!module || typeof module.resource !== 'string') return;

      const resource = RSCManifestCssPlugin.normalizePath(module.resource);
      modules.set(resource, owner);
      modules.set(RSCManifestCssPlugin.stripResourceQuery(resource), owner);
    };

    for (const module of compilation.modules || []) {
      record(module);

      for (const nestedModule of module.modules || []) {
        record(nestedModule, module);
      }
    }

    return modules;
  }

  static moduleForEntry(resourceKey, entry, modulesByResource) {
    const candidates = RSCManifestCssPlugin.resourceCandidates(resourceKey, entry);

    for (const candidate of candidates) {
      const resource = RSCManifestCssPlugin.normalizePath(candidate);
      const exactMatch =
        modulesByResource.get(resource) ||
        modulesByResource.get(RSCManifestCssPlugin.stripResourceQuery(resource));
      if (exactMatch) return exactMatch;

      const suffix = `/${resource.replace(/^\.\//, '')}`;
      for (const [moduleResource, module] of modulesByResource) {
        if (moduleResource.endsWith(suffix)) return module;
      }
    }

    return null;
  }

  static resourceCandidates(resourceKey, entry) {
    const candidates = [];

    if (typeof resourceKey === 'string') {
      if (resourceKey.startsWith('file://')) {
        try {
          candidates.push(fileURLToPath(resourceKey));
        } catch {
          candidates.push(resourceKey);
        }
      } else {
        candidates.push(resourceKey);
      }
    }

    if (entry && typeof entry.id === 'string') {
      candidates.push(entry.id);
    }

    return candidates;
  }

  static normalizePath(resource) {
    return resource.replace(/\\/g, '/');
  }

  static stripResourceQuery(resource) {
    return resource.split('?', 1)[0];
  }

  static sameList(left, right) {
    return (
      Array.isArray(left) &&
      left.length === right.length &&
      left.every((value, index) => value === right[index])
    );
  }
}

module.exports = RSCManifestCssPlugin;
