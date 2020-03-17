import type { CREReturnTypes } from './types/index';

export default function isResultNonReactComponent(reactElementOrRouterResult: CREReturnTypes): boolean {
  return !!(
    (reactElementOrRouterResult as {renderedHtml: string}).renderedHtml ||
    (reactElementOrRouterResult as {redirectLocation: {pathname: string; search: string}}).redirectLocation ||
    (reactElementOrRouterResult as {routeError: Error}).routeError ||
    (reactElementOrRouterResult as {error: Error}).error);
}
