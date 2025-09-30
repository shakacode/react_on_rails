import type { ReactOnRailsInternal, RailsContext } from './types/index.ts';
declare global {
  var ReactOnRails: ReactOnRailsInternal;
  var __REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__: boolean;
}
export declare function getRailsContext(): RailsContext | null;
export declare function resetRailsContext(): void;
//# sourceMappingURL=context.d.ts.map
