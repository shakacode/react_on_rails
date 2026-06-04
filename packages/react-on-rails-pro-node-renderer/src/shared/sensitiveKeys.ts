export const SENSITIVE_REQUEST_BODY_KEYS = new Set([
  'password',
  'token',
  'secret',
  'api_key',
  'api-key',
  'apikey',
  'authorization',
  'auth_token',
  'auth-token',
  'authtoken',
  'access_token',
  'accesstoken',
  'bearer',
  'credentials',
]);

export function sanitizeBodyKeys(body: object): string[] {
  return Object.keys(body).filter((key) => !SENSITIVE_REQUEST_BODY_KEYS.has(key.toLowerCase()));
}
