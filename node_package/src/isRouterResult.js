export default function isRouterResult(reactElementOrRouterResult) {
  return !!(
    reactElementOrRouterResult.redirectLocation ||
    reactElementOrRouterResult.error);
}
