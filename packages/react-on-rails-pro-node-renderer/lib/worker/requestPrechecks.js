"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.performRequestPrechecks = performRequestPrechecks;
const checkProtocolVersionHandler_1 = require("./checkProtocolVersionHandler");
const authHandler_1 = require("./authHandler");
function performRequestPrechecks(body) {
    // Check protocol version
    const protocolVersionCheckingResult = (0, checkProtocolVersionHandler_1.checkProtocolVersion)(body);
    if (typeof protocolVersionCheckingResult === 'object') {
        return protocolVersionCheckingResult;
    }
    // Authenticate Ruby client
    const authResult = (0, authHandler_1.authenticate)(body);
    if (typeof authResult === 'object') {
        return authResult;
    }
    return undefined;
}
//# sourceMappingURL=requestPrechecks.js.map