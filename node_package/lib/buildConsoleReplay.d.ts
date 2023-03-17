declare global {
    interface Console {
        history?: {
            arguments: Array<string | Record<string, string>>;
            level: "error" | "log" | "debug";
        }[];
    }
}
export declare function consoleReplay(): string;
export default function buildConsoleReplay(): string;
