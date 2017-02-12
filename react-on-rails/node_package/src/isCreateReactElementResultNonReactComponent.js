export default function isResultNonReactComponent(reactElementOrRouterResult) {
  return !!(
    reactElementOrRouterResult.renderedHtml ||
    reactElementOrRouterResult.redirectLocation ||
    reactElementOrRouterResult.error);
}
