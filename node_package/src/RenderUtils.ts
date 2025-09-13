/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */
// eslint-disable-next-line import/prefer-default-export -- only one export for now, but others may be added later
export function wrapInScriptTags(scriptId: string, scriptBody: string): string {
  if (!scriptBody) {
    return '';
  }

  return `
<script id="${scriptId}">
${scriptBody}
</script>`;
}
