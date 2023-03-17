"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = {
    authenticityToken: function () {
        var token = document.querySelector('meta[name="csrf-token"]');
        if (token && (token instanceof window.HTMLMetaElement)) {
            return token.content;
        }
        return null;
    },
    authenticityHeaders: function (otherHeaders) {
        if (otherHeaders === void 0) { otherHeaders = {}; }
        return Object.assign(otherHeaders, {
            'X-CSRF-Token': this.authenticityToken(),
            'X-Requested-With': 'XMLHttpRequest',
        });
    },
};
