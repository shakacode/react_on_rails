const ENTRY_PATHS = { rspack: '/main.js', vite: '/src/index.js' };

export function assertExactlyOneEntry(html, tool) {
  const expectedPath = ENTRY_PATHS[tool];
  if (!expectedPath) throw new Error(`unknown control ${tool}`);

  const scriptSources = [...html.matchAll(/<script\b[^>]*\bsrc=["']([^"']+)["']/giu)].map(
    (match) => new URL(match[1], 'http://benchmark.invalid').pathname,
  );
  const entryCount = scriptSources.filter((source) => source === expectedPath).length;
  if (entryCount !== 1) {
    throw new Error(`expected exactly one ${tool} entry ${expectedPath}; found ${entryCount}`);
  }
}
