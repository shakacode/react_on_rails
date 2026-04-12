/**
 * Sanitizes a CSP nonce to prevent attribute injection attacks.
 *
 * Policy: sanitize-then-validate. Characters outside the base64/base64url alphabet
 * are stripped first, then the result is validated against the expected nonce pattern.
 * If the sanitized value does not match, `undefined` is returned and no nonce
 * attribute will be emitted — the render proceeds without a nonce rather than
 * failing or logging potentially sensitive values. Note that if stripping yields
 * a string that still matches the base64/base64url pattern, that stripped value
 * is returned.
 *
 * CSP nonces should be base64 or base64url strings with optional trailing `=` padding.
 */
export default function sanitizeNonce(nonce?: string): string | undefined {
  const nonceWithAllowedCharsOnly = nonce?.replace(/[^a-zA-Z0-9+/=_-]/g, '');
  return nonceWithAllowedCharsOnly?.match(/^[a-zA-Z0-9+/_-]+={0,2}$/)?.[0];
}
