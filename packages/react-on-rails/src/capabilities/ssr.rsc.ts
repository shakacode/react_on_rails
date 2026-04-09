/* eslint-disable import/prefer-default-export -- named export for consistency with capability API */

/**
 * SSR capability for RSC bundles.
 * SSR methods throw because they are not supported in the RSC bundle.
 */
export function createSSRCapability() {
  return {
    handleError() {
      throw new Error('"handleError" function is not supported in RSC bundle');
    },

    serverRenderReactComponent() {
      throw new Error('"serverRenderReactComponent" function is not supported in RSC bundle');
    },
  };
}
