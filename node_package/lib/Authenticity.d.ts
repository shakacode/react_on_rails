import type { AuthenticityHeaders } from './types/index.ts';

export declare function authenticityToken(): string | null;
export declare const authenticityHeaders: (otherHeaders?: Record<string, string>) => AuthenticityHeaders;
