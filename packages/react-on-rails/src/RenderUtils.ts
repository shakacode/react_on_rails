import sanitizeNonce from './sanitizeNonce.ts';

// eslint-disable-next-line import/prefer-default-export -- only one export for now, but others may be added later
export function wrapInScriptTags(scriptId: string, scriptBody: string, nonce?: string): string {
  if (!scriptBody) {
    return '';
  }

  const sanitizedNonce = sanitizeNonce(nonce);
  const nonceAttr = sanitizedNonce ? ` nonce="${sanitizedNonce}"` : '';

  return `
<script id="${scriptId}"${nonceAttr}>
${scriptBody}
</script>`;
}
