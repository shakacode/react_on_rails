"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.supportsRootApi = void 0;
var react_dom_1 = __importDefault(require("react-dom"));
var reactMajorVersion = ((_a = react_dom_1.default.version) === null || _a === void 0 ? void 0 : _a.split('.')[0]) || 16;
// TODO: once we require React 18, we can remove this and inline everything guarded by it.
// Not the default export because others may be added for future React versions.
// eslint-disable-next-line import/prefer-default-export
exports.supportsRootApi = reactMajorVersion >= 18;
