export default function isResultNonReactComponent(reactElementOrRouterResult: any): boolean {
  return !!(
    reactElementOrRouterResult.renderedHtml ||
    reactElementOrRouterResult.redirectLocation ||
    reactElementOrRouterResult.error);
}
