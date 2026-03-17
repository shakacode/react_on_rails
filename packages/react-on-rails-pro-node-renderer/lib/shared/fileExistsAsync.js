"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs_1 = __importDefault(require("fs"));
const util_1 = require("util");
const fsAccessAsync = (0, util_1.promisify)(fs_1.default.access);
const fileExistsAsync = async (assetPath) => {
    try {
        await fsAccessAsync(assetPath, fs_1.default.constants.R_OK);
        return true;
    }
    catch (error) {
        if (error.code === 'ENOENT') {
            return false;
        }
        throw error;
    }
};
exports.default = fileExistsAsync;
//# sourceMappingURL=fileExistsAsync.js.map