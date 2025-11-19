// eslint-disable-next-line import/prefer-default-export -- only one export for now, but others may be added later
export function wrapInScriptTags(scriptId: string, scriptBody: string, nonce?: string): string {
  if (!scriptBody) {
    return '';
  }

  const nonceAttr = nonce ? ` nonce="${nonce}"` : '';

  return `
<script id="${scriptId}"${nonceAttr}>
${scriptBody}
</script>`;
}
