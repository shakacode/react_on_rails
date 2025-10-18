export function authenticityToken() {
  const token = document.querySelector('meta[name="csrf-token"]');
  if (token instanceof HTMLMetaElement) {
    return token.content;
  }
  return null;
}
export const authenticityHeaders = (otherHeaders = {}) =>
  Object.assign(otherHeaders, {
    'X-CSRF-Token': authenticityToken(),
    'X-Requested-With': 'XMLHttpRequest',
  });
