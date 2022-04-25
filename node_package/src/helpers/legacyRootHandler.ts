import ReactDOM from 'react-dom';
import type { RootRenderFunction, RootHydrateFunction } from '../types';

export const canHydrate = !!ReactDOM.hydrate

export const hydrate: RootHydrateFunction = (domNode, reactElement) => {
  return ReactDOM.hydrate(reactElement, domNode)
}

export const render: RootRenderFunction = (domNode, reactElement) => {
  return ReactDOM.render(reactElement, domNode);
}
