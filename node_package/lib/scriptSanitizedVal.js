"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = (function (val) {
    // Replace closing
    var re = /<\/\W*script/gi;
    return val.replace(re, '(/script');
});
