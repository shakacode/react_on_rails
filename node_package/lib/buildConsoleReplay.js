"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.consoleReplay = void 0;
var RenderUtils_1 = __importDefault(require("./RenderUtils"));
var scriptSanitizedVal_1 = __importDefault(require("./scriptSanitizedVal"));
function consoleReplay() {
    // console.history is a global polyfill used in server rendering.
    // $FlowFixMe
    if (!(console.history instanceof Array)) {
        return '';
    }
    var lines = console.history.map(function (msg) {
        var stringifiedList = msg.arguments.map(function (arg) {
            var val;
            try {
                val = (typeof arg === 'string' || arg instanceof String) ? arg : JSON.stringify(arg);
                if (val === undefined) {
                    val = 'undefined';
                }
            }
            catch (e) {
                val = "".concat(e.message, ": ").concat(arg);
            }
            return (0, scriptSanitizedVal_1.default)(val);
        });
        return "console.".concat(msg.level, ".apply(console, ").concat(JSON.stringify(stringifiedList), ");");
    });
    return lines.join('\n');
}
exports.consoleReplay = consoleReplay;
function buildConsoleReplay() {
    return RenderUtils_1.default.wrapInScriptTags('consoleReplayLog', consoleReplay());
}
exports.default = buildConsoleReplay;
