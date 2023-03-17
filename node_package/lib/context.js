"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Get the context, be it window or global
 * @returns {boolean|Window|*|context}
 */
function context() {
    return ((typeof window !== 'undefined') && window) ||
        ((typeof global !== 'undefined') && global) ||
        this;
}
exports.default = context;
