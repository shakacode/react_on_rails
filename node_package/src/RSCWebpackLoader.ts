import { pathToFileURL } from 'url';
import { LoaderDefinition } from 'webpack';

const RSCWebpackLoader: LoaderDefinition = function RSCWebpackLoader(source, sourceMap) {
  // Mark loader as async since we're doing async operations
  const callback = this.async();

  (async () => {
    // Convert file path to URL format
    const fileUrl = pathToFileURL(this.resourcePath).href;

    // Workaround for TS transpiling `await import` while we need to keep it.
    // See https://github.com/microsoft/TypeScript/issues/43329#issuecomment-1008361973
    // If we end up needing it more than once, prefer creating a non-compiled
    // `dynamicImport.js` file instead.
    // eslint-disable-next-line no-new-func
    const { load } = await new Function('return import("react-server-dom-webpack/node-loader")')() as
      typeof import('react-server-dom-webpack/node-loader');
    return load(fileUrl, null, async () => ({
      format: 'module',
      source,
    }));
  })().then(
    result => callback(null, result.source, sourceMap),
    error => callback(error),
  );
};

export default RSCWebpackLoader;
