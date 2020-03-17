export default {
  wrapInScriptTags(scriptId: string, scriptBody: string): string {
    if (!scriptBody) {
      return '';
    }

    return `\n<script id="${scriptId}">
${scriptBody}
</script>`;
  },
};
