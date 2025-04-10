import type { AuthenticityHeaders } from './types/index';

export function authenticityToken(): string | null {
  const token = document.querySelector('meta[name="csrf-token"]');
  if (token instanceof HTMLMetaElement) {
    return token.content;
  }
  return null;
}

export const authenticityHeaders = (otherHeaders: Record<string, string> = {}): AuthenticityHeaders =>
  Object.assign(otherHeaders, {
    'X-CSRF-Token': authenticityToken(),
    'X-Requested-With': 'XMLHttpRequest',
  });
