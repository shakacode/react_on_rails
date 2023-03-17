import type { AuthenticityHeaders } from './types/index';
declare const _default: {
    authenticityToken(): string | null;
    authenticityHeaders(otherHeaders?: {
        [id: string]: string;
    }): AuthenticityHeaders;
};
export default _default;
