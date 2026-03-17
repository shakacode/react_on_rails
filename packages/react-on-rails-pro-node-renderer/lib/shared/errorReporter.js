"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.addMessageNotifier = addMessageNotifier;
exports.addErrorNotifier = addErrorNotifier;
exports.addNotifier = addNotifier;
exports.message = message;
exports.error = error;
const log_js_1 = __importDefault(require("./log.js"));
const messageNotifiers = [];
const errorNotifiers = [];
/**
 * Adds a callback to notify a service on string error messages.
 */
function addMessageNotifier(notifier) {
    messageNotifiers.push(notifier);
}
/**
 * Adds a callback to notify an error tracking service on JavaScript {@link Error}s.
 */
function addErrorNotifier(notifier) {
    errorNotifiers.push(notifier);
}
/**
 * Adds a callback to notify an error tracking service on both string error messages and JavaScript {@link Error}s.
 */
function addNotifier(notifier) {
    messageNotifiers.push(notifier);
    errorNotifiers.push(notifier);
}
function notify(msg, tracingContext, notifiers) {
    notifiers.forEach((notifier) => {
        try {
            notifier(msg, tracingContext);
        }
        catch (e) {
            log_js_1.default.error(e, 'An error tracking notifier failed');
        }
    });
}
/**
 * Reports an error message.
 */
function message(msg, tracingContext) {
    log_js_1.default.error({ msg, label: 'ErrorReporter notification' });
    notify(msg, tracingContext, messageNotifiers);
}
/**
 * Reports an error.
 */
function error(err, tracingContext) {
    log_js_1.default.error({ err, label: 'ErrorReporter notification' });
    notify(err, tracingContext, errorNotifiers);
}
//# sourceMappingURL=errorReporter.js.map