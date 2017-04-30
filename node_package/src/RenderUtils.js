export default {
  wrapInScriptTags(scriptId, scriptBody) {
    if (!scriptBody) {
      return '';
    }

    return `\n<script id="${scriptId}">
${scriptBody}
</script>`;
  },
};
