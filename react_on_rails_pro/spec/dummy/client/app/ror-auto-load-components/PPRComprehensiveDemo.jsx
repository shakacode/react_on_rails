'use client';
// 'use client' tells the generator NOT to wrap this in registerServerComponent (RSC). PPR works
// on the SSR HTML layer; ppr_react_component refuses RSC-tagged components.
// Auto-loaded as `PPRComprehensiveDemo`. Used by ppr_react_component on the demo page.
export { default } from '../components/PPRDemo/PPRDemo';
