// eslint-disable-next-line import/prefer-default-export -- only one export for now, but others may be added later
export function wrapInScriptTags(scriptId: string, scriptBody: string, nonce?: string): string {
  if (!scriptBody) {
    return '';
  }

  // Sanitize nonce to prevent attribute injection attacks
  // CSP nonces should be base64 strings, so only allow alphanumeric, +, /, =, -, and _
  const sanitizedNonce = nonce?.replace(/[^a-zA-Z0-9+/=_-]/g, '');
  const nonceAttr = sanitizedNonce ? ` nonce="${sanitizedNonce}"` : '';

  return `
<script id="${scriptId}"${nonceAttr}>
${scriptBody}
</script>`;
}
