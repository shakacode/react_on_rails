import supportsReactCreateRoot from './supportsReactCreateRoot';
import type { RootRenderFunction, RootHydrateFunction } from '../types';

interface RenderHelper {
  canHydrate: boolean;
  reactHydrate: RootHydrateFunction;
  reactRender: RootRenderFunction;
}

export default (async (): Promise<RenderHelper> => {
  const toImport = supportsReactCreateRoot === true ? 'react-dom/client' : 'react-dom';
  const ReactDOM = await import(toImport);

  let canHydrate: RenderHelper['canHydrate'];
  let reactHydrate: RenderHelper['reactHydrate'];
  let reactRender: RenderHelper['reactRender'];

  if (supportsReactCreateRoot === true) {
    canHydrate = !!ReactDOM.hydrateRoot;
    reactHydrate = (domNode, reactElement) => ReactDOM.hydrateRoot(domNode, reactElement);
    reactRender = (domNode, reactElement) => {
      const root = ReactDOM.createRoot(domNode);
      root.render(reactElement);
      return root;
    };
  } else {
    canHydrate = !!ReactDOM.hydrate;
    reactHydrate = (domNode, reactElement) => ReactDOM.hydrate(reactElement, domNode);
    // eslint-disable-next-line react/no-render-return-value
    reactRender = (domNode, reactElement) => ReactDOM.render(reactElement, domNode);
  }

  return {
    canHydrate,
    reactHydrate,
    reactRender,
  };
})();
