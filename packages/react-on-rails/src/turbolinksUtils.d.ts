declare global {
  namespace Turbolinks {
    interface TurbolinksStatic {
      controller?: unknown;
    }
  }
}
/**
 * Formats a message if the `traceTurbolinks` option is enabled.
 * Multiple arguments can be passed like to `console.log`,
 * except format specifiers aren't substituted (because it isn't used as the first argument).
 */
export declare function debugTurbolinks(...msg: unknown[]): void;
export declare function turbolinksInstalled(): boolean;
export declare function turboInstalled(): boolean;
export declare function turbolinksVersion5(): boolean;
export declare function turbolinksSupported(): boolean;
//# sourceMappingURL=turbolinksUtils.d.ts.map
