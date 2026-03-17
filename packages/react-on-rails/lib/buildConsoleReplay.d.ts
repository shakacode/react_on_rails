declare global {
    interface Console {
        history?: {
            arguments: Array<string | Record<string, string>>;
            level: 'error' | 'log' | 'debug';
        }[];
    }
}
/**
 * Returns the console replay JavaScript code without wrapping it in script tags.
 * This is useful when you want to wrap the code in script tags yourself (e.g., with a CSP nonce).
 * @internal Exported for tests and for Ruby helper to wrap with nonce
 */
export declare function consoleReplay(customConsoleHistory?: (typeof console)['history'], numberOfMessagesToSkip?: number): string;
export default function buildConsoleReplay(customConsoleHistory?: (typeof console)['history'], numberOfMessagesToSkip?: number, nonce?: string): string;
//# sourceMappingURL=buildConsoleReplay.d.ts.map