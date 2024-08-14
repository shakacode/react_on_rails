// This is the default node-renderer from running `yarn start`
import { reactOnRailsProNodeRenderer } from './ReactOnRailsProNodeRenderer';

console.log('React on Rails Pro Node Renderer with ENV config');

reactOnRailsProNodeRenderer().catch((e: unknown) => {
  throw e;
});
