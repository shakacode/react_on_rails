export default {
  wrapInScriptTags(scriptId, scriptBody): string {
    if (!scriptBody) {
      return '';
    }

    return `\n<script id="${scriptId}">
${scriptBody}
</script>`;
  },
};
