// // @ts-expect-error react-dom/client only available in React 18
// // eslint-disable-next-line import/no-unresolved 
// import ReactDOM from 'react-dom/client';
// import type { RootRenderFunction, RootHydrateFunction } from '../types';

// export const canHydrate = !!ReactDOM.hydrateRoot;

// export const hydrate: RootHydrateFunction = (domNode, reactElement) => ReactDOM.hydrateRoot(domNode, reactElement);

// export const render: RootRenderFunction = (domNode, reactElement) => {
//   const root = ReactDOM.createRoot(domNode);
//   root.render(reactElement);
//   return root;
// };
