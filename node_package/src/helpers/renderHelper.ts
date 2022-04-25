import supportsReactCreateRoot from './supportsReactCreateRoot';
import * as legacyRootHandler from './legacyRootHandler';
import * as modernRootHandler from './modernRootHandler';


let toExport;

if (supportsReactCreateRoot) {
  toExport = modernRootHandler;
} else {
  toExport = legacyRootHandler;
}

export const {
  canHydrate,
  hydrate: reactHydrate,
  render: reactRender
} = toExport;

