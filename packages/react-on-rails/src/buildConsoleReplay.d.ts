declare global {
  interface Console {
    history?: {
      arguments: Array<string | Record<string, string>>;
      level: 'error' | 'log' | 'debug';
    }[];
  }
}
/** @internal Exported only for tests */
export declare function consoleReplay(
  customConsoleHistory?: (typeof console)['history'] | undefined,
  numberOfMessagesToSkip?: number,
): string;
export default function buildConsoleReplay(
  customConsoleHistory?: (typeof console)['history'] | undefined,
  numberOfMessagesToSkip?: number,
): string;
//# sourceMappingURL=buildConsoleReplay.d.ts.map
