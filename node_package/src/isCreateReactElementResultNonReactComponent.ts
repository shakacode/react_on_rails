import { Component } from 'react';

export default function isResultNonReactComponent(
  reactElementOrRouterResult: {renderedHtml: string} | {redirectLocation: string} | {error: Error} | Component
): boolean {
  return !!(
    reactElementOrRouterResult.renderedHtml ||
    reactElementOrRouterResult.redirectLocation ||
    reactElementOrRouterResult.error);
}
