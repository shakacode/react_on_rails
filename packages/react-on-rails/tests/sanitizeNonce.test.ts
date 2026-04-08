import sanitizeNonce from '../src/sanitizeNonce.ts';

describe('sanitizeNonce', () => {
  it('returns undefined for undefined input', () => {
    expect(sanitizeNonce(undefined)).toBeUndefined();
  });

  it('returns undefined for empty string', () => {
    expect(sanitizeNonce('')).toBeUndefined();
  });

  it('passes through a valid base64 nonce', () => {
    expect(sanitizeNonce('abc123')).toBe('abc123');
  });

  it('passes through a base64 nonce with padding', () => {
    expect(sanitizeNonce('abc123==')).toBe('abc123==');
  });

  it('passes through a base64 nonce with single padding', () => {
    expect(sanitizeNonce('abc12=')).toBe('abc12=');
  });

  it('passes through a base64url nonce with hyphens and underscores', () => {
    expect(sanitizeNonce('abc-def_ghi')).toBe('abc-def_ghi');
  });

  it('passes through a nonce with plus and slash (standard base64)', () => {
    expect(sanitizeNonce('abc+def/ghi')).toBe('abc+def/ghi');
  });

  it('strips and rejects a nonce containing attribute injection', () => {
    expect(sanitizeNonce('abc123" onload=alert(1)')).toBeUndefined();
  });

  it('strips invalid chars from injection input and returns the remaining nonce text', () => {
    // The output is attribute-safe and cannot inject markup; it may still be a nonce-like
    // string that does not match any server-generated CSP nonce in practice, so the script
    // tag would still be blocked by CSP.
    expect(sanitizeNonce('"><script>alert(1)</script>')).toBe('scriptalert1/script');
  });

  it('returns undefined for a nonce that is only padding characters', () => {
    expect(sanitizeNonce('===')).toBeUndefined();
  });

  it('returns undefined when padding appears in the middle of the nonce', () => {
    expect(sanitizeNonce('abc=def')).toBeUndefined();
  });

  it('strips spaces and concatenates the result', () => {
    // Spaces are stripped; remaining "abc123" is valid base64
    expect(sanitizeNonce('abc 123')).toBe('abc123');
  });

  it('handles a long valid nonce', () => {
    const longNonce = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+/';
    expect(sanitizeNonce(longNonce)).toBe(longNonce);
  });
});
