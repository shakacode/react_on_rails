import supportsReactCreateRoot from './supportsReactCreateRoot';
import * as legacyRootHandler from './legacyRootHandler';
import * as modernRootHandler from './modernRootHandler';


let toExport;

if (supportsReactCreateRoot) {
  toExport = legacyRootHandler;
} else {
  toExport = modernRootHandler;
}

export const {
  canHydrate,
  hydrate: reactHydrate,
  render: reactRender
} = toExport;

