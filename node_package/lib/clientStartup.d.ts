import type { ReactOnRails as ReactOnRailsType, Root } from './types';
declare global {
    interface Window {
        ReactOnRails: ReactOnRailsType;
        __REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__?: boolean;
        roots: Root[];
    }
    namespace NodeJS {
        interface Global {
            ReactOnRails: ReactOnRailsType;
            roots: Root[];
        }
    }
    namespace Turbolinks {
        interface TurbolinksStatic {
            controller?: unknown;
        }
    }
}
type Context = Window | NodeJS.Global;
export declare function reactOnRailsPageLoaded(): void;
export declare function clientStartup(context: Context): void;
export {};
