"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = {
    wrapInScriptTags: function (scriptId, scriptBody) {
        if (!scriptBody) {
            return '';
        }
        return "\n<script id=\"".concat(scriptId, "\">\n").concat(scriptBody, "\n</script>");
    },
};
