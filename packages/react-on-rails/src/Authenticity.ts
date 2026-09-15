import type { AuthenticityHeaders } from './types/index.ts';

export function authenticityToken(): string | null {
  const token = document.querySelector('meta[name="csrf-token"]');
  if (token instanceof HTMLMetaElement) {
    return token.content;
  }
  return null;
}

export const authenticityHeaders = (otherHeaders: Record<string, string> = {}): AuthenticityHeaders =>
  // eslint-disable-next-line prefer-object-spread -- spread triggers TS2322 (authenticityToken() returns string|null)
  Object.assign({}, otherHeaders, {
    'X-CSRF-Token': authenticityToken(),
    'X-Requested-With': 'XMLHttpRequest',
  });
