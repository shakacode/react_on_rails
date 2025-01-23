import type { AuthenticityHeaders } from './types/index';

export default {
  authenticityToken(): string | null {
    const token = document.querySelector('meta[name="csrf-token"]');
    if (token instanceof HTMLMetaElement) {
      return token.content;
    }
    return null;
  },

  authenticityHeaders(otherHeaders: { [id: string]: string } = {}): AuthenticityHeaders {
    return Object.assign(otherHeaders, {
      'X-CSRF-Token': this.authenticityToken(),
      'X-Requested-With': 'XMLHttpRequest',
    });
  },
};
