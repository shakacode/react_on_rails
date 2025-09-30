import { reactHydrate, reactRender } from './reactApis.cjs';
export default function reactHydrateOrRender(domNode, reactElement, hydrate) {
  return hydrate ? reactHydrate(domNode, reactElement) : reactRender(domNode, reactElement);
}
//# sourceMappingURL=reactHydrateOrRender.js.map
