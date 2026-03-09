// eslint-disable-next-line import/prefer-default-export -- only one export for now, but others may be added later
export function wrapInScriptTags(scriptId: string, scriptBody: string, nonce?: string): string {
  if (!scriptBody) {
    return '';
  }

  // Sanitize nonce to prevent attribute injection attacks
  // CSP nonces should be base64/base64url-like strings with optional trailing padding.
  const nonceWithAllowedCharsOnly = nonce?.replace(/[^a-zA-Z0-9+/=_-]/g, '');
  const sanitizedNonce = nonceWithAllowedCharsOnly?.match(/^[a-zA-Z0-9+/_-]+={0,2}$/)?.[0];
  const nonceAttr = sanitizedNonce ? ` nonce="${sanitizedNonce}"` : '';

  return `
<script id="${scriptId}"${nonceAttr}>
${scriptBody}
</script>`;
}
